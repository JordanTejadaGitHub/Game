# Dream signature council review — 2026-10-09

User-authorized scope: first review Briar Crown, Ricochet, Rooted Nightmares, Great Ripple and Impatient Night, then apply the same experiential review to the remaining build-defining and strong behavior-changing Dreams. Preserve pool placements, randomness, Half-Dreamed, Grove availability, Full Moon and native Warden combos.

Statuses below distinguish council decisions from source-reviewed implementation: **retained** means existing gameplay/feedback is sufficient for this pass; **recommended** identifies a specific additional cue. **implemented** means the feedback hook has been source-reviewed; empirical balance is not implied. No additional mechanical redesign is currently justified. Empirical balance and experiential impact remain unmeasured; source review establishes behavior, not player comprehension.

Current data rule: `DreamState.is_defining` = defining tag OR Legendary rarity. Excluding `retired = true`, there are 70 resources. These can join new offer pools; per-run Grove, family, act, eligibility and sampling gates still apply. Retained Deepened partners follow their base decision, preserving their actual distinct radius/duration/connection behavior.

Evidence baseline: `scripts/run/dream_state.gd` (`is_defining`, `get_card_effects`, offer gates); `scripts/run/dream_effects.gd`; `scripts/tower/tower.gd` (`_draw_badges`, `_draw_empowered`, rank pips); `scripts/ui/card_scene.gd` (placement demonstrations); `scripts/tower/tower_placer.gd` (Dream ghost preview). All resource effects below were read from current `resource/dream/*.tres`, rather than historical audit counts. Baseline inspection/preview decisions are not claims that every card has a living demonstration.

## All defining resources

| Card / resource | Status | Concrete decision / source evidence |
|---|---|---|
| Briar Crown / briar_crown | implemented | Tiny crown on empowered wall; inspect-only source link; local actual strike. DreamState.briar_source/_briar_strike. |
| Brimming / brimming | retained | Existing effective bonus/status/rank or economy inspection; no extra combat particles. DreamState.get_card_effects; Tower effective stats; native statuses/HUD. |
| Cozy Corners / cozy_corners | retained | Existing placement geometry/range preview and selection/build badge; maintain current rule. DreamState.get_card_effects; TowerPlacer Dream preview; CardScene. |
| Crossroads / crossroads | retained | Existing placement geometry/range preview and selection/build badge; maintain current rule. DreamState.get_card_effects; TowerPlacer Dream preview; CardScene. |
| Crowd Breaker / crowd_breaker | retained | Existing effective bonus/status/rank or economy inspection; no extra combat particles. DreamState.get_card_effects; Tower effective stats; native statuses/HUD. |
| Dawnbreak / dawnbreak | implemented | Budgeted actual Dawnburst footprint. Reactions._dawnburst. |
| Deeper Rings / deeper_rings | retained | Increased maximum visible in rank controls/pips. |
| Desperate Bloom / desperate_bloom | retained | Existing effective bonus/status/rank or economy inspection; no extra combat particles. DreamState.get_card_effects; Tower effective stats; native statuses/HUD. |
| Dawnwing / dream_dawnwing | retained | Existing ascension bloom and real final-form attacks/aura/statuses communicate changed behavior. TowerPlacer.evolve; Tower attack dispatch; native attack effect nodes. |
| Grandmother Oak / dream_grandmother_oak | retained | Existing ascension bloom and real final-form attacks/aura/statuses communicate changed behavior. TowerPlacer.evolve; Tower attack dispatch; native attack effect nodes. |
| The Great Bell / dream_great_bell | retained | Existing ascension bloom and real final-form attacks/aura/statuses communicate changed behavior. TowerPlacer.evolve; Tower attack dispatch; native attack effect nodes. |
| Old Mountain / dream_old_mountain | retained | Existing ascension bloom and real final-form attacks/aura/statuses communicate changed behavior. TowerPlacer.evolve; Tower attack dispatch; native attack effect nodes. |
| Sporemother / dream_sporemother | retained | Existing ascension bloom and real final-form attacks/aura/statuses communicate changed behavior. TowerPlacer.evolve; Tower attack dispatch; native attack effect nodes. |
| Stormheart / dream_stormheart | retained | Existing ascension bloom and real final-form attacks/aura/statuses communicate changed behavior. TowerPlacer.evolve; Tower attack dispatch; native attack effect nodes. |
| The Whirlwind / dream_tempest | retained | Existing ascension bloom and real final-form attacks/aura/statuses communicate changed behavior. TowerPlacer.evolve; Tower attack dispatch; native attack effect nodes. |
| Tidecaller / dream_tidecaller | retained | Existing ascension bloom and real final-form attacks/aura/statuses communicate changed behavior. TowerPlacer.evolve; Tower attack dispatch; native attack effect nodes. |
| World Root / dream_world_root | retained | Existing ascension bloom and real final-form attacks/aura/statuses communicate changed behavior. TowerPlacer.evolve; Tower attack dispatch; native attack effect nodes. |
| Drumbeat / drumbeat | retained | Existing placement geometry/range preview and selection/build badge; maintain current rule. DreamState.get_card_effects; TowerPlacer Dream preview; CardScene. |
| Elder Kin / elder_kin | retained | Existing effective bonus/status/rank or economy inspection; no extra combat particles. DreamState.get_card_effects; Tower effective stats; native statuses/HUD. |
| Endless Rings / endless_rings | retained | Eldest crown, rank controls/pips, court inspection. |
| Eternal Charge / eternal_static | retained | Existing effective bonus/status/rank or economy inspection; no extra combat particles. DreamState.get_card_effects; Tower effective stats; native statuses/HUD. |
| Extended Family / extended_family | retained | Actual two kinship links communicate behavior. Kinships.get_pairs. |
| Fresh Growth / fresh_growth | retained | Existing bloom_left empowered ring. Tower._draw_empowered. |
| Full Moon / full_moon | retained | Existing crit feedback and inspected chance; preserve overflow mechanics. |
| Golden Harvest / golden_harvest | retained | Existing effective bonus/status/rank or economy inspection; no extra combat particles. DreamState.get_card_effects; Tower effective stats; native statuses/HUD. |
| Great Ripple / great_ripple | implemented | Faint anticipation and released aftershock. GroveRules.area_attack. Preserve expanded filled disk, not hollow annulus. |
| Grove of Kin / grove_of_kin | retained | Existing effective bonus/status/rank or economy inspection; no extra combat particles. DreamState.get_card_effects; Tower effective stats; native statuses/HUD. |
| Head Start / head_start | retained | Existing effective bonus/status/rank or economy inspection; no extra combat particles. DreamState.get_card_effects; Tower effective stats; native statuses/HUD. |
| Heart of the Maze / heart_of_the_maze | retained | Existing placement geometry/range preview and selection/build badge; maintain current rule. DreamState.get_card_effects; TowerPlacer Dream preview; CardScene. |
| Hollow Ground / hollow_ground | retained | Existing placement geometry/range preview and selection/build badge; maintain current rule. DreamState.get_card_effects; TowerPlacer Dream preview; CardScene. |
| Hummingheart / hummingheart | retained | Existing effective bonus/status/rank or economy inspection; no extra combat particles. DreamState.get_card_effects; Tower effective stats; native statuses/HUD. |
| Hunter's Moon / hunters_moon | implemented | Brief bounded transfer cue on actual spread; retain Marked badge. DreamState._hunters_spread. |
| Hunter's Patience / hunters_patience | retained | Existing effective bonus/status/rank or economy inspection; no extra combat particles. DreamState.get_card_effects; Tower effective stats; native statuses/HUD. |
| Last Breath / last_breath | implemented | Budgeted real death-burst footprint only when secondary targets exist. DreamState._last_breath. |
| Last Leaf / last_leaf | retained | Existing effective bonus/status/rank or economy inspection; no extra combat particles. DreamState.get_card_effects; Tower effective stats; native statuses/HUD. |
| Lingering Ground / lingering_ground | retained | Longer native ground effects communicate duration; inspect duration, no extra overlay. |
| Lingering Splash / lingering_splash | retained | Existing actual ground patch. GroveRules.area_attack/LingeringPatch. |
| Lone Hunter / lone_hunter | retained | Existing effective bonus/status/rank or economy inspection; no extra combat particles. DreamState.get_card_effects; Tower effective stats; native statuses/HUD. |
| Lucid Dreaming / lucid_dreaming | retained | Actual four-card/two-pick offer flow communicates effect. |
| Many Talents / many_talents | retained | Existing effective bonus/status/rank or economy inspection; no extra combat particles. DreamState.get_card_effects; Tower effective stats; native statuses/HUD. |
| Menagerie / menagerie | retained | Existing effective bonus/status/rank or economy inspection; no extra combat particles. DreamState.get_card_effects; Tower effective stats; native statuses/HUD. |
| Momentum / momentum | implemented | Selected-Warden streak/ramp state, no always-on particles. GroveRules.note_hit/speed_bonus. |
| Nightshade / nightshade | retained | Existing effective bonus/status/rank or economy inspection; no extra combat particles. DreamState.get_card_effects; Tower effective stats; native statuses/HUD. |
| Overlap / overlap | implemented | Brief second-area-hit accent for real qualification. DreamState.overlap_multiplier; Tower.hit. |
| Stirring Roots / restless_roots | retained | Existing effective bonus/status/rank or economy inspection; no extra combat particles. DreamState.get_card_effects; Tower effective stats; native statuses/HUD. |
| Root Network / root_network | retained | Existing network lines plus placement/selection feedback. Tower._redraw_root_network. |
| Rootbound / rootbound | retained | Existing placement geometry/range preview and selection/build badge; maintain current rule. DreamState.get_card_effects; TowerPlacer Dream preview; CardScene. |
| Rooted Nightmares / rooted_nightmares | implemented | Blocking footprint for actually Held ground walkers; actual stationary queue communicates waiting (no separate waiting icon delivered). EnemySpawner._update_rooted_cells; Enemy._is_blocked_ahead; test_acts_3_4. |
| Sap Rising / sap_rising | retained | Existing sap_pulse sheet at the real nonattacker pulse. ShapeCards._update_sap; do not duplicate this overlay. |
| Scarred Bark / scarred_bark | retained | Existing effective bonus/status/rank or economy inspection; no extra combat particles. DreamState.get_card_effects; Tower effective stats; native statuses/HUD. |
| Seedling Gift / seedling_gift | retained | Charge counter and zero-cost next Sprout preview. |
| Seeping / seeping | retained | Existing effective bonus/status/rank or economy inspection; no extra combat particles. DreamState.get_card_effects; Tower effective stats; native statuses/HUD. |
| Shared Training / shared_training | retained | Existing effective bonus/status/rank or economy inspection; no extra combat particles. DreamState.get_card_effects; Tower effective stats; native statuses/HUD. |
| Small Hands / small_hands | retained | Existing effective bonus/status/rank or economy inspection; no extra combat particles. DreamState.get_card_effects; Tower effective stats; native statuses/HUD. |
| Solitude / solitude | retained | Existing placement geometry/range preview and selection/build badge; maintain current rule. DreamState.get_card_effects; TowerPlacer Dream preview; CardScene. |
| Specialist / specialist | retained | Existing effective bonus/status/rank or economy inspection; no extra combat particles. DreamState.get_card_effects; Tower effective stats; native statuses/HUD. |
| Spillover / spillover | implemented | Local real overkill splash footprint. GroveRules.spillover. |
| Thicket / sprout_chorus | retained | Existing placement geometry/range preview and selection/build badge; maintain current rule. DreamState.get_card_effects; TowerPlacer Dream preview; CardScene. |
| Straightaway / straightaway | retained | Existing placement geometry/range preview and selection/build badge; maintain current rule. DreamState.get_card_effects; TowerPlacer Dream preview; CardScene. |
| Sunlit Rest / sunlit_rest | retained | Existing actual Nurture rank-up feedback. |
| Sweet Harmony / sweet_harmony | retained | Existing real harmony strike/bond feedback. Kinships.note_hit. |
| Tended Stumps / tended_stumps | retained | Existing placement geometry/range preview and selection/build badge; maintain current rule. DreamState.get_card_effects; TowerPlacer Dream preview; CardScene. |
| The Last Light / the_last_light | retained | Existing effective bonus/status/rank or economy inspection; no extra combat particles. DreamState.get_card_effects; Tower effective stats; native statuses/HUD. |
| The Long Walk / the_long_walk | retained | Existing effective bonus/status/rank or economy inspection; no extra combat particles. DreamState.get_card_effects; Tower effective stats; native statuses/HUD. |
| The Old Ones / the_old_ones | retained | Existing effective bonus/status/rank or economy inspection; no extra combat particles. DreamState.get_card_effects; Tower effective stats; native statuses/HUD. |
| Thorny Walls / thorny_walls | implemented | Local lash on actual wall attack; share restrained wall cue infrastructure. Tower wall attack hook. |
| Twig Walls / twig_walls | retained | Actual small wall footprint and discounted planting preview communicate effect. |
| Watchful Rest / watchful_rest | retained | Existing watch_charged ready ground ring. Tower._draw_empowered/_update_watchful; optional consumed accent only after live evidence. |
| Whirlwind Heart / whirlwind_heart | retained | Existing effective bonus/status/rank or economy inspection; no extra combat particles. DreamState.get_card_effects; Tower effective stats; native statuses/HUD. |
| Wildwood Reclaimed / wildwood_reclaimed | retained | Existing placement geometry/range preview and selection/build badge; maintain current rule. DreamState.get_card_effects; TowerPlacer Dream preview; CardScene. |

## Additional strong behavior rules and retained partners

| Cards | Status | Concrete decision / evidence |
|---|---|---|
| Ricochet / II | implemented | Fading traveled seed trail, return tint, successful-turn spark. SeedBoomerang._ricochet/_process. Preserve one/two 90-degree half-length legs. |
| Impatient Night | implemented | Active HUD chip while two early-called drifts have actual nightmares on field. DriftDirector.early_drifts_on_field/early_overlap_changed; approved top dream_design. |
| Target Turnover / II | implemented | Selected-Warden active duration marker if missing; no mass particles. Tower.note_primary_target; 3/5-second current duration. |
| Shattering Blow / II | implemented | Real-trigger broken-arc splash cue, live 1/1.5-cell radius. Tower._shattering_blow. |
| Passing Dream | implemented | Bounded source-to-recipient transfer cue when statuses actually copied. DreamState._passing_dream. |
| Spore Cascade / II | implemented | Shared transfer cue at actual two/three-recipient spread; retain status propagation. DreamState spread hook. |
| Root Web | retained | Native Held badge/root cue communicates spreading; short links only if live review finds ambiguity. Enemy._spread_hold. |
| Tangled Release / II | retained | Actual backward movement communicates release pull. Enemy release hook. |
| Seed Storm | retained | Real five-seed fan. Tower._throw_seeds. |
| Twin Puff | retained | Real extra projectile. Tower._twin_puff. |
| Static Field / II | retained | Native bolt/area feedback; preserve wider II geometry. Reactions static bolt. |
| Ring Dance | retained | Real neighboring ring bursts; preserve cascade. DreamState ring hooks. |
| Thorn Snare / II | retained | Native Held feedback and actual blocking footprint communicate hold; do not duplicate a damage-lash cue for this hold-only rule. Tower._update_wall_effects; EnemySpawner._update_rooted_cells. |
| First Frost | retained | Actual Held state communicates freeze; use Rooted view only when blockers are truly present. |
| Switchback | retained | Native slowed movement/status feedback; no recurring turn labels. DreamState.switchback_at. |
| Root Network II | retained | Existing network lines; diagonal connectivity differs from base, preserve preview. |
| Sunlit Rest II | retained | Existing two real rank-ups. |
| Watchful Rest II | retained | Existing ready ring; preserve shorter charging time. |
| Old Friends / II, Rooted Bond, Shared Training | retained | Real kinship links/stages/signatures and rank inspection. Kinships and Tower signature paths. |
| Native combo amplifiers, including Entwined/Woven | retained | Existing Reaction/status/attack visuals; avoid a second overlay for every amplified event. Reactions, ReactionTracker and native effect nodes. |
| Remaining free-price/rank/offer/economy/clearing rules | retained | Actual changed price, counter, rank-up, offer and clearing preview communicate results; no combat overlay. |

## Bounded recommended batch

Delivered batch retains the existing Sap Rising sap_pulse sheet and adds actual-trigger cues for Last Breath, Spillover, Shattering Blow and Dawnbreak, then one shared transfer cue for Passing Dream, Hunter's Moon and Spore Cascade. Selected-Warden ramp/timer readouts are lower priority. Existing Watchful Rest/Fresh Growth rings should be retained instead of duplicated. Apply active budgets, nearby coalescing, on-screen culling and reduced-motion/effects settings; cues must not apply damage, statuses or randomness.

Review Rooted by the actual blocker map, not all Held/frozen/asleep bodies. The card intentionally makes every Held ground walker a blocker, including holds from other Wardens; existing tests cover blocked cells, queues, flyer exclusion and reopening. Great Ripple uses a wider filled damage disk after one second; no measured balance/retention evidence supports a redesign. A ring-shaped visual can illustrate the disk boundary without changing mechanics.



## Final review and verification reconciliation

Resolved: Great Ripple caps feedback nodes at 12 (4 reduced) while retaining every gameplay timer; EnemyStatuses.applications counts accepted applications before immediate Static consumption, and transfer hooks compare this counter rather than remaining status presence; selected tempo uses WorldLabel.draw_tag. Thorny Walls now emits shared wall_struck at the real lash, reusing the bounded Briar view. Thorn Snare retains native Held/blocking feedback rather than receiving a misleading damage-lash cue. Sap Rising retains its existing sap_pulse.

Transfer and death-burst feedback is parented through Reactions._world(self), preserving the EnemySpawner enemy-only child invariant. The application counter is ephemeral, unpersisted presentation bookkeeping; old saves require no migration. Feedback budgets skip cosmetics only. No new mechanics, RNG, offer-pool or native-combo changes were found in the signature source review.

Main reports passing signature, burst, ripple, transfer, geometry, generic-card, build, Reaction and save tests, plus isolated area-rework validation and existing feedback/UI tests. Scene-based tests retain existing teardown leak diagnostics. Burst/ripple/transfer captures were visually inspected. Briar, Ricochet, blocking footprints and overlap HUD were also checked in real graphical captures; the crown was moved above foliage and given a thin gold rim after visual review. Empirical balance and full combat readability remain unmeasured; no mechanics redesign is justified by this pass.
