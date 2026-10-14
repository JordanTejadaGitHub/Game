# Dream cards: lead review and decision document (2026-10-11)

Read-only review. Nothing in the repo was changed and nothing was run. Sources: the six council reports, `live_cards.tsv` (256 cards), `dream_design.md` 1-113, `unique_dream_successors.md`, `claude_handoff.md`, and the card files where reports disagreed.

Members: **P** player, **T** tower-defence, **R** roguelite, **D** designer, **E** engineer, **I** impact.
Status names are the player-facing ones (Soaked, Drowsy, Poisoned, Exposed, Charged, Rooted). All numbers in proposals are starting values for Balancing Discussion.

## 1. Verdict

- The offer system already does what the owner wants (random, no steering). The card set does not yet.
- About 120 of 256 cards pass "I can point at it on screen". 55 are plain numbers and 38 are too small or too wordy to feel (I).
- The problem is in the cards seen most: 23 of 65 Commons are plain numbers, and 33 of the 55 number cards are in the start pool.
- The newest cards (10-09 to 10-11) have good ideas but read like rule specs, and Fifth Beat is broken in code.
- The set also has holes: 36 defining cards (the rule is 40), three archetypes short of helpers, four with no Rare to hope for on a fresh profile.

## 2. Where the council agrees

- **The offers are right; the cards are the problem.** (R, D, T, I)
- **Commons are where the number cards live.** (I, R, D, P)
- **Cards about where you build are the best cards**: bends, walls, lone Wardens, clusters. (P, T, R, I)
- **These pay out without the player doing anything**: Head of the Line, Lantern Glow, Weary Feet, Edge of Sight, In the Thick. (I, R, T)
- **Small stack counts do nothing**: 2-3 Exposed when it needs 10, 2-3 Poisoned when the cap is 32. (I, R, D)
- **The new cards' text is unreadable in five seconds**: Stored Rain, Stone Relay, Drumbeat, Fifth Beat, Crossfire, Brimming, Steadfast, Canopy, Grand Tour. (P, D, I, E)
- **Fifth Beat needs more than a reword.** (E, T, D; P and I asked for a reword only, see section 3)
- **`spore_cascade_ii` is live by accident.** (D, R, I; I confirmed it in the file)
- **Pocket-change Dew cards are never felt**: Early Bird, Kin's Keepsake, Emergency Reserves. (P, I, R)
- **Four archetypes have no start-pool Rare or Legendary**: daring, tending, swift, reach. (R, D)
- **No trample triggers, nothing stacks, Legendaries keep one archetype.** These rules hold. (D, T)

## 3. Where they disagree, and my ruling

| # | Topic | Positions | Ruling | Why |
|---|---|---|---|---|
| 1 | Fifth Beat | P, I: reword only. E, T, D: the effect is wrong. | Change the effect (section 5). | The echo takes defences twice and pulse Wardens pay 10% for nothing. |
| 2 | First Light (first hit ×3) | R: replace, it is a number. P: the most exciting card. I: keep. | Keep. | Big, instant, visible on every nightmare. |
| 3 | Clear Minds (+35% vs no statuses) | I: replace with a short Rooted. R: it is a real "no-status build" definer. E: works as written. | Keep the effect; add an on-screen sign on clean nightmares. | It steers a build. A free Rooted in every run's pool is too much control. |
| 4 | Cozy Corners | T: one Warden per bend. P, I: keep, it shapes the maze. | Owner call. I recommend T's change. | With half-cell placement nearly every Warden is "beside a bend". |
| 5 | Close Shave | I: Root followers after a leak. R: trigger before the leak. | R's direction (section 5). | A card that only works after you fail is a regret pick (P). |
| 6 | Early Bird | I: regrow a leaf. R: peek at the next Dream. | I's version, as an owner call. | A peek touches offers; the owner wants no steering. |
| 7 | Quiet Vigil | I: full Exposed. R: 5 stacks. Both keep the 5 s idle timer. | Drop the idle timer (section 5). | It rewards idle Wardens and costs a range scan per Warden per frame (E). |
| 8 | Target-switch cards (Target Turnover, Passing Thread, Spore Reserve) | I: make all three bigger. T: switching cannot be planned. D: three cards, one idea. | Keep one (Spore Reserve). Rework the other two. | Only 2 Wardens let you pick a target; pulse and spin Wardens never switch. |
| 9 | Lasting Dreams (statuses last twice as long) | I: replace with "no decay inside range". D: it outclasses a Rare. | Keep as is. | "Twice" is felt. The replacement needs a per-frame check and could make Poisoned permanent. |
| 10 | Fresh Growth | I: fine. T: sell at the rest, replant after Start, keep +50% all block. | T's fix: growing only, not planting. | The owner's "no juggling" rule. |
| 11 | Slows as replacements | I proposes ten new slows. T: slows stop at half speed, so they are dead picks in a Drowsy build. | At most three new slow cards. Heavy Air turns wasted slow into Rooted. | Ten slows would be ten dead cards for one archetype. |
| 12 | Start-pool Rares | R: move Spillover and Last Stand out of the Grove. Owner: Grove exclusives stay exclusive. | Do not move them. Design new start Rares (section 8). | Standing owner rule. |
| 13 | Percent cards that need real maze shaping (Straightaway, Narrow Way, Solitude, Rootbound, Nightshade) | I: borderline. P: favourites. | Keep. | The player must build for them and can see the condition. |
| 14 | Rooted Nightmares (Legendary) | T: leaders held in turn can stall a column. I: keep. | Add "a cell can be blocked once every 3 s". | "Control stays bounded" is already the rule. |
| 15 | Whirlwind Heart | D: a net loss alone. I: fair trade. P: cannot do the sum. | Keep the effect; rewrite the text (section 7). | A Legendary trade is fine if the card says what you get. |

Note on the "43 cards with an unclosed bracket" (P): that is the export, not the cards.

## 4. Fix first: bugs and broken promises

| Item | Evidence | Fix | Size |
|---|---|---|---|
| `spore_cascade_ii` is still offered | `resource/dream/spore_cascade_ii.tres` line 15: `rule_id = &"spore_cascade"retired = true` on one line | Put `retired = true` on its own line | S |
| Fifth Beat echo takes defences twice (half vs resistant, 150% vs weak) | `scripts/tower/dream_build_rules.gd` 102-111; `tower.gd` 2714-2724 | Store the hit before defences, as Stone Relay does | S |
| Fifth Beat takes 10% from pulse and spin Wardens, which can never echo; slow Wardens need 12-30 s for five hits | `tower.gd` 2540-2575; T report §3.1 | Only Wardens that can echo are touched (or drop the 10%, section 5) | S |
| Corner Sign: text says "next hit", code gives every Warden +1 stack per bend | `scripts/run/dream_path_rules.gd` 18-34 | Reworked in section 5; text and code then match | S |
| Quiet Vigil: any direct hit spends it; it is pre-charged at every block start | `dream_growth_rules.gd` 47-61; `tower.gd` 2641-2644 | Reworked in section 5 | S |
| Steadfast "pins" but applies a bare hold that skips every Rooted rule and card | `dream_state.gd` 5164-5178; `enemy_statuses.gd` 791-799 | Apply normal Rooted (section 5) | S |
| Few and Mighty shows +88% in the Dreams row, gives +80% | `dream_effects.gd` 365-369 | Cap the shown number | S |
| Shared Mycelium has no family need; it can fill a Rare slot with no Poisoned Warden on the board | `resource/dream/shared_mycelium.tres` (no `requires`); Crossed Sparks has `firefly_jar` | Add `requires` sporeling | S |
| Crossfire and Stone Relay: unstated rules (walking follower only; pulse Wardens never count; splash can spend the stone) | `dream_build_rules.gd` 69-136 | Say it on the card or in the Codex (section 7) | S |
| Stored Rain wastes every second attack against a lone target (a boss) | `dream_build_rules.gd` 138-197 | No puddle when no other walking nightmare is in reach | S |
| `PLAIN_STAT_CARDS` is stale (three of five are no longer plain) | `dream_state.gd` 2703 | Rebuild from section 6 after the rework | S |
| 13 cards have no archetype tag | D report §4 | Tag them: Target Turnover swift; Back-row Roots reach; Clear Minds precision; Passing Thread, First Frost, Live Wire, Heavy Eyelids, Quick Reactions, Shared Mycelium affliction; Bramble Oath maze; Sheltering Boughs, Shared Light, Patient Roots tending | S |
| Defining cards: 36, rule is 40 (tall 3, overgrowth 3, swift 2) | D report §2 | Section 8 | M |
| Helpers under the floor of 6: tall 4, overgrowth 5, affliction 5 | D report §2 | Tags fix affliction; section 8 for the rest | M |
| Cost paid every frame with no card owned | `enemy.gd` 467-470; `tower.gd` 2637, 2644-2645, 2753, 792 | One "any cooperation rule held" flag, checked once per frame | M |
| Cost while the card is owned: Wake Ripple (tree walk per dispel), Canopy (recompute per hit), Stored Rain (scan per puddle per frame), Switchback (all-Warden scan per bend), Stone Relay and Crossfire (all-nightmare scan) | E report §3 | Canopy: keep only the 0.2 s sampler. Switchback: mark covered bends on placement. Others: use the nightmare list, not the tree | M |
| First Frost counters are static and leak into the next run | `tower.gd` 111-112 | Move to the run's state | S |
| `board_can_use` has no gate for Drumbeat, Crossfire, Steadfast; Canopy checks count, not connection | `dream_state.gd` 2633-2670 | Add the gates | S |
| Drumbeat neighbours: code and build preview may disagree on half cells (not verified) | `dream_state.gd` 5100-5162 vs `dream_effects.gd` 736 | Check, then one shared helper | S |
| Docs out of date: old Canopy text; Wellspring cap 120 vs 130 | `dream_design.md` 74; `CLAUDE.md` vs `claude_handoff.md` | Correct the docs | S |
| No tests for: Fifth Beat double defence and pulse penalty, Few and Mighty text, First Frost leak, hook costs | E report §5 | Add with the fixes | M |

## 5. The number-card rework list

Rules I applied to every row:

- No card keyed to "primary target", switching or streaks, except Spore Reserve (the one switch card kept) and Fifth Beat (which now skips pulse Wardens openly).
- Exposed and Poisoned are added in halves or fulls, never 1-3 stacks.
- Every Rooted goes through the normal Rooted rules (cooldown, cap, bosses shorter).
- Each device is used on at most three reworked cards:
  - **fires twice**: Light Steps, Crowd Breaker, The Quiet Ones.
  - **attacks at once**: Rush, Stung, Hunt's Rush.
  - **short Rooted**: Close Shave, Heavy Air, Steadfast.
  - **push back**: Head of the Line, Spinning Corners, Crosswind (each once per nightmare).
  - **new slow**: Weary Feet, Bramble Oath, Forest's Edge.
  - **changes who Wardens aim at**: Ripples, Lone Hunter, Twin Strike.
- Where I could, the trigger is worked out on placement or at drift start, not per hit.

Every row keeps its id, rarity, pool, tags and Needs. S = start pool, G = Grove.

| id | name | rarity+pool | now | final proposed text | what the player sees | flagged by | status |
|---|---|---|---|---|---|---|---|
| head_of_the_line | Head of the Line | C, S | +25% to the lead nightmare | Dispelling the nightmare furthest along shoves the next one back 1 cell. Once per nightmare. | The new leader is thrown back | I, R, T | APPROVE-READY |
| edge_of_sight | Edge of Sight | C, S | +25% in outer half of range | A Warden's first hit on a nightmare is a crit if it lands in the outer half of its range. | Crits as nightmares enter the ring | I, R | APPROVE-READY |
| light_steps | Light Steps | C, S | 30% faster for 8 s at drift start | At the start of each drift, every Warden's first 3 attacks fire twice. | An opening volley of double shots | I | APPROVE-READY |
| rush | Rush | C, S | 20% faster with 10+ on field | Every 10th nightmare to enter the field in a drift makes every Warden attack at once. | The whole grove fires together | I | APPROVE-READY |
| bitter_sap | Bitter Sap | C, S | +1 starting stack | Each Warden's first hit on a nightmare applies three times its usual status stacks. | Status dots burst on first contact | I, R, D | APPROVE-READY |
| ripples | Ripples | C, S | Area +25% to non-targets | Wardens with an area attack aim at the nightmare with the most others within 1 cell. | Splashes land in the thick | I | APPROVE-READY |
| wide_petals | Wide Petals | C, S | Splashes 0.5 wider | Splashes and clouds on a straight stretch of 5 or more path cells stretch 1 cell further along it. | Long splashes down corridors | I, R | APPROVE-READY |
| close_guard | Close Guard | C, S | Short Wardens +0.5 range | A Warden with range 3 or less strikes each nightmare once, free, as it steps onto a path cell touching it. | Short Wardens lash every passer-by | I, R | APPROVE-READY |
| weary_feet | Weary Feet | C, S | +1% damage taken per 4 tiles | A nightmare that has walked 40 path cells tires: it is 20% slower for the rest of its walk. | Nightmares drag late in the maze | I, R, T | APPROVE-READY |
| forest_floor | Forest Floor | C, S | +20% touching an obstacle | A Warden touching 2 or more uncleared obstacles reaches 1 cell further. Clearing them ends it. | Bigger ring in the build ghost | I, R | NEEDS OWNER CALL |
| mulch | Mulch | C, S | +20% on a cleared cell | The first Warden planted on each cleared cell arrives at rank I, free. | New Warden arrives with a rank | I, R, D | APPROVE-READY |
| growth_rings | Growth Rings | C, S | +0.1 range per rank | A Warden at rank III or higher gets the target button, like Standing Stone. | A new button on ranked Wardens | I, T | NEEDS OWNER CALL |
| steady_aim | Steady Aim | C, S | Crits +40% above half health | A crit on a nightmare above half health makes that Warden's next attack a crit too. | Two crit callouts in a row | I | APPROVE-READY |
| twin_strike | Twin Strike | C, S | Kin +20% on a shared target | Bonded kin aim at the same nightmare whenever both can reach it, and deal 20% more to it. | Kin pairs focus one nightmare | I, R, D | APPROVE-READY |
| close_quarters | Close Quarters | C, S | Touching kin 20% faster | When kin touch each other, their Harmony strikes both Wardens' targets. | Two Harmony strikes at once | I | APPROVE-READY |
| early_bird | Early Bird | C, S | +5 Dew per early call | The first drift you call early each block regrows 1 leaf if none of its nightmares reach the Heartwood. | A leaf grows back | I, R, P | NEEDS OWNER CALL |
| close_shave | Close Shave | C, S | 30% faster after a leak | The first nightmare each drift to come within 2 cells of the Heartwood is Rooted for 2 s. | The leader freezes at the door | I, R, P | APPROVE-READY |
| stung | Stung | C, S | +10% per leaf lost | When a leaf is lost, every Warden within 4 cells of the Heartwood attacks at once, then twice as fast for 5 s. | The Heartwood guard erupts | I | APPROVE-READY |
| lantern_glow | Lantern Glow | C, S | Cells in reach: no fog, +15% | Path cells in reach of 2 or more Wardens glow. Nightmares on them can't hide in fog and take 20% more damage. | Glowing stretches where rings overlap | I, R, T | APPROVE-READY |
| rhythm | Fifth Beat | C, S | 5th hit in a row echoes; all hits -10% | Every 5th hit in a row on the same nightmare strikes twice. Pulse and spin Wardens are not affected. | A second strike on the fifth | E, T, D, P, I | NEEDS OWNER CALL (drop the 10%?) |
| bright_marks | Bright Marks | C, S | +30 points at full Exposed | Wardens reach 1 cell further to hit a fully Exposed nightmare. | Far Wardens join in on lit targets | I | APPROVE-READY |
| quickened_sap | Target Turnover | U, S, basic | 35% faster after a switch | A shot whose target is dispelled before it lands turns to the nearest nightmare instead of being lost. | Shots curve to a new target | I, T, D, R | APPROVE-READY |
| crowded_path | In the Thick | U, S | +5% per nightmare in range | While 5 or more nightmares are in a Warden's range, its attacks also hit a second nightmare. | Two shots per attack in crowds | I, R, D | APPROVE-READY |
| crowd_breaker | Crowd Breaker | U, S | Area +5% per nightmare hit | An area attack that hits 5 or more nightmares strikes a second time at once. | A double flash on a packed splash | I | APPROVE-READY |
| corner_sign | Corner Sign | U, S | +1 stack after a bend | Statuses applied to a nightmare standing on a bend land with double stacks. | Dots fill faster on corners | I, E, D | APPROVE-READY |
| quiet_vigil | Quiet Vigil | U, S | Idle 5 s: +3 Exposed | Each Warden's first hit of every drift leaves its target fully Exposed for 5 s. | The front of each drift lights up | I, R, E, D | NEEDS OWNER CALL |
| passing_thread | Passing Thread | U, S | Switch copies 1 stack | When a status fills up on a nightmare, half its stacks also jump to the nightmare behind. Once per nightmare per status. | Dots hop down the line | I, T, D | APPROVE-READY |
| blessing_sporeling | Spore Reserve | U, S | Switch moves 3 Poisoned | When a Warden switches target, up to 10 Poisoned stacks move with it from the old target to the new one. | Poison dots jump across | I, D | APPROVE-READY |
| heavy_air | Heavy Air | U, S | Slows 40% stronger | A nightmare already slowed to the limit that is slowed again is Rooted for 1 s. Once per nightmare every 5 s. | Slowed nightmares stop dead | I, T | APPROVE-READY |
| hedge_maze | Hedge Maze | U, S | +5% per touching Thornwall | A Warden's reach also spreads from up to 2 Thornwalls touching it. | The range ring grows around walls | I, R | NEEDS OWNER CALL |
| lone_hunter | Lone Hunter | U, S | +45% to isolated nightmares | Wardens aim first at a nightmare with no other within 2 cells, and deal 45% more to it. | Stragglers get picked off | I | APPROVE-READY |
| fresh_growth | Fresh Growth | U, S | Planted or grown in a drift: +50% | A Warden grown into a new form during a drift deals 50% more damage until the next rest. | A glow on freshly grown Wardens | T | APPROVE-READY |
| cozy_corners | Cozy Corners | U, S | Beside a bend: +30% | The Warden on the inside of a bend deals 30% more damage. One Warden per bend. | One marked Warden per corner | T (P, I keep) | NEEDS OWNER CALL |
| dream_residue | Dream Residue | U, S | Leaving Caught: 2 Drowsy | A nightmare leaving a Dreamcatcher's Caught effect keeps half its full Drowsy stacks. | It leaves the catcher still slow | I | APPROVE-READY (Tower Code checks Caught rules) |
| elder_kin | Elder Kin | U, S | Kin share 25% of rank bonuses | A ranked Warden in a Kinship also gives its kin its latest rank choice. | Kin shows the borrowed choice | I | NEEDS OWNER CALL (touches rank-V rewards) |
| falling_weight | Falling Weight | U, S | Stone +45% vs Rooted or asleep | A Pebbling-line stone landing on a Rooted or sleeping nightmare deals 45% more and leaves rubble under it. | Rubble under held nightmares | I | APPROVE-READY |
| homing_instinct | Homing Instinct | U, S | Birds return 50% faster | Nestling-line birds hit every nightmare they fly through on the way home, for half damage. | Birds rake the path flying back | I | APPROVE-READY |
| ill_wind | Ill Wind | U, S | Copied statuses +45% | A status copied by Gust or Zephyr deals one tick of its damage the moment it lands. | Damage numbers along the gust | I | APPROVE-READY |
| lingering_ground | Lingering Ground | U, S | Ground effects last 50% longer | A ground effect returns to its full time when a nightmare is dispelled on it, up to 3 times. | Clouds and rubble refill on dispels | I | APPROVE-READY |
| spinning_corners | Spinning Corners | U, S | Spin 45% faster at a bend | Pinwheels and Windmills beside a bend fling each nightmare on it back half a cell. Once per nightmare. | Nightmares tossed back at the corner | I, D | APPROVE-READY |
| sweet_harmony | Sweet Harmony | U, S | Harmonies +50%, faster | Harmonies also strike the nightmares within 1 cell of their target. | Harmony bursts over a group | I | APPROVE-READY |
| shared_mycelium | Shared Mycelium | R, S | Two Wardens: +2 Poisoned | When two different Wardens add Poisoned within 2 s, the nightmare gains 8 extra stacks. Once per nightmare every 2 s. | The poison bar jumps | I, R, D | APPROVE-READY (trigger: see section 8) |
| crossed_sparks | Crossed Sparks | R, S | Two Wardens: +2 Charged | When two different Wardens add Charged within 2 s, the nightmare becomes fully Charged and its bolt fires. Once per nightmare every 4 s. | An instant bolt from a crossed pair | I, D | APPROVE-READY (trigger: see section 8) |
| murmur | Murmur | R, S | Second bird hit +30% | Nestling-line birds within 3 cells of each other swoop together at one nightmare. A shared swoop deals 30% more. | Birds dive as a flock | I, D | APPROVE-READY |
| old_growth | Steadfast | R, S | Old Wardens "pin" 0.4 s | Each nightmare's first hit from a Warden that has stood 5 drifts Roots it for 1 s. Not bosses. Selling resets the Warden. | Old Wardens stop each newcomer | I, E, P | APPROVE-READY |
| thinning_the_herd | Thinning the Herd | R, S | +2% per dispel in range | Every 10th nightmare dispelled in a Warden's range each drift makes its next attack hit every nightmare in range. | One huge sweep every tenth dispel | I, R, D | APPROVE-READY |
| bramble_oath | Bramble Oath | C, G | +3% per 5 tiles walls add | Nightmares walking between two Thornwalls, one on each side, are slowed 25%. | They crawl through hedge corridors | I, T | APPROVE-READY |
| forests_edge | Forest's Edge | C, G | +35% near the start | Nightmares hit by a Warden within 3 cells of the start are slowed 25% for 3 s. | They leave the gate limping | I, R | APPROVE-READY |
| quickening | Hunt's Rush | C, G | Dispel: 30% faster 4 s | When a Warden dispels a nightmare, its next attack comes at once. | An instant follow-up shot | I | APPROVE-READY |
| seeping | Seeping | U, G | Effects +8% per status | Each time a nightmare gains a second, third or fourth status, its other statuses deal one tick of damage at once. | A burst of numbers on each new status | I | APPROVE-READY |
| sharpened_light | Sharpened Light | U, G | Crits +0.5× | A crit lights the nightmare: it gains 5 Exposed stacks. | Half the Exposed dots on a crit | I, D | APPROVE-READY |
| crosswind | Crosswind | U, G | Samara +25% after another hit | A Samara seed knocks a nightmare another Warden just hit back half a cell. Once per nightmare. | The seed shoves it back | I, D | APPROVE-READY |
| hunters_patience | Hunter's Patience | R, G | +60% elites, +35% bosses, +40% flyers | Every aiming Warden gets the target button. A Warden set to anything but First deals 30% more damage. | You pick targets; chosen ones melt | I, R, T | NEEDS OWNER CALL |
| shared_light | Shared Light | R, G | +4% per touching Warden | A Warden can also attack nightmares in reach of a Warden touching it, for half damage. | Back-row Wardens fire past their ring | I | APPROVE-READY |
| opening_fracture | Opening Fracture | R, G | Crit primes: next other hit +40% | A crit cracks a nightmare open for 2 s: the next hit from a different Warden is also a crit. | Two crit callouts in a row | I, D | APPROVE-READY |
| thousand_cuts | Thousand Cuts | R, G | +2% per hit, up to +60% | A nightmare hit 20 times without a 2 s pause is torn open: it takes 60% more damage until the hits stop. | It flashes open after a flurry | I | APPROVE-READY |
| crossroads | Crossroads | L, G | +40% touching two stretches | A Warden touching two path cells at least 6 steps apart attacks one nightmare on each stretch at the same time. | One Warden firing two ways | I, D | APPROVE-READY |
| full_moon | Full Moon | L, G | +10% crit | When a Warden crits, the Wardens touching it crit on their next attack. A passed-on crit is not passed on again. | Crits ripple through a cluster | I, D | APPROVE-READY |
| the_quiet_ones | The Quiet Ones | L, G | Quiet Wardens 50% stronger | A Warden inside the auras of 2 or more Quiet Wardens fires every attack twice. | Double shots where auras overlap | I, P | APPROVE-READY |
| wildwood_reclaimed | Wildwood Reclaimed | L, G | +30% to +60% on cleared cells | Clearing an obstacle gives a free Nurture rank to each Warden on a cleared cell within 2 cells. | Ranks pop as you clear | I, D | APPROVE-READY |

**5b. Size bumps only** (same card, bigger so it is felt; all APPROVE-READY, numbers to Balancing):

| id | now | new |
|---|---|---|
| hobble (C, S) | Crit slows 30% for 1 s | Crit slows 40% for 2 s |
| switchback (C, S) | Bend slow 25% for 1 s | 40% for 2 s |
| undergrowth (C, S) | Sprout clumps +0.5 reach | +1 cell |
| wide_swing (C, S) | Every 3rd area attack 0.75 wider | Twice as wide |
| emergency_reserves (C, S) | 8 Dew on first leaf loss per block | 20 Dew, with a Dew popup |
| afterroot (U, S) | +2 Exposed | +5 Exposed |
| kins_keepsake (U, S) | 1 Dew, up to 6 a drift | 3 Dew per Kinship's first Harmony each drift |
| spore_kin (U, S) | Harmony applies 2 Poisoned | 6 Poisoned |
| lullaby / Slow Waking (U, S) | Caught lasts 1 s past range | 2 s |
| hushed_hedge (U, G) | First nightmare per wall per drift | First 3 |

**Not ruled yet (second wave, Grove Uncommons flagged by I):** backspin, deep_frost, far_reach, grandfather_stump, hairpin_winds, heavy_eyelids, hush, kind_canopy, mixed_grove, needle_point, patient_aim, patient_roots, shiny_things, still_target, tended_stumps. I's proposals for these cannot be approved as written:
- hairpin_winds and patient_roots are more slows (budget used).
- kind_canopy and grandfather_stump reuse "fires twice" and "attacks at once".
- tended_stumps copies Briar Trap. hush copies Great Ripple.
- mixed_grove adds 1 stack, which is too small.
- patient_aim rewards not firing.
- deep_frost, needle_point and shiny_things rest on rules I did not check in code.

## 6. Keep as numbers

- **Dew, Sprout and clearing economy:** bountiful, cheap_seeds, seedfall, seedling_gift, evergreen, steady_roots, tender_care, tender_care_ii, groundskeeper, heartwoods_reach, reclaimed_earth, weed_puller, weathered_walls, warm_hearth, morning_dew, harvest_moon, dew_bowl, deep_well, dew_line, dew_trail, winding_path (add a cap, section 9), sudden_insight, glimmering_hunt, wandering_mind.
- **Survival staples everyone understands:** deep_roots, thick_bark.
- **Risks the player chooses:** bold_opening, call_of_the_wild, quick_step, last_stand, last_leaf, desperate_bloom, scarred_bark, moonflip.
- **Real trades with a price:** blood_is_thicker, chosen_few, deep_sleep, thin_bark, venom_bloom, whirlwind_heart, monoculture, few_and_mighty, the_last_light, odd_one_out.
- **Big simple effects players feel:** first_light, lasting_dreams, heavy_dew, deeper_calm (add the on-screen sign).
- **Percent cards that need real building:** cozy_corners (pending section 9), straightaway, narrow_way, solitude, rootbound, nightshade, heart_of_the_maze.

## 7. Texts to rewrite without changing the effect

| Card | Current text (short) | Plain rewrite |
|---|---|---|
| Crossfire | "Two Wardens landing original primary hits… nearest ground follower within 2 route cells, for 40% of the weaker hit…" | When two Wardens hit the same nightmare within 1 s, the walking nightmare behind it takes 40% of the weaker hit. |
| Drumbeat | "…joins a relay. Every 2 distinct adjacent Wardens completing original attacks advances its next attack by 35% of one base attack interval…" | A Warden touching 2 or more attackers attacks sooner each time two different neighbours attack. |
| Stored Rain | "…removes Damp and suppresses the whole attack… doubled-base-power, non-critical hit…" (55 words) | A water attack on a Soaked nightmare leaves a puddle for 4 s instead. The next walking nightmare to step in it takes a double hit. |
| Stone Relay | "An original stone hit embeds one stone per living target… spends it to strike the first living follower…" (46 words) | A stone hit lodges a stone in the nightmare. The next hit from another family knocks it into the nightmare behind, for 75%. |
| Brimming | Four sentences of exceptions | Nightmares hold twice as many stacks of every status. Reactions need twice the build-up and hit 2.2 times as hard. |
| Canopy | "Attackers in an orthogonally connected cluster of at least 6…" | Six or more attackers side by side get +1 range while the group is fighting 6 or more nightmares. |
| Grand Tour | "…up to 1 extra second each. Each status lifetime can gain at most 1 second in total…" | A new status on a nightmare makes its other statuses last 1 s longer, once each. Not Rooted or sleep. |
| Endless Rings | Cost list, damage, naming and neighbours in one box (47 words) | The Eldest has no top rank. Each rank past VII costs 1.2 times the last. Wardens touching the Eldest get a quarter of its rank bonuses. |
| Shared Training (P) | "…four matching picks each on the same training gain its signature or mastery at rank IV." | Two bonded kin that both made the same rank choice four times get their rank V reward at rank IV. |
| Whirlwind Heart (P, D) | "All attack speed bonuses count double, and every hit deals 20% less damage." | Every "attacks faster" bonus you have counts double. Every hit deals 20% less. |
| Last Collection (P) | "…pay 20% more of their actual Dew share." | Nightmares dispelled within 3 cells of the Heartwood drop 20% more Dew. |

Moved to section 5 because the effect must change: **Fifth Beat**, **Steadfast**, **Spore Reserve**, **Passing Thread**, **The Quiet Ones**.

Two rules for every card text from now on (P, D):
- One sentence for the effect. Cooldowns and edge cases ("no follower: the stone is still spent") go in the Codex.
- One word per idea: "path cells" (not tiles, steps or route cells), "touching" (and the Codex says corners count), "hit" (not "original primary direct hit").

## 8. Structural gaps

- **Defining cards per archetype (rule: 4).** tall 3, overgrowth 3, swift 2. None of the reworked cards in section 5 is strong enough to promote. Tall and overgrowth each need one new defining card; swift needs two. Design work for Roguelite Code with Tower Discussion.
- **Helpers per archetype (rule: 6).** The tag fixes in section 4 bring affliction to 6. Tall (4) and overgrowth (5) stay short. Retiring more cards from these two must stop until they are back-filled.
- **Start-pool Rares and Legendaries.** Daring, tending, swift and reach have none; swift has no Rare anywhere; kinship has no Legendary anywhere; start Legendaries fell from 4 to 2. Grove cards stay in the Grove, so this needs four new start Rares (section 9, question 5). Until then boss rests will repeat the same six generic Rares (R, inference).
- **The "two Wardens within N seconds" template (9 cards).** No report states the "doubly covered cells" proposal in so many words; it follows from T's point that these cards are really about two Wardens' reach overlapping, and from the Lantern Glow reworks by I and R. My ruling:
  - Adopt it for the four cards where the timer is only a stopwatch: **Shared Mycelium, Crossed Sparks, Overlap, Crossfire**. They trigger for a nightmare standing on a path cell that both Wardens reach. The build ghost shows those cells, using the same glow as Lantern Glow.
  - Keep the timer on the five where the order of events is the point: Opening Fracture, Afterroot, Crosswind, Murmur (now a shared swoop), Twin Strike (now shared aim).
  - Why: the player can plan it while building, it is worked out on placement instead of per hit, and it ends "same sentence, status swapped". The rule that both Wardens must really apply the status stays.
- **Target modes.** Only Standing Stone and Moonstone have the button, so "what to target" is not a decision today (T). I do not recommend giving it to every Warden by default: it adds a control to every Warden panel and is awkward on touch. Give it through cards instead: Growth Rings (rank III Wardens) and Hunter's Patience (every aiming Warden, with a payoff). Owner call, question 2.

## 9. Decisions only the owner can make

1. **Fifth Beat: drop the "all hits deal 10% less" price?** Recommend yes. With it the best case is about 108% of normal, which is not felt, and Flurry (Uncommon) already does more with no price.
2. **Target button through cards (Growth Rings, Hunter's Patience) instead of on every Warden?** Recommend yes.
3. **Cozy Corners: only the Warden on the inside of each bend?** Recommend yes; half cells made it nearly automatic.
4. **Switch four "within N seconds" cards to "a path cell both Wardens reach", shown in the build ghost?** Recommend yes.
5. **Add four new start-pool Rares (daring, tending, swift, reach) rather than move Grove cards?** Recommend yes; exclusives stay exclusive.
6. **Rooted Bond describes selling and replanting. Retire it from offers (id kept)?** Recommend yes; it is the only card that scripts a juggle.
7. **Morning Dew is in every run's pool and pays more the earlier you take it. Sample it like other cards?** Recommend yes, for Morning Dew only; leave the other six basics.
8. **Winding Path has no cap (30 Dew a rest at 60 covered cells; the universal maze reward stops at 20). Cap it at 25 and count only cells your maze added?** Recommend yes.

Smaller calls are marked NEEDS OWNER CALL in the section 5 table: Forest Floor, Growth Rings, Early Bird, Quiet Vigil, Hedge Maze, Elder Kin.

## 10. Order of work

1. **Fix what is broken (section 4).** Card files, tags, `requires`, `PLAIN_STAT_CARDS`, `board_can_use` gates: Roguelite Code. Fifth Beat echo and pulse penalty, Steadfast, First Frost statics, the per-frame flag and the scans: Tower Code. Few and Mighty shown number: Main / UI.
2. **Rewrite the texts (section 7) and the size bumps (5b).** Card data: Roguelite Code. Card layout and Codex small print: Main / UI. Bump values: Balancing Discussion.
3. **Rework the start-pool cards (section 5, Commons first, then Uncommons and Rares).** Hooks in Tower and Enemy code: Tower Code. Card data and offer gates: Roguelite Code. Build-ghost glow for covered cells, new callouts and the target button: Main / UI. Starting numbers: Balancing Discussion. Do the 15 cards in I's "change first" list before the rest and play them.
4. **Grove cards and structure.** The 14 Grove rows in section 5 and the second wave: Tower Code and Roguelite Code, with Meta Game Discussion confirming each node still fits its branch. New start Rares and defining cards (section 8): designed with the owner, built by Roguelite Code and Tower Code, tuned by Balancing Discussion.

---

## 11. Owner direction and the "families as classes" proposal (2026-10-11)

### What the owner said

> "Want it to feel like Slay the Spire having impact when you build your deck and playstyle is
> different. Starting Warden should feel like classes and different cards offered can change your
> build. The increased stacking helps with cards feeling more impactful and increases maze design."

The owner then agreed with this plan:

1. Fix what's broken (section 4) before changing more cards.
2. Make the first family a class: one built-in rule per family, kept all run.
3. Rework the Commons in batches of about 15, with play between batches.

**Answers to the eight questions in section 9:**

| # | Question | Answer |
|---|---|---|
| 1 | Drop Fifth Beat's "all hits deal 10% less"? | **Yes** |
| 2 | Target button through cards (Growth Rings, Hunter's Patience), not on every Warden? | **Yes** |
| 3 | Cozy Corners: only the Warden on the inside of each bend? | **Yes** |
| 4 | Four "within N seconds" cards trigger on a path cell both Wardens reach? | **Yes** |
| 5 | Four new start-pool Rares? | **Wait.** Design them after the class rules; the Rares each build needs may change. |
| 6 | Retire Rooted Bond from offers? | **Yes** |
| 7 | Sample Morning Dew like other cards? | **Yes** |
| 8 | Cap Winding Path at 25 and count only added path? | **Yes** |

The six smaller calls in the section 5 table (Forest Floor, Growth Rings, Early Bird, Quiet Vigil,
Hedge Maze, Elder Kin) are still open.

**Stacking stays.** The higher status caps are kept. Cards that add a fixed 1–3 stacks change to
fill **a share of the cap** (for example "fills a quarter of Exposed"), so they scale with the caps
and with Brimming.

### The proposal: a Calling for your first family

**Status: proposal for the owner's approval. Nothing is built.**

**The idea.** In Slay the Spire your class gives you a starter relic and decides how every card
reads. Here, the family you take at the **first pick** (after drift 1) becomes your class. It comes
with a **Calling**: one built-in rule you keep all run.

**Rules:**
- You get the Calling **with the first pick**, not from a Dream offer. Each of the three families
  on the first-pick screen shows its Calling, so the choice is informed.
- Only the **first** family brings its Calling. Families picked later (drifts 25, 50, 75) join as
  additions, without theirs.
- The Calling applies to the whole family line, including branches and final forms.
- It's shown as a small badge beside the Dreams row, and in "Dreams this run".
- It never changes Dream offers. No steering: it's a lens for judging the random cards.
- Unlocking a new family in the Memory Grove unlocks a new class.
- **Stone Relay, Stored Rain and Spore Reserve leave the Dream pool** (ids kept, retired from
  offers). Their jobs become the Callings below, with simpler rules.

**The nine Callings.** Each is one sentence, uses only what's in the game, and shows something on
screen. Numbers are starting points for balancing.

| Family | Calling | Rule | What you see | How it changes the run |
|---|---|---|---|---|
| Sporeling | **Take Root** | A nightmare whose Poisoned reaches half its cap takes root: it is Rooted for 1.5 s. Once per nightmare; bosses for half as long. | Roots grip a nightmare glowing with spores | Two Sporelings working one stretch stop nightmares there, and the Rooted nightmare's spores tick three times as fast (Smother). It gives the spore class its own Rooted, so more Reactions open up. |
| Firefly Jar | **Lantern Ring** | Any Warden's hit on a nightmare inside a Firefly Jar's reach also adds Charged. | The Jar's ring sparks on each hit | The Jar becomes a hub: plant your other Wardens so they shoot into its ring. |
| Dewdrop | **Splashback** | The first hit on a Soaked nightmare from another family splashes onto the nightmares beside it. | A splash of water off the other Warden's hit | Soaked matters to every family. Dewdrop's branches (fog, rain, trails) become ways to set it up. |
| Bellflower | **Ringing** | Each Bellflower pulse deepens every status a nightmare already carries (a tenth of its cap each). | Status pips jumping on each ring | The bell amplifies whatever your other families apply. Plant it where their statuses land. |
| Acorn | **Volley** | Every 5th acorn the Acorn throws, every Warden in its aura attacks at once at the Acorn's target. Pulse Wardens pulse at once. | A burst from the whole cluster | The Acorn conducts its neighbours. What you plant around it decides what the volley does. |
| Nestling | **Perches** | A Nestling's bird can also swoop from any of your Wardens within 3 cells, and its hit adds that Warden's status. | Birds launching from other Wardens | Every Warden you plant is a perch. Birds carry your other families' statuses across the map. |
| Pebbling | **Lodged Stone** | A Pebbling's stone lodges in its target. The next hit from another kind of Warden knocks it into the nightmare behind. | A stone sitting on the nightmare, then flying on | Stone sets up, others cash in. Every second family you add gets better. |
| Rootling | **Anvil** | Every Warden that reaches a Rooted nightmare turns to it, and their hits on it add double stacks. | Shots swinging to the Rooted nightmare | Roots pick the target. Heavy hitters land on it, and status families fill it fast. |
| Whirligig | **Tailwind** | Attacks that pass through a Whirligig's reach go further: shots fly on to a second nightmare, and pulses and splashes spread 1 cell wider. | Shots bending onward; wider rings | Plant Whirligigs between your Wardens and the path. |

**Checks against the council's findings:**
- **Pulse and spin families are included.** Bellflower, Rootling, Acorn and Whirligig each get a
  Calling that works with how they attack. None depends on "primary target".
- **No device is overused.** Attack at once is used once (Volley), turning aim once (Anvil), a short Rooted once (Take Root). No Calling pushes nightmares back; that stays with the Rootling branches and Tidecaller.
- **Control stays bounded.** Take Root is once per nightmare. Anvil speeds up stacks; it doesn't
  lengthen Rooted.
- **Stacking.** Take Root, Lantern Ring, Ringing and Anvil all scale with the higher caps
  rather than adding a fixed few stacks.
- **Performance.** Lantern Ring, Perches, Volley and Tailwind can be worked out when Wardens are
  planted or sold, not per hit. Spore Bed and Wet Ground reuse the existing ground-effect nodes.
- **Free power.** A Calling is extra strength every run. Balancing sets the numbers so act 1
  survival stays where it is now.

**Also part of this proposal:**
- **Generic cards must work for every class.** A card keyed to "the Warden's target" counts a
  pulse or spin Warden's target as the nightmare furthest along in its reach. Where that can't
  work, the card says "aiming Wardens" in its text.
- **Later option, not proposed now:** a Rare Dream that grants a second family's Calling. Wait
  until the first nine are played.

**Owner's answers (2026-10-11):**
1. **Only the first family brings its Calling.** Approved.
2. **The first pick keeps offering random families.** Approved.
3. The idea is approved. The owner asked what Acorn's first Calling (Rally: neighbours aim at the
   Acorn's target) gains. It gained little, because Wardens already aim at the nightmare furthest
   along. It's replaced by **Volley** in the table above (my recommendation; the owner hasn't
   confirmed it yet).

### Calling check: builds and family combinations (2026-10-11)

The owner asked that every Calling allow different builds and combine with the other families.
I checked each one against the eight other families and against the builds. Four of the first
drafts failed and are revised in the table above:

| Calling | Problem in the first draft | Revision |
|---|---|---|
| Wet Ground (Dewdrop) | Soaked alone only boosts water hits, so it did nothing with Pebbling, Nestling or Acorn. | The first hit on a Soaked nightmare from another family splashes to those beside it. (The wet-cell half was later dropped: see the branch check below.) |
| Perches (Nestling) | It only cared about walls, not families. | Birds swoop from your other Wardens and add that Warden's status. |
| Anvil (Rootling) | "Statuses build faster" did nothing with the families that apply no status. | Every Warden turns to the Rooted nightmare, and status hits add double stacks. |
| Tailwind (Whirligig) | It only worked for shots, so Bellflower and Rootling got nothing. | Shots fly on; pulses and splashes spread 1 cell wider. |
| Rally (Acorn) | Wardens already share a target. | Replaced by Volley. |

**What each Calling does with each second family.** "Kin" marks the status families whose
Reaction it sets up.

| Calling (first family) | + Sporeling | + Firefly Jar | + Dewdrop | + Bellflower | + Acorn | + Nestling | + Pebbling | + Rootling | + Whirligig |
|---|---|---|---|---|---|---|---|---|---|
| **Take Root** (Sporeling) | — | Rooted and Poisoned and Charged: Smother, then Ignite | Rooted and Soaked: Shatter | Drowsy keeps nightmares in the puffs longer, so more reach full | aura cluster lands on the Rooted nightmare | birds get a still target | the slow heavy hit can't miss | two Rooted sources: Smother often | gusts copy Poisoned so more nightmares reach full |
| **Lantern Ring** (Firefly Jar) | fast puffs fill Charged; Ignite | — | splash charges a whole group; Thunderclap | each pulse charges everything in the ring | bounces charge three at once | birds charge on every pass | slow, so few stacks, but the bolt lands on a softened target | pulses charge the crowd; Rooted targets sit in the ring | gusts copy Charged out of the ring |
| **Splashback** (Dewdrop) | puffs splash; Mushrooming | sparks splash; Thunderclap | — | pulses splash off every Soaked nightmare; Drown | bounce plus splash covers a pack | bird hits splash | the heaviest hit in the game splashes | pulses splash; Shatter | pulses splash; Soaked is copied down the path |
| **Ringing** (Bellflower) | Poisoned climbs on every ring | Charged climbs: bolts come sooner | Soaked deepens; Drown at full Drowsy | — | nothing but Drowsy to deepen | nothing but Drowsy to deepen | nothing but Drowsy to deepen | deepens Drowsy; Rooted is not deepened | deepens whatever the gusts copy in |
| **Volley** (Acorn) | a burst of Poisoned on one target | a burst of Charged: bolt on demand | everyone hits the Soaked target at once | all bells pulse together | — | every bird launches together | all stones land at once: an alpha strike | pulse and Root on the beat | gust fires with the volley and spreads its statuses |
| **Perches** (Nestling) | birds carry Poisoned anywhere | birds carry Charged | birds carry Soaked | birds carry Drowsy | perch on the Acorn: swoop from inside the aura | — | perch on a far Pebbling: reach only | perch on a Rootling: reach only | perch on a Whirligig: reach only |
| **Lodged Stone** (Pebbling) | fastest trigger: a lodged stone never waits long | fast trigger, and the flying stone hits Charged targets | splash knocks several stones loose at once | one pulse knocks every lodged stone | bounce knocks three | each swoop knocks two | — | pulse knocks all; Rooted leaders line up the one behind | pulse knocks all |
| **Anvil** (Rootling) | double Poisoned on the Rooted one: Smother | double Charged: quick bolt | double Soaked: Shatter | double Drowsy: sleep while Rooted | the cluster swings onto it | birds swing onto it | the heavy hit always finds it | — | gust copies its doubled stacks |
| **Tailwind** (Whirligig) | puffs poison two | sparks charge two | splash 1 cell wider | pulse 1 cell wider | acorns fly on, then bounce | no change (birds aren't shots) | the heavy stone hits a second target | pulse 1 cell wider | — |

Weak cells, left as they are on purpose:
- Perches with the three families that apply no status (reach only).
- Ringing with Acorn, Nestling and Pebbling (it deepens Drowsy only).
- Tailwind with Nestling, and Lantern Ring with Pebbling.

Every Calling still has at least five partners that change how it plays, and none needs one
particular partner.

### Branch check: no Calling repeats what a branch already does (2026-10-11)

The owner asked for this check. I read the description of all 122 Wardens in `resource/tower/`
and compared each Calling with every branch and final form. Three Callings repeated a branch and
are replaced in the table above:

| First draft | Branch that already does it | Replaced by |
|---|---|---|
| Spore Bed (dispelled Poisoned nightmares leave spores on the path) | **Deliquescent** ("a Poisoned nightmare it dispels melts into a pool of ink") and **Inkcap** (ink trails that poison walkers), both Sporeling branches | **Take Root:** full Poisoned Roots the nightmare for 1.5 s, once |
| Wet Ground, first half (wet cells make walkers Soaked) | **Torrent** (a 3-tile wet trail), **Mistveil** and **Morning Fog** (fog keeps walkers Soaked), **Cloudlet** and **Nimbus** (rain), all Dewdrop branches | **Splashback:** only the second half is kept (another family's first hit on a Soaked nightmare splashes) |
| Lullaby (full Drowsy stumbles back 1 cell) | **Rootcurl**, **Long Way Home** and **Heartroot** pull nightmares back (Rootling branches); **Tidecaller** pushes back a tile | **Ringing:** each pulse deepens every status the nightmare carries |

**The other six, and the nearest things to them:**

| Calling | Nearest existing thing | Why it isn't a repeat |
|---|---|---|
| Lantern Ring | Chime Stone and Sparkler add Charged with their own attacks; the Legendary Dream Eternal Charge makes every Warden's 4th hit add Charged | No branch makes *other* Wardens' hits add Charged. It does overlap Eternal Charge: Lantern Ring is the local version, tied to the Jar's reach. If both are owned, Eternal Charge still adds outside the ring. |
| Volley | Elder Stump and Grove Heart speed neighbours up; Graftling copies a neighbour's attack | No branch makes neighbours fire together on a beat. |
| Perches | Graftling copies a neighbour's attack "statuses and all"; the Dreams Pollen Beaks and Charged Feathers put Poisoned or Charged on Hummingbird pecks | No branch lets a bird launch from another Warden. The status half overlaps those two Dreams for Hummingbirds; with Perches owned they'd add little. |
| Lodged Stone | Edgestone spills overkill onto the nearest nightmare; Pebbling's own pebble skips on | Neither needs a second family to trigger. |
| Anvil | World Root (Rooted nightmares take 30% more), Thorncoil, Sunpetal and Old Mountain reward Rooted targets with their own attacks | No branch turns other Wardens' aim or doubles their stacks. |
| Tailwind | Midsummer's beam and Jetreed's jet carry on behind their target; Rain Lily splashes wider | Those change one Warden's own attack. Tailwind is a zone that changes other Wardens' attacks. |
| Splashback | Undercurrent's whirlpool shares 25% of a hit between nightmares standing in it | Splashback needs Soaked, not a whirlpool, and fires once per nightmare per Soaking. Close in feel; flag for the playtest. |
| Take Root | Hoarfrost freezes a nightmare Soaked twice; Dreamshroom puts a nightmare at full Drowsy to sleep | Same pattern (a full status stops the nightmare) on a different status. No Sporeling branch Roots. |
| Ringing | Whirligig and Gust copy statuses from one nightmare to another | Ringing deepens what's already there; it never moves it. |

**Two overlaps with Dream cards to settle before building:** Lantern Ring with Eternal Charge, and
Perches with Pollen Beaks / Charged Feathers. Options: leave them (the Calling makes the card a
weaker pick for that class), or stop offering the card to that class.

**Builds each Calling can go into** (so a class isn't one build):

| Calling | Builds it supports | Why they differ |
|---|---|---|
| Take Root | affliction, maze, precision, tall | Stack depth; choose where they stop; crits and heavy hits on a still target; one ranked hitter gets the time. |
| Lantern Ring | swift, overgrowth, tall, affliction | Fast hits charge faster; many Sprouts in the ring; one big hub Jar; Charged Reactions. |
| Splashback | reach, precision, affliction, overgrowth | Wide splashes; one big hit that splashes; Soaked Reactions; many small hits each splash once. |
| Ringing | affliction, swift, maze, kinship | Deeper stacks; faster bells ring more; plant the bell where statuses land; kin statuses deepen together. |
| Volley | overgrowth, tall, precision, kinship | A crowd of Sprouts firing together; a few ranked hitters; first-hit cards; kin inside the aura. |
| Perches | affliction, reach, overgrowth, precision | Status carrier; spread-out perches; Sprouts as perches; lone-Warden cards. |
| Lodged Stone | overgrowth, swift, reach, precision | Sprouts count as another kind; faster triggers; pulses and splashes knock many; a crit stone flies on. |
| Anvil | affliction, precision, tall, maze | Double stacks; focus on one target; a ranked hitter always finds it; Root at a chosen spot. |
| Tailwind | precision, affliction, reach, maze | Second targets for big shots; statuses on two; wider areas; Whirligigs placed between Wardens and path. |

**Still to check in code before building:** how a Rooted nightmare being re-targeted interacts
with Standing Stone's target modes (Anvil), and whether a bird's hit can carry another Warden's
status credit (Perches) without breaking the "native status" rule the cooperation cards use.

### Order of work, updated

1. **Fix what's broken** (section 4).
2. **Callings:** the owner approves the nine; Balancing sets numbers; Tower Code builds the rules;
   Roguelite Code retires the three role cards and adds the first-pick hook; Main / UI shows the
   Calling on the family pick and the badge.
3. **Commons batch 1:** the 15 cards the impact reviewer ranked first (section 5), then a playtest.
4. **Text rewrites** (section 7) alongside batch 1.
5. **Later batches**, then the new Rares and build-defining cards (section 8), designed against
   the Callings.

### Why Rooted makes a good class rule (2026-10-11)

The owner asked whether Rooting allows interesting builds. From the Reaction and Warden data:

- **Rooted is the best-connected status in the game.** It's part of 3 of the 8 Reactions (Smother,
  Shatter, Pinned) and 6 of the 8 Crowned Reactions (Avalanche, Fairy Circle, Fever Dream,
  Prismstorm, Starfall, Still Pool).
- **Take Root pays off on its own.** Rooted + Poisoned is Smother: spores tick three times as fast
  while the nightmare is Rooted. So the class has a loop with no second family: fill, root, burn.
- **Builds it opens with a second family:**
  - **+ Dewdrop:** Shatter (Rooted and Soaked, then a crit or heavy hit deals ×2.5). With
    Mushrooming it also reaches Fairy Circle.
  - **+ Firefly Jar:** Pinned through the Lanternmoth branch (Exposed and Rooted: the next hit is a
    ×3 crit), and Ignite on the held target.
  - **+ Bellflower:** Fever Dream (Smother ending on a fully Drowsy nightmare puts it to sleep).
  - **+ Pebbling:** the slow heavy hit lands on a still target; Falling Weight and Old Mountain
    reward Rooted targets.
  - **+ Rootling:** two Rooted sources and the Rooted payoffs in its branches (Thorncoil, World Root).
- **Threshold changed to half the cap.** Poisoned's cap is 32 and a puff lasts 5 s. One base
  Sporeling (2 puffs a second) holds about 10 stacks on a target, so "full" would need four
  Sporelings and would never fire early. Half the cap (16; 32 with Brimming) needs two Sporelings
  on the same stretch, which is the multi-Warden play the stacking change is meant to reward.
- **It stays bounded.** Once per nightmare; a Hold already has a 1.5 s cooldown (3 s on bosses)
  and a 2.25 s cap in `enemy_statuses.gd`.

---

## 12. Built on 2026-10-11 (committed as 67940fac, not pushed)

The owner chose "bugs + Callings" for the first pass, with parse checks and targeted tests allowed.
Nothing is committed. The 15-card Commons batch, the text rewrites of section 7 and the new Rares
are **not** built yet.

### Callings

| Piece | Where |
|---|---|
| The nine rules, their names and card texts, starting numbers | `scripts/combat/callings.gd` (new; preloaded, no `class_name`) |
| The run's Calling: `DreamState.calling`, `set_calling()`, `calling_title()`, `calling_text()`, signal `calling_changed`; saved as `"calling"` | `scripts/run/dream_state.gd` |
| Set at the first pick only; shown on each family card at the first pick; a toast names it | `scripts/ui/family_pick_screen.gd` |
| Hooks: after a hit, status application, aiming, the attack release, shots and landings, pulse and splash width | `scripts/tower/tower.gd` |
| Lodged Stone reuses the Stone Relay code | `scripts/tower/dream_build_rules.gd` |
| Stone Relay, Stored Rain, Spore Reserve: `retired = true` (ids and effects stay for old saves) | `resource/meta/blessing/` |
| Test | `tests/test_callings.gd` |

How the open code questions were settled:
- **Anvil and target modes:** a Warden whose target mode the player chose keeps it; Anvil only turns
  Wardens on their default aim.
- **Perches and "native" statuses:** the perch's status is added as a non-native stack, so it never
  counts for the two-Warden cooperation cards.
- **Volley:** a volley's forced attacks don't count toward the next volley.
- **Tailwind:** the onward shot deals 60% and never flies on again.

Not built for Callings yet: a badge beside the Dreams row, the Calling in "Dreams this run" and the
Codex, and effects art (the rules use existing dust and burst effects). Dev runs that skip the
family pick have no Calling.

### Fixes from section 4

| Item | Done |
|---|---|
| `spore_cascade_ii` file defect | Fixed: the card is retired again |
| Fifth Beat double defence | Fixed: the echo and Crossfire's bolt store the hit before defences |
| Fifth Beat's 10% price | Removed (owner's answer 1), which also ends the penalty on pulse and spin Wardens. Text rewritten |
| Corner Sign, Quiet Vigil, Crossfire | Texts now say what the code does. Their reworks wait for the Commons batches |
| Steadfast | Applies a normal Rooted through `Tower.hold` |
| Few and Mighty | The shown number is capped at +80% like the effect |
| Shared Mycelium with no Poisoned Warden | Gated in `board_can_use` (a Warden that applies Poisoned). Its tags and Needs are unchanged: successors must keep their predecessor's (`test_unique_dream_catalogue`) |
| Missing build tags | 11 cards tagged. Passing Thread and Shared Mycelium are left as they are for the same successor rule |
| First Frost's static count | Reset when a run starts |
| `board_can_use` gates | Added for Crossfire, Drumbeat and Steadfast |
| Cost with no card owned | The cooperation bookkeeping in `Tower.hit` only runs when Crosswind, Opening Fracture or Afterroot is owned |
| Docs | Canopy's stale line in `dream_design.md`; Wellspring cap 130 in `CLAUDE.md` |

**Left for later, on purpose:**
- `PLAIN_STAT_CARDS`: the 2026-10-09 rework says the one-simple-combat-card limit is retained, so
  the list is unchanged until the owner decides.
- Stored Rain against a lone boss: the card is retired now.
- The other performance items (Wake Ripple, Canopy, Switchback, per-nightmare group lookups).
- Canopy's connection gate and the Drumbeat half-cell check.
- Defining and helper counts, and the new start-pool Rares (design work, section 8).

---

## 13. Callings rework: cards carry the class (2026-10-12, proposal; nothing built)

### Owner direction

After a Firefly Jar start: *"still don't feel like there are different builds with a class; went
with starting Firefly and was pretty much given 1 build."* And: *"should feel like cards are
helping you decide the build."*

**What went wrong in section 11.** The check asked "does the Calling combine with every second
family?" It needed to ask "can the cards change where the run goes?" Lantern Ring is an always-on
payoff, so every Firefly run is "fill Charged". In Slay the Spire the starter relic is small and
the class is its card pool. Section 11 built it the other way round.

**Approved shape:**
- The Calling shrinks to a small setup. It can stay small in act 1.
- Each family gets **12 class cards** in the normal Dream pool, offered only when that family is
  the Calling. They're random like any card and never guaranteed.
- Three directions with 3 cards each, plus 3 bridge cards that each belong to two directions, so
  every direction has 5 cards it can use and players can pivot.
- Each direction has a Common way in and one Rare that defines it.
- Each direction changes **placement**, not just numbers.
- Up to two class cards per offer. Random Dreams, no steering, Grove exclusives and the chase
  ceiling (about 30% by drift 50, 50% by 75) all stand.
- **Firefly Jar is the prototype.** The owner plays it before the other eight families are
  touched. Their Callings from section 11 stay as built until then.

### Firefly Jar: the Calling

**Lantern Light.** Path cells within 3 cells of a Firefly-family Warden glow. Nightmares on them
are **Lit**: they can't hide, and your Firefly cards work on them.

- Lit is a place on the path, drawn as a glow, not a second ring around the Warden. Long-range
  forms (Lanternmoth 4.5 cells, Sunpetal 3.5) can shoot nightmares that aren't Lit.
- Three cells is about 28 of the map's 414 cells per Warden (tower-defence review).
- No free Charged any more.

### Firefly Jar: the 12 class cards

The first draft went to three council members (roguelite, tower defence, player). Their main
findings, and what changed:

| Finding | Change |
|---|---|
| Storm and Spotlight were the same board; Lanternway had no payoff of its own | Each direction now needs a different layout and has its own payoff (below) |
| Lantern Ring as an Uncommon was the old Calling again: an auto-pick | It's the Storm **Rare**, and only works where two lights overlap |
| Hard Light was nearly dead (a Jar attacks 1.5 times a second) and unreadable | Now Hammerfall, keyed to "once a second or slower", which the family's own branches meet |
| Carried Spark was farmable by two Jars side by side | The nightmare must leave one light and enter a different one |
| Three cards were invisible in play (Kept Spark, Afterglow, Lantern Reach) | Kept Spark and Lantern Reach are replaced; Afterglow gets a visible trail |
| Lantern Ring, Flashpoint and Carried Spark all read as "more Charged" | Only two cards add Charged outright now; Flashpoint is the crit bridge |
| Five names with Lantern or Light blurred together | Renamed; two remain |

**The three directions and their boards:**
- **Storm: lights that overlap.** Jars packed together so their glows cross, with everything
  firing into the crossing.
- **Spotlight: Jars as spotters.** A Jar or two forward on the path; slow, long-range Wardens
  behind them.
- **Lanternway: lights apart.** Jars at least 4 cells from each other along the route, so a
  nightmare enters one light after another.

Storm and Lanternway pull opposite ways on purpose.

| # | Card | Rarity | Direction | Text | What you see |
|---|---|---|---|---|---|
| 1 | **Crossed Beams** | Common | Storm | Where two lights overlap, Firefly-family hits add 1 extra Charged. | A brighter patch where glows cross |
| 2 | **Chain of Lanterns** | Uncommon | Storm | A Lit nightmare's bolt also strikes the 3 nearest Lit nightmares for half. | Lightning forking through the glow |
| 3 | **Lantern Ring** | Rare | Storm | Where two lights overlap, any Warden's hit adds 1 Charged. Once per nightmare each second. | Sparks off every Warden's hits |
| 4 | **Spotters** | Common | Spotlight | Wardens with range 4 or more can hit Lit nightmares 1 cell beyond their reach. | Shots landing past the range ring |
| 5 | **Hammerfall** | Uncommon | Spotlight | Wardens that attack once a second or slower deal 25% more damage to Lit nightmares. | A heavy flash on the hit |
| 6 | **Spotlight** | Rare | Spotlight | The Lit nightmare furthest along is in the Spotlight. Hits on it from slow Wardens are crits. | A beam on one nightmare |
| 7 | **Afterglow** | Common | Lanternway | A nightmare stays Lit for 3 s after it leaves a light. | A fading glow that follows it |
| 8 | **Firefly Trail** | Uncommon | Lanternway | A nightmare that has passed through 3 different lights takes 30% more damage for the rest of its walk. | Three lights gathering over it |
| 9 | **Lone Watch** | Rare | Lanternway | A Firefly-family Warden with no other within 4 cells lights 1 cell further, and attacks each nightmare at once when it enters its light. | A wider glow; a shot the moment they step in |
| 10 | **Flashpoint** | Uncommon | Storm + Spotlight | A crit on a Lit nightmare adds 3 Charged. | A burst of sparks on the crit |
| 11 | **Carried Spark** | Uncommon | Storm + Lanternway | A nightmare that leaves one light and enters a different one gains 4 Charged. | A spark jumping light to light |
| 12 | **Ambush** | Uncommon | Spotlight + Lanternway | Each time a nightmare enters a light, the first hit on it from each Warden is a crit. | A flash on the first hits |

- **"Slow Wardens"** on Spotlight means the same as Hammerfall: once a second or slower, by base
  rate. Prism Jar, Lanternmoth and Sunpetal qualify (all exactly 1.0), and so do Pebbling,
  Bellflower and most heavy hitters. The Jar itself doesn't.
- **Each direction has 5 cards:** Storm 1, 2, 3, 10, 11. Spotlight 4, 5, 6, 10, 12. Lanternway
  7, 8, 9, 11, 12.
- **Nearest existing cards, and why these aren't repeats:**
  - Chain of Lanterns vs Live Wire and Static Field: those work anywhere; this only chains through
    the glow, so it grows with how much path you light.
  - Ambush vs First Light and Called Shot: those fire once per nightmare; Ambush re-arms at every
    light.
  - Carried Spark vs Jarlink: Jarlink's arc damages nightmares touching the line between two
    Jarlinks; Carried Spark rewards lights that are apart.
  - Spotters vs Long Shadows (Grove): Long Shadows is flat range; Spotters only reaches into the
    glow.
- **Spotlight (6) and Flashpoint (10):** a Spotlight crit can feed Flashpoint, which is the
  intended bridge. Neither makes a second strike, so there's no loop.

### Main class and sub-class (owner question, 2026-10-12)

*"Should we also have main class cards and sub class cards that users have in their pool if they
start with that family, then sub class cards that get entered into the pool once you choose
another family?"*

**Yes, and the sub-class layer mostly exists already.** Every family has cards that need the
family and enter the pool the moment the player owns it, first pick or later:

| Family | Live cards that need it |
|---|---|
| Firefly Jar | 15 |
| Sporeling | 14 |
| Dewdrop | 14 |
| Bellflower | 13 |
| Rootling | 10 |
| Acorn | 8 |
| Pebbling | 7 |
| Nestling | 5 |
| Whirligig | 4 |

Firefly's 15 are six form unlocks plus nine others (Crossed Sparks, Static Field, Resonance,
Falling Stars, and pair cards such as Sparking Spores, Rain on Glass, Charged Feathers,
Fireflies in the Grass, Wildfire Spores).

**Proposed three layers:**

| Layer | Offered when | Size | Job |
|---|---|---|---|
| **Main class** | The family is the Calling | 12 | Decide the build: three directions, each with its own board |
| **Sub-class** | The player owns the family, first pick or later | 4, not counting form unlocks | Bring the family's own mechanic into any run, without the Calling's setup |
| **Pair cards** | The player owns both families | as now | The existing cross-family cards |

- **Sub-class cards never use the Calling's setup.** A Dewdrop start that adds Firefly Jar gets no
  Lit and none of the 12; it gets Firefly's four sub-class cards (Charged and bolts). That keeps
  the class a class.
- **Sub-class cards should name what the main class does, so the two meet.** Example: a Firefly
  sub-class card that adds Charged is what a Sporeling main class wants if one of its directions
  pays off on statuses stacking.
- **No new cards needed for Firefly's sub-class.** Choose four of the nine it has. The rest stay
  as pair cards or go to the Commons rework list.
- **Families are uneven.** Whirligig and Nestling have too few; Sporeling, Dewdrop and Bellflower
  have more than four. That's work for when those families get their turn, not for the prototype.
- **Risk: too many family cards chasing two slots.** A third-family run could hold 12 + 4 + 4 + 4
  plus pair cards. The existing 60% sample per family already thins this; Balancing should check
  how often a class card is seen at all once three families are owned.

### Offer rules for class cards

- Offered only when `DreamState.calling` is that family.
- They count as family cards: at most two per offer, shared with sub-class and pair cards.
- A seeded 60% of the 12 is in each run's pool (the existing family sampling), so about 7 per run
  and each Rare in about 6 runs in 10.
- A direction counts as "complete" only with its Rare (for the chase ceiling).
- Normal rarity odds; no guarantee at boss rests beyond the existing rules.

### Starting numbers, for Balancing

From the tower-defence review (inferred from Jar 18.2 damage, 1.5 attacks a second, Charged cap 20,
bolt x16; no sim):

| Card | Number | Note |
|---|---|---|
| Lantern Ring | once per nightmare each second | at 0.5 s it out-charged the Jar itself |
| Chain of Lanterns | 3 nearest, half | "every Lit nightmare" grew with the square of the crowd |
| Lone Watch | +1 cell | +2 lit most of the map |
| Spotters | +1 cell | |
| Hammerfall | 25% | base rate once a second or slower |
| Firefly Trail | 30% after 3 lights | new; unchecked |
| Crossed Beams | +1 Charged | new; unchecked |
| Flashpoint / Carried Spark | 3 / 4 Charged | of a cap of 20 |
| Afterglow | 3 s | |

### What changes in code (not built)

| File | Change |
|---|---|
| `scripts/combat/callings.gd` | Firefly's Calling becomes Lantern Light: `NAMES` / `TEXTS`; new helpers for Lit (glowing path cells within `LIT_CELLS` 3 of light-line Wardens, cached like `zone`), how many lights cover a nightmare, and "entered a light" (per-nightmare record of the lights it's in). `_lantern_ring` stops being always-on: it runs only with the Lantern Ring card and only in overlapping light, once a second. New hooks for the other eleven cards. The other eight Callings are untouched. |
| `resource/dream/script/upgrade_data.gd` | One new field, `calling` (a family id): a main class card. |
| `scripts/run/dream_state.gd` | `can_offer` refuses a class card unless `calling` matches; class cards count as family cards (`is_family_card`) and are sampled with the family. `DreamState.calling` and its save field stay as they are. |
| `scripts/tower/tower.gd` | Small hooks: extra Charged in overlap (1), crit rules (6, 12), damage (5, 8), reach into the glow (4), attack on entry (9). |
| `scripts/enemy/enemy.gd`, `enemy_statuses.gd` | Lit nightmares are revealed; a bolt's chain (2); Charged on crit and on light-to-light (10, 11); Afterglow's timer (7). |
| Map drawing | The glow on lit path cells (reuse Lantern Glow's or Rootlight's lit-tile drawing). |
| `resource/dream/` | 12 new card files. Sub-class: a tag on the four chosen Firefly cards, no new files. |
| `scripts/ui/family_pick_screen.gd` | The first-pick card shows Lantern Light's text. |
| Tests | `tests/test_callings.gd` (Lantern Ring's part changes); a new test for class-card offers. |

### Open questions for the owner

1. Is "Lit = glowing path cells within 3 cells of a Firefly-family Warden" right, or should each
   form light its own reach?
2. Storm now depends on overlapping lights. Is that the cluster feel you wanted, or should plain
   Storm cards work in any light?
3. Should Lantern Glow (the Common that makes every Warden's reach glow) be kept out of offers for
   a Firefly Calling, since it reads like the Calling?
4. Sub-class: four per family chosen from the cards each family already has, or new ones?

---

## 14. Four class sets and the main class / sub-class layers: council review (2026-10-12; nothing built)

The owner asked for the council's view on main class and sub-class cards, and for the other
starting Wardens to be prototyped with Firefly Jar. Three designers drafted Sporeling, Dewdrop and
Rootling (Rootling assumed as the third, being the demo's fourth family). The roguelite,
tower-defence and player reviewers then read all four sets together.

Work files, all in `D:\Projects\logs\dream_council\`: `sporeling_draft.md`, `dewdrop_draft.md`,
`rootling_draft.md` (the full card tables), `classes_roguelite.md`, `classes_td.md`,
`classes_player.md` (the reviews). Nothing was run; every number is unchecked.

### Verdict

- **The layers are right.** All three reviewers back main class, sub-class and pair cards. The
  player called the lock "Slay the Spire logic and a reason to start with another family".
- **The four sets are not ready to build.** They are one template four times, and three of the
  four bring the old Calling back as a Rare that is still the build.

### The drafts in one table

| Family | Calling (setup) | Direction 1 | Direction 2 | Direction 3 |
|---|---|---|---|---|
| Firefly Jar | Lantern Light: path within 3 cells glows; nightmares there are Lit | Storm: lights overlap | Spotlight: Jars spot for slow Wardens | Lanternway: lights apart |
| Sporeling | First Fruit: at 8 Poisoned a nightmare is Fruiting | Clump: spore Wardens touching | Trail: spore Wardens apart | Host: poison at the start, others finish |
| Dewdrop | Puddles: path beside a Dewdrop is a puddle; Soaked can't run out there | Flood: one big joined puddle | Waterside: other families round a puddle | Runoff: soak early, pay downstream |
| Rootling | Creeping Roots: path beside a Rootling is root ground | Knot: root ground overlaps at a bend | Long Road: separate patches | Runners: Thornwalls carry the roots |

### What the council found

**1. One template four times.**
- "Pack together": Storm, Clump, Flood, Knot.
- "Space apart": Lanternway, Trail, Long Road.
- "Others work my zone": Spotlight, Host, Waterside.
- The same cards repeat: "+1 stack where two overlap" (Crossed Beams, Crowded Caps, Standing
  Water, Double Knot), "no other within 4 cells" (Lone Watch, Lone Cap, Far Roots), "leave one,
  enter the next" (Carried Spark, Patch to Patch, Tripwire).
- The player: "mostly four colours".
- Distinct today: Firefly's Spotlight, Dewdrop's Flood, Rootling's Runners.

**2. The old Calling as a Rare is still the build.** Lantern Ring, Take Root, Splashback and
Anvil each make "any Warden" feed the class status. The player would still auto-pick two of them.

**3. The Commons are dull.** Nearly every Common is "+1 stack", so a player only joins a build
when its Rare appears, which is "given 1 build" again. Runners (Rootling) is the model for a
Common that changes the board.

**4. The Callings do nothing a player can watch at drift 1.** None made the player want the
family. "Rooted has stacks" and "Fruiting" lost them.

**5. The 60% pool sample picks the build before the player does.** With 12 cards and three Rares,
all three Rares are in a run's pool in about 22% of runs, exactly one in about 29%, none in about
6% (paper arithmetic). The player can't see which.

**6. Rules that break on the real board** (tower-defence review, read from code):
- "Touching" fails on half cells: a straight wall touches 2 route cells or none. Use "route within
  1.25 cells of the Warden's centre" and measure size as route length.
- Rootling's control is not bounded as written: Patient Roots stretches a 0.3 s card Root to
  1.3 s or more, and a Root on an already Rooted nightmare skips the wait. Card Roots need a fixed
  length and their own shared wait.
- Burrs and Double Knot would switch Smother, Pinned and Shatter on for good (they read the
  Rooted stack count).
- Stirred Spores, Gathering Stream and Drip Line never let a status end.
- Downstream plus Across the Water gives every Warden beside the water the whole route.
- One Take Root does **not** reach Smother (1 Rooted stack; Smother needs 4). Section 11's claim
  that it does was wrong.

**7. The sub-class picks are leftovers.** Several need a third thing (Drowsy, a Kinship) or are
plain boosts. Mycelium and Afterroot are the models. Dewdrop and Rootling have too few cards and
need new ones.

### Recommended changes before anything is built

1. **Give each class its own question**, so only one class is about "where":

| Family | The class is about | Directions to keep | Replace |
|---|---|---|---|
| Firefly Jar | Where the lights are | Storm, Spotlight, Lanternway | none; it keeps the only "apart" direction |
| Sporeling | How long and how far poison lasts | Clump | Trail and Host, with Ripe (pays for time spent Fruiting, so a long maze) and Spread (poison jumps between nightmares) |
| Dewdrop | The shape of the water | Flood, Waterside | Runoff, with Crossings (pays each time the route re-enters the same puddle) |
| Rootling | Stopping the line | Knot, Runners | Long Road, with Logjam (hold the leader, pay per nightmare piled behind) |

2. **All 12 class cards are always in the pool.** Hold the ceiling (about 30% by drift 50, 50% by
   75) with the Rares' weight, for Balancing to set.
3. **The old Calling's Rare loses "any Warden" or gains a price.** Same test for all four.
4. **Each Calling gets one small thing the player can watch at drift 1**, and its first-pick card
   names the three directions.
5. **Commons change the board**, as Runners does. No "+1 stack" Commons.
6. **Sub-class is 3 cards per family:** one existing card that lends the family's mechanic
   (Mycelium, Afterroot), one more existing card that isn't a plain boost, and one new card that
   works when that family is planted beside a Calling-family Warden. The second family pick says
   what it brings; the words "sub-class" never appear in the game.
7. **Bound the control and the reach** as in finding 6.
8. **Plain words.** No "patch", "root ground", "Fruiting", "outside spore reach" or "tick" in card
   text; the player review has rewrites for 26 cards.

### Open questions for the owner

1. Is Rootling the right third family, or did you mean another?
2. Do you agree each class should ask its own question (table above), or do you want all four on
   the "pack / apart / others help" template so they're quick to learn?
3. All 12 class cards always in the pool, or keep the 60% sample?
4. Sub-class: 3 cards with one new card each, or 4 from existing cards only?
5. Prototype order: Firefly and Dewdrop are closest to ready; Sporeling needs two new directions.
   Build two first, or wait for all four?

### Bellflower, the fourth starting family (owner, 2026-10-12)

The owner corrected the assumption above: the four starting families are Sporeling, Firefly Jar,
Dewdrop and **Bellflower**. The Rootling draft is set aside for when Grove families get their turn.
Bellflower was drafted to the recommendations in this section, not the first template
(`bellflower_draft.md` in the work folder; unreviewed by the council, numbers unchecked).

- **The class is about:** when the bells toll, and what is in the ring when they do.
- **Calling, Keeping Time** (replaces Ringing): each Bellflower-family Warden counts its pulses;
  every 4th is a Toll, a louder ring that reaches 1 cell further. Four petals light, then the big
  ring. It adds no attack.
- **Peal** (a row of bells down one stretch, tolling in route order): Sound Carries (Common),
  Refrain (Uncommon), Call and Answer (Rare).
- **Lullaby** (one or two bells as a "bed", heavy hitters set back; a Toll sleeps one nightmare
  and the player chooses who wakes it): Nod Off (Common), Rude Awakening (Uncommon), Catching
  Yawns (Rare).
- **Crescendo** (one bell inside a hairpin so its reach never empties; call drifts early):
  Overture (Common), Swell (Uncommon), Unbroken Song (Rare).
- **Bridges:** Counting Sheep (Peal + Lullaby), Hanging Note (Peal + Crescendo), With a Start
  (Lullaby + Crescendo).
- **Sub-class:** Chorus and Many Threads (existing), Struck Bell (new: a hit from the first
  family's Warden within 2 cells makes a bell ring again at half strength, once every 3 s).
- **Control:** every card sleep is a fixed 1 s through the one sleep gate (4 s wait, never bosses).
- **Main doubts:** Lullaby's three payoffs need a sleeper card first; a wider ring every 4 s may be
  too small a Calling; Lullaby's board is close to Firefly's Spotlight; "Swell" is also a Dewdrop
  draft card name.

---

## 15. One thing per family (owner idea, 2026-10-12; council review, nothing built)

**Owner:** *"each family has a specific thing that they do so multi building helps with cards like
spore family has cards that increase stacking on statuses, firefly has cards that transfer
statuses since they like to spread damage."* And: *"make sure there is still different build
within the families."*

Reviews in `D:\Projects\logs\dream_council\`: `verbs_roguelite.md`, `verbs_td.md`,
`verbs_player.md`. Nothing was run; all figures are paper arithmetic or read from code.

### Verdict

All three reviewers back it. It answers both problems from section 14: the classes stop being
"four colours", and a second family gets a one-sentence job. The player: it "makes the second
family pick exciting for the first time".

### The four starters' things

Each answers a different question about a status, so they combine without repeating.

| Family | Its thing | The question | What a player sees |
|---|---|---|---|
| Sporeling | **Grow**: a full status does something more | How much | The mushrooms get bigger in steps |
| Firefly Jar | **Jump**: a bolt carries statuses to what it strikes | Who else | An arc in the status's colour |
| Dewdrop | **Pool**: water on the path, and what happens in it | Where | The water itself |
| Bellflower | **Ring**: on a beat, statuses in reach act again | When | A second, fainter ring |

- **"Stacking higher" can't mean higher caps.** Read from code: a higher cap only helps Poisoned.
  It weakens Charged (the bolt fires at the cap), does nothing for Soaked or Exposed, and delays
  full Drowsy. So Sporeling's thing is what a status does once full, never "+N stacks".
- **Firefly's forms move damage today, not statuses** (Stormcap chains, Sparkler sparks). Carrying
  statuses is new for it, and it is Whirligig's whole identity now (Gust and four more forms copy
  statuses). The tower-defence reviewer would keep Firefly to damage only; the roguelite reviewer
  and the player want the statuses to ride the bolt. **Owner call.**
- **Dewdrop is the weak one.** "Statuses last longer" is invisible and the player couldn't picture
  any Dewdrop start. Tying it to water on the path gives it a place and a board.
- Grove families, lower confidence: Rootling Hold, Pebbling Break, Acorn Rally, Nestling Deliver,
  Whirligig Carry (or a new thing if Firefly takes Jump).

### Where the thing lives

| Layer | Job |
|---|---|
| The family itself | Has its thing built in: full strength as the first family (this replaces the Calling), a smaller form as a later family |
| 12 main class cards | Three ways to point the thing, each with its own board |
| 3 sub-class cards | Widen the thing to the first family's status and Wardens |

- **Why built in, not only on cards:** a second family taken at drift 25 gets about five offers
  before drift 50, so a card-only thing would show up in roughly 30% of runs (paper arithmetic).
- **The second family's thing must act on the first family's status**, or both pick orders are
  the same run. The pick screen says it in one line that names the status: "Firefly Jar: your
  Poisoned will jump between nightmares."

### Different builds inside each family (owner's rule)

The thing is how the family works; the three directions are what it is pointed at. Test: two runs
of one family can be told apart from a screenshot.

| Family | State | Three builds |
|---|---|---|
| Firefly Jar | Passes | Storm (jumps spread outward where lights overlap), Spotlight (gathered on one target), Lanternway (handed forward light to light). Jumps must follow the light or Storm always wins. |
| Dewdrop | Passes; the strongest | Flood (one big water, Dewdrops only), Crossings (the route re-enters the same water), Waterside (other families round the water) |
| Bellflower | Passes | Peal (a row tolling in order), Lullaby (sleep one, choose who wakes it), Crescendo (one bell that never falls quiet). Count the beat per nightmare, or Crescendo always wins. |
| Sporeling | **Fails as drafted** | Every direction ends in "the biggest Poisoned number". Proposed: Ripe (pays for time spent full, so a long maze), Wide (three or more different statuses count as full, so many families), Nursery (grows another family's status near spore Wardens) |

A direction that spends or bursts a full stack was suggested for Sporeling, but tower_design.md
records the owner's 2026-09-30 line for the family ("stack it, keep it, spread it; no pop"), so it
is left out unless the owner says otherwise.

### Bounds to write in from the first draft

- **Grow:** never a higher cap, never Rooted (its 4 stacks gate Smother, Pinned and Shatter),
  never longer statuses.
- **Jump:** carries at most half, never past the normal limit, never carried twice, never Rooted
  or sleep, never onto a boss, and at the receiver's strength, not the sender's.
- **Ring:** uses up what it pays out; one jump per nightmare per ring. Firefly plus Bellflower is
  degenerate on paper without that (damage grows with the square of the crowd).
- **Pool:** never stops a status's clock.
- **Every lent thing is tied to distance from the lending Warden** (within 1.25 cells of its
  centre; "touching" fails on half cells), or it is a damage boost in disguise.
- **Each thing needs a bad matchup:** jumping on a lone boss, growing against swarms.

### Risks

- **Sporeling plus Firefly is the strongest pair**, and the player would take Firefly second every
  time. The Jump bounds above are the guard; Balancing should check it first.
- **Cards already doing a family's thing sit in the general pool or on the wrong family:**
  Brimming, Passing Dream, Passing Thread, Spore Cascade, Live Wire; the Callings Ringing
  ("deepens every status"), Anvil ("double stacks") and Tailwind. They need moving or retiring
  before the things are added.
- **Catching Yawns** (Bellflower draft) is a jump and should leave Bellflower's set.

### Recommended next step

Prototype the four things and the 12 sub-class cards before writing 48 class cards. That is the
smallest build that tests the idea: four starts times three possible second families.

### Open questions for the owner

1. Firefly: do statuses ride the bolt (Jump), or does it only spread damage and Whirligig keeps
   status-copying?
2. Sporeling: is "a full status does something more" what you meant by stacking, given higher
   caps only help Poisoned?
3. Is each family's thing built into the family (full as first pick, smaller as a later pick),
   replacing the Calling?
4. Prototype the four things and sub-class cards first, or the full class sets?

### Owner decisions on section 15 (2026-10-12)

1. **Whirligig keeps copying statuses.** Firefly Jar's thing is spreading damage to other
   nightmares (arcs and bolts), never moving or copying statuses.
2. **Sporeling's thing is stacking quickly:** statuses build up fast. Not higher caps, and not
   "a full status does more".
3. **A family's thing is what its cards do and are built around.** That is the family's identity.
   The thing lives in the cards; the Calling stays a small setup.

| Family | Its thing | Status |
|---|---|---|
| Sporeling | **Quicken**: statuses build up fast | Owner |
| Firefly Jar | **Arc**: damage spreads to other nightmares | Owner |
| Whirligig | **Copy**: statuses are copied between nightmares | Owner |
| Dewdrop | Pool: water on the path, and what happens in it | Council proposal, unconfirmed |
| Bellflower | Ring: on a beat, statuses in reach act again | Council proposal, unconfirmed |

Notes from the earlier code read that still apply:
- Stacking quickly helps every status, unlike a higher cap: Charged reaches its bolt sooner,
  Exposed its 10, Drowsy its full. It must never apply to Rooted (4 stacks gate Smother, Pinned
  and Shatter).
- An arc moves damage only, never arcs again, and one per nightmare per event.
- The built-in "full as first pick, smaller as later pick" proposal above is superseded by
  decision 3: the thing is carried by the family's cards.

---

## 16. The four starters redrafted around their things (2026-10-12; unreviewed, nothing built)

Full card tables, sub-class cards, pairings, bounds and starting numbers are in
`D:\Projects\logs\dream_council\things_sporeling_firefly.md` and
`things_dewdrop_bellflower.md`. The council has not reviewed these redrafts; every number is
unchecked.

| Family | Thing | Calling | Three directions (board, payoff) | Sub-class (lent to another class) |
|---|---|---|---|---|
| Sporeling | Statuses build up fast | **Fresh Spores**: a puff on a nightmare with no Poisoned lands 3 at once | **Thicket**: spore Wardens packed on one stretch; one deep number on elites and bosses. **Meadow**: each spore Warden ringed by Sprouts along a lane; the whole swarm Poisoned at once. **Nursery**: spore Wardens dotted among other kinds; the other family's bolts, sleep, Exposed and Reactions arrive early | Rich Soil (new), Shared Mycelium (changed: any status), Hothouse (new: a neighbour's status starts half full, once per nightmare) |
| Firefly Jar | Damage jumps to other nightmares | **Lantern Light** kept; a "light" is one unbroken stretch of lit path | **Storm**: joined glows; the Jars' bolts fork through the crowd. **Spotlight**: a Jar forward, slow Wardens back; heavy hits spread off the leader. **Lanternway**: many separate lights; damage is handed forward to the next lights | Live Wire and Crossfire (existing, moved from the general pool, within 2 cells of a Firefly Warden), Like to Like (new: a hit also strikes the nearest nightmare with the same status) |
| Dewdrop | Dewdrops turn the path into water, and wet nightmares in it are in trouble | **Puddles**: route within 1.25 cells of a Dewdrop is water; a Dewdrop's hit in water sends a ripple that Soaks everything in it | **Flood**: one long water; pays as nightmares leave. **Crossings**: the route passes the same Dewdrop twice; pays on coming back still Soaked. **Waterside**: other families round small ponds | Heavy Dew (changed), Wake Ripple (changed: the first family's status lands on every Soaked nightmare within 2 cells of a Dewdrop), Skipping Stones (new) |
| Bellflower | Every fourth ring is a Toll, and when the bell tolls it happens again | **Keeping Time**: every 4th ring to hit a nightmare is a Toll that lands again a beat later at half strength; the count is on the nightmare | **Peal**: a row of bells. **Lullaby**: sleep one, choose who wakes it. **Crescendo**: one bell that never falls quiet | Struck Bell (new), Chorus (changed), Knell (new: the 4th ring sets off the first family's status and uses it up) |

**Gone or retired in these drafts:** Lantern Ring, Take Root, Splashback and Ringing do not come
back as Rares. Firefly loses every card that added Charged or a flat percentage. Proposed to
retire: Bitter Sap, Crossed Sparks, Charged Field, Heavy Eyelids.

**Needs new code:** adding stacks without refreshing a status's clock (or quick stacking keeps
statuses alive for ever), and a per-nightmare ring count.

**Designers' main doubts:**
- Sporeling's Thicket and Meadow both pay in Poisoned (deep against wide); Nursery does little
  before a second family at drift 25; three Sporeling cards only change aim.
- Mycelium no longer fits as a sub-class card (it lends Poisoned to Sprouts, not quick stacking),
  though both reviewers had called it the best one.
- Knell on a Sporeling start pays Poisoned out early, which is near the "pop" the owner ruled out.
- Stir the Pond and Wake Ripple put a stack on other nightmares, close to Whirligig's copying.
- Dewdrop's Riptide is the Drown Reaction without Bellflower.
- Guiding Light spreads Exposed from a Firefly form, against "Firefly never copies statuses".
- Wash Away (switches off a resistance) needs a ruling from enemy design.

**Owner, 2026-10-12:** Dewdrop's thing (water on the path) and Bellflower's thing (every fourth
ring happens again) are confirmed. All four starters' things are now owner-approved.

---

## 17. Council pass on the four redrafts (2026-10-12; nothing built)

Reviews: `redraft_roguelite.md`, `redraft_td.md`, `redraft_player.md` in the work folder. Nothing
was run; figures are paper arithmetic or read from code.

### Verdict

| Family | Roguelite | Tower defence | Player | State |
|---|---|---|---|---|
| Firefly Jar | Three real builds | Three boards once "a light" is redefined | Three, all pass the screenshot test | Closest to ready |
| Bellflower | Three boards; Peal's payoff is thin | Peal and Crescendo share a board | Three; Lullaby looks like Spotlight | Close |
| Dewdrop | Flood and Crossings share a board | Same | Two and a half | One direction to separate |
| Sporeling | About one and a half builds | Thicket and Meadow share a board | "Still one build", and the family to skip as a second pick | Needs another redraft |

The player: Firefly, Dewdrop and Bellflower "now read as three different classes (what, where,
when)". Sporeling is "still a colour": building fast is a rate nobody can watch.

### Findings

**Sporeling is the problem family.**
- Thicket and Meadow are one board: a Mycelium Sprout costs 10 Dew against a Sporeling's 25, so
  everyone builds the Sprout ring, and nothing in Thicket needs a clump.
- Its three lent cards are the same card three times, and Mycelium (the card every reviewer
  wanted) was dropped.
- Its three aim Commons (Big Game, Wide Sowing, Hand in Hand) feel like settings, not cards.
- Fresh Spores is switched off by any Sprout's stack upstream.

**Quick stacking has no safe way to exist in the code yet.**
- `EnemyStatuses.apply()` always refreshes the status's clock, and Poisoned always gets a new 5 s
  batch. Any card that lends stacks keeps statuses alive for ever until a "quiet add" exists.
- Even with a quiet add, Charged never ends at +1 stack a second (it loses 1 per 2 s).
- Five Sporeling cards each add about 1 stack a second; together a Jar's Charged goes from 1.5 a
  second to about 6. Cap all added stacks at double the Warden's own.

**Other broken bounds.**
- Card naps can chain: `sleep()` takes the longer time on a nightmare already asleep. Card naps
  must never land on a sleeper.
- Hanging Note grows with the square of the crowd; one per bell.
- Riptide uses the Soaked applier's damage (about 1,800 with a Tidecaller) and gives Dewdrop the
  Drown Reaction without Bellflower.
- The Water Remembers refreshes every Poisoned batch.
- Fireflies in the Grass lights the whole route for 10 Dew a Sprout, erasing two Firefly boards.

**Shared boards.**
- Dewdrop: a dividing wall of Dewdrops is both Flood and Crossings. A "ford" rule (water of 4
  steps or less) would give Crossings its own board.
- Bellflower: the count is per nightmare and nothing pays for a row, so Peal and Crescendo are
  both "every bell round one fold".
- Firefly: "a light is one unbroken stretch of lit path" breaks in a serpentine (one Jar becomes
  3 or 4 lights). Use overlapping glows.

**The second family.**
- Dead pairs as drafted: Sporeling then Bellflower (Knell on Poisoned nets nothing), Dewdrop then
  Sporeling (Soaked already fills itself), Bellflower then Dewdrop.
- Too strong: Firefly then Sporeling (about two-thirds more bolts), Firefly then Dewdrop (Wake
  Ripple spreads Charged into Thunderclaps).
- Pick-screen lines over-promise: Reactions need a grown (tier 2) Warden.
- Seeing any of a second family's 3 cards before drift 50, taken at drift 25: 32% to 56% on paper,
  depending on how family cards are drawn. Proposed rule: a new family's lent cards count three
  times in the draw until one has been offered (about 67% to 85%), and each lent set has one Rare
  so the drift 25 rest can offer it.
- A direction "completes" in 31% to 50% of runs by drift 50 if that means 3 of its 5 cards, but
  only 10% to 15% if it needs its Rare.

**Callings at drift 1.**
- Puddles: the best. Fresh Spores: visible, but only a head start.
- Keeping Time: a lone bell on a straight lane may never Toll a fast nightmare; count 3, not 4.
- Lantern Light: still a glow that does nothing. The player asks for one small forked bolt.

**Facts the drafts got wrong** (13 in the tower-defence file), including: Shared Mycelium is built
at 6 stacks, the base Bellflower counts per bell and nightmare pair, nothing is wasted at the
Poisoned cap.

### The council on the open owner questions

| Question | Roguelite | Tower defence | Player |
|---|---|---|---|
| Thicket and Meadow both pay in Poisoned | Two builds in principle, one as drafted | The shared payoff is fine; the shared board is the fault | Two matchups, one build to look at |
| Mycelium | Keep it with every Sporeling owner | Belongs in both layers | "I'd miss it a lot" |
| Knell setting off Poisoned early | Not a pop, a nothing; make it "ticks once more" | Cut its Poisoned line | Just fun, if it pays a bit extra |
| Stir the Pond and Wake Ripple | Not copying; keep Wake Ripple, replace Stir the Pond | Not copying; needs the quiet add and a 4-step limit | (not asked) |
| Guiding Light spreading Exposed | Keep; the rule binds the new cards only | Make it damage or move it to Whirligig | (not asked) |

### Recommended next steps

1. **Sporeling gets a third pass**, with Mycelium back in both layers, a second board that is
   really different, lent cards that are three different cards, and something to watch.
2. **Firefly, Dewdrop and Bellflower get the fixes above** (definitions, bounds, the shared
   boards), no redesign.
3. **Roguelite Code is asked for two small pieces first:** a quiet add (stacks without a clock
   refresh) and "card naps never land on a sleeper". Nothing in the lent cards is safe without
   them.
4. **Then Balancing**, with the offer-odds question for the second family.

---

## 18. The four starter class sets, current draft (2026-10-12; unreviewed since the fix pass, nothing built)

Sporeling is on its third pass; Firefly Jar, Dewdrop and Bellflower have had the fixes from section 17. Every number is unchecked. Directions, second-family lines, bounds, cards to retire, starting numbers and new code are in the work folder: `final_sporeling.md` and `final_firefly_dewdrop_bellflower.md`.

**Shared rules:** one distance vocabulary (touching, near = 2 cells on both axes, steps along the path, reach); lent cards are never offered to that family's own start (the Sporeling draft assumed the opposite: open); each lent set has one Rare; lent stacks use a quiet add (stacks without a clock refresh; new code); pick lines say "adds 3 Dreams" and promise no Reaction.

### Sporeling: spores pile on fast

#### Calling: Spore Print (replaces Take Root and Fresh Spores)

**A dispelled Poisoned nightmare leaves a mushroom on the path. The next nightmare to step on it
takes a dose: 3 Poisoned at once.**

- **What you see at drift 1:** drift 1 is 6 Shades, 2 s apart (`drift_01.tres`). The first one falls
  and a small mushroom comes up where it fell. The Shade behind walks onto it: the mushroom puffs,
  its badge jumps by 3, and a small cap pops up on its back. Every dose adds a cap (up to 3 drawn),
  so a nightmare visibly grows mushrooms in steps.
- **A Sprout upstream can't switch it off.** It doesn't care how much Poisoned the walker already
  has, and a nightmare Poisoned only by Mycelium Sprouts leaves a mushroom too.
- Nothing is spent or burst: the mushroom is used up, the stacks are not.
- The first-pick card adds one line and no build names: "Your Sporeling cards grow mushrooms and
  hand out doses."
- Rulings:
  - One mushroom per path cell; at most 40 on the map; it lasts 20 s unless stepped on; all wither
    when a rest starts.
  - A dose is an ordinary application (one batch, the normal 5 s) from the Warden whose Poisoned was
    on the fallen nightmare. If that Warden is sold, the mushroom withers.
  - Flyers never step on anything. Bosses and elites take doses like anyone else.

#### The 12 main class cards

| # | Card | Rarity | Direction | Text | What you see |
|---|---|---|---|---|---|
| 1 | **Mushroom Bed** | Common | Bed | A path cell within 1 cell of 2 spore Wardens grows a mushroom every 5 s. | The build ghost lights the hemmed cells; mushrooms come up on them, at rests too |
| 2 | **Open Season** | Uncommon | Bed | After a nightmare steps on a mushroom, each spore Warden's next puff on it is a dose. | It steps, the mushroom puffs, then every Warden round the bed fires one fat puff |
| 3 | **It Grows on You** | Rare | Bed | Each dose a nightmare takes is 1 bigger than its last, up to 6 Poisoned at once. | The cap on its back gets bigger with every dose; the badge jumps 3, 4, 5, 6 |
| 4 | **Kept Ground** | Common | Carpet | A mushroom within 2 cells of a spore Warden grows back 4 s after it is stepped on. | Mushrooms near a spore Warden shrink to a button and come back; the rest are gone for good |
| 5 | **Kicked Up** | Uncommon | Carpet | A nightmare stepping on a mushroom kicks up spores: every nightmare within 1 cell of it takes the dose too. | A green puff off the mushroom over the whole knot of nightmares |
| 6 | **Spore Haze** | Rare | Carpet | A spore Warden with 4 mushrooms within 2 cells puffs in clouds: each puff also lands on nightmares within 1 cell of its target. | A haze hangs over that Warden's stretch; its puffs open into clouds |
| 7 | **Pass It Round** | Common | Garden | Each different kind of Warden within 1 cell of a spore Warden puffs spores with its first hit on a nightmare: a dose. | A thread from the mushroom to each kind beside it; their first shot lands green |
| 8 | **Sickbed** | Uncommon | Garden | Other Wardens within 1 cell of a spore Warden add their status twice on every second hit, to the nightmare it is puffing. Never Rooted. | A spore ring on the puffed nightmare; every second hit on it flashes and its badge jumps 2 |
| 9 | **Everything Grows** | Rare | Garden | A nightmare taking a dose also gains 1 of each other status a Warden put on it in the last 2 s. Never Rooted. | The dose's puff shows each other status's colour; those badges tick up with it |
| 10 | **Twin Caps** | Uncommon | Bed + Carpet | Each mushroom has two caps: it gives a dose to two different nightmares before it is used up. | Mushrooms drawn as a pair; one cap goes at a time |
| 11 | **Side by Side** | Uncommon | Bed + Garden | A path cell within 1 cell of a spore Warden and another family's Warden grows a mushroom every 5 s. | Mushrooms on the path between a spore Warden and its partner |
| 12 | **Leaf Litter** | Uncommon | Carpet + Garden | A nightmare dispelled within 2 cells of a spore Warden leaves a mushroom, Poisoned or not. | Mushrooms where a Jar's bolt or a bell did the work |

- **Each direction has 5 cards.** Bed 1, 2, 3, 10, 11. Carpet 4, 5, 6, 10, 12. Garden 7, 8, 9, 11, 12.
- **Every card works with only the Calling**, because the Calling supplies mushrooms and doses. No
  Rare is the build: each direction pays on its Common and Uncommon.
  - Bed without its Rare: the bed (1), every Warden round it doses again (2), each mushroom serves
    two (10).
  - Carpet without its Rare: stretches that grow back (4), the pack shares each dose (5), every
    kill near a spore Warden seeds one (12).
  - Garden without its Rare: a dose per kind standing by (7), the puffed nightmare takes the
    partner's status faster (8), a bed between partners (11).
- **No aim cards.** Big Game, Wide Sowing and Hand in Hand are gone and not replaced.
- **Rulings the text leaves out.**
  - Mushroom Bed, Side by Side: the cell regrows 5 s after it is emptied. A cell that qualifies for
    both still grows one mushroom.
  - Open Season: once per Warden per nightmare every 2 s. Mycelium Sprouts are not spore Wardens.
  - It Grows on You: counted per nightmare, for the whole run of its life. Kicked Up gives each
    receiver a dose of its own size.
  - Kicked Up: the shared dose is fresh Poisoned from the mushroom's Warden. It does not read or
    move what the stepping nightmare carries, and it does not set off Open Season for the others.
  - Spore Haze: stacks and puff damage both land; it is not Mistveil's fog.
  - Pass It Round: one dose per kind per nightmare, however many of that kind stand there. A kind
    is a form (Sprout, Firefly Jar, Stormcap…). Spore forms don't count. Selling and replanting
    resets nothing.
  - Sickbed: "puffing" = that spore Warden's puff landed on it in the last 2 s. The extra stack
    rides the other Warden's own hit; nothing is added between its hits.
  - Everything Grows: 1 stack, by the quiet add, only to a status whose own Warden hit this
    nightmare in the last 2 s, and inside the budget in section 7.
- **Family forms.** Fairy Ring and Elf Circle plant rings that hit and add 2 or 3 Poisoned; those
  are attacks, not mushrooms, and no class card counts them. See doubt 1.

#### The 3 sub-class cards (lent when Sporeling is picked later)

Offered to **every** Sporeling owner, the Sporeling start included. Plain words only: a later family
brings no Calling, so there are no mushrooms and no doses here.

| Card | Rarity | Text | What you see |
|---|---|---|---|
| **Mycelium** (existing, unchanged in effect) | Uncommon | Sprouts within 1 cell of a spore Warden puff spores too: each hit adds 1 Poisoned. | Sprouts wearing little caps, shooting green |
| **Hothouse** | Uncommon | Statuses from another family's Wardens within 1 cell of a spore Warden start a third full on each nightmare. Never Rooted. | The badge appears already part filled, with a sprout on it |
| **Overnight** (the "ooh") | Rare | A spore Warden's puff lands 3 Poisoned at once on a nightmare carrying a status from another family's Warden. | Puffs on your Charged, Soaked or Drowsy nightmares land fat; caps pop up on them |

- **Three different cards:** what your walls do; a head start for your own status; my status
  piling onto whatever yours has touched.
- Mycelium: "within 1 cell" is the built "touching" set. It adds no Warden across a half-cell lane.
- Hothouse: once per status per nightmare, ever. A third of the need, rounded up (Soaked 3,
  Exposed 4, Charged 7, Drowsy 7). Bosses nothing. It is the Warden's own first application with
  more stacks, so it has that application's clock and nothing is lengthened.
- Overnight: Poisoned and Rooted don't count as the carried status. Forms that already add 2 or 3
  a puff add 2 more. One batch, the normal 5 s. The cap is unchanged.
- **Overnight is Rare**, so the drift 25 rest can offer it.
- The pick line names the status and promises only what a base Warden can do: "Sporeling: Sprouts
  beside a mushroom poison, and your [Charged] starts a third full beside one. Adds 3 cards."


### Firefly Jar: damage spreads to other nightmares

#### The Calling: Lantern Light

> Nightmares in a Firefly Warden's glow are Lit and can't hide. The hit that dispels one forks to
> the nearest Lit nightmare for half.

- **What you see in the first drift with a Jar:** the glow on the path, and a small fork leaping
  off every nightmare that falls in it.
- **Why the fork hangs on a dispel, not on a bolt:** Charged fills at 20 and one Jar gives a Shade
  about 6 in a pass, so there are no bolts in the early drifts. A fork on bolts would still be a
  glow that does nothing. Dispels happen from the first drift.
- **Small:** half of one hit, once per dispel. A nightmare dispelled by a fork gives no fork.
- **Cut:** "your Firefly cards work on them" / "send lightning between Lit nightmares".
- "Can't hide" is the existing fog rule (Lantern Glow's).

#### The 12 main class cards

| # | Card | Rarity | Direction | Text | What you see |
|---|---|---|---|---|---|
| 1 | **Where Lights Meet** | Common | Storm | Path lit by two Firefly Wardens glows gold. The hit that dispels a nightmare there forks to the 3 nearest Lit nightmares. | Gold path; three forks off each nightmare that falls on it |
| 2 | **Chain of Lanterns** | Uncommon | Storm | A bolt on a Lit nightmare also forks to the 2 nearest Lit nightmares for half. | Lightning forking through the glow |
| 3 | **Last Spark** | Rare | Storm | A Charged nightmare that is dispelled, or walks out of the light, throws its charge as a bolt at the nearest Lit nightmare. | A spark leaping off each nightmare that falls or steps out |
| 4 | **Hammerfall** | Common | Spotlight | A slow Warden's hit on a Lit nightmare forks to the nearest other Lit nightmare for half. | A heavy flash, then one fork |
| 5 | **Ground Strike** | Uncommon | Spotlight | A slow Warden's hit on the only Lit nightmare in its light strikes it a second time for half. | The fork curling back into its own target |
| 6 | **Spotlight** | Rare | Spotlight | Slow Wardens' hits on the Lit nightmare nearest the Heartwood also fork to every other nightmare in that light, for a quarter. | A beam on the leader; each heavy hit flashes down the light |
| 7 | **Fireflies in the Grass** (existing, changed) | Common | Lanternway | For each Firefly Warden you own, one Sprout of your choice glows: a small light of its own. | A lantern button on Sprouts; small glows along the path |
| 8 | **Signal Fires** | Uncommon | Lanternway | The hit that dispels a nightmare in one light also forks, for half, to the front nightmare in the next light. | The next light flashes; a fork lands on its leader |
| 9 | **Lanternway** | Rare | Lanternway | A bolt in any light also forks to the front nightmare in each of the next 3 lights, for half. | Lightning running down the string of lights |
| 10 | **Nothing Wasted** | Uncommon | Storm + Spotlight | When a hit or bolt dispels a Lit nightmare, the damage left over forks to the nearest Lit nightmare. | The rest of a big hit leaping to the next nightmare |
| 11 | **Ambush** | Uncommon | Spotlight + Lanternway | The first hit on a nightmare in each light it enters also forks to the nearest other Lit nightmare, for half. | A flash and a fork as it steps into each glow |
| 12 | **Waiting Spark** | Uncommon | Storm + Lanternway | A fork with no Lit nightmare to reach waits in its light for 3 s and strikes the next nightmare to enter. | A spark hanging on the path until something walks into it |

**Each direction has 5:** Storm 1, 2, 3, 10, 12. Spotlight 4, 5, 6, 10, 11. Lanternway 7, 8, 9,
11, 12.

**What replaced the dead cards.**

| Dead card | Why | Now |
|---|---|---|
| Crossed Beams | One fork inside Chain of Lanterns' three | Merged away. Where Lights Meet gives gold path its own job (dispels, not bolts), so it works before bolts exist |
| Parting Spark | Last Spark with a second trigger | Merged into Last Spark |
| Flashpoint | The family has 0 to 5% crit | Replaced by Nothing Wasted |
| Spotters | +1.5 cells of reach | Cut. Hammerfall is the Spotlight Common |

**Rules behind the short texts.**
- **One fork per nightmare per event,** whatever cards are owned; the largest wins. An event forks
  to at most 6 nightmares in all.
- **Where Lights Meet** makes the Calling's fork three forks; it is not added on top. With Nothing
  Wasted, the nearest nightmare takes the larger of the two.
- **Last Spark:** "its charge" is the built share of a full bolt (`stored_bolt_damage`). On leaving,
  its Charged ends. This bolt is a fork: Chain of Lanterns and Lanternway add nothing to it.
- **Ground Strike** is the one card that is not a spread. It is there because the roguelite review
  asked for a lone-boss clause. Bosses take half of it like any fork: a quarter of the hit.
  With Hammerfall owned, a hit either forks or strikes again, never both.
- **Spotlight:** at most 6 others. The nearest one takes Hammerfall's half, not both.
- **Fireflies in the Grass:** the player switches Sprouts on from the Warden panel (a button, so it
  works on touch). A Sprout light is the path touching that Sprout, about 3 steps. It is always its
  own light: it never joins a Jar's light, never makes gold path, and where it overlaps a Jar's
  glow the Jar's light wins. It counts as a light for every card. A Sprout is not a Firefly Warden
  and not a slow Warden. With 4 Jars there are at most 8 lights.
- **Signal Fires:** once for each light each second. **Lanternway:** each of the 3 must be the
  "next light" of the one before (the 8-step rule).
- **Nothing Wasted:** never more than the hit or bolt itself.
- **Ambush:** once for each nightmare and light.
- **Waiting Spark:** one waiting spark per light; a bigger one replaces a smaller. With Ground
  Strike owned, a slow Warden's lone hit strikes again and nothing waits.

**Family forms not duplicated:** Stormcap chains its own hit, Sparkler adds Charged, Midsummer's
beam carries on, Jarlink is a standing line. No card forks a Jar's ordinary hit; cards fork
dispels, bolts and slow Wardens' hits.

#### The 3 lent cards (Firefly Jar picked second)

No Lit and no lights: these work near the Jar.

| Card | Rarity | Text | Change |
|---|---|---|---|
| **Live Wire** | Common | A hit from your [Sporelings] near a Firefly Warden forks to one more nightmare for a third. Splashes and pulses fork once. | Existing (general pool, "bolts jump to a second nightmare"). Now the plain lend |
| **Crossfire** | Uncommon | A Firefly Warden and your [Sporeling] near it hitting one nightmare within 1 s strike the 2 behind it for half the weaker hit. | Existing (general pool). Needs a Firefly Warden; 2 targets at half (was 1 at 40%). Its 3 s wait per nightmare and "stored before defences" stay |
| **Like to Like** | Rare | Damage your [Sporelings] near a Firefly Warden deal to a [Poisoned] nightmare forks to the nearest other [Poisoned] nightmare, for a third. | New. Bounded (below) |

**Like to Like, bounded.**
- A third, not half. The status must be the one the hitting Warden applies.
- The receiver must be near the nightmare that was hit (2 cells), and carry that status.
- **Hits fork per hit. Status damage (Poisoned ticks) forks once a second, and only while the
  ticking nightmare is near a Firefly Warden.** Without this, the card does nothing on a Sporeling
  start, whose damage is ticks (the roguelite review); with it unbounded it is a flat boost
  everywhere (the tower-defence review). The two reviews disagree here; this is the middle.
- Bolts and Reactions never fork from it. One fork per hit across Live Wire and Like to Like.
- The fork is drawn in the status's colour. The status never moves.


### Dewdrop: water on the path

#### The Calling: Puddles

> The path beside your Dewdrops is water. A Dewdrop's hit there ripples: every nightmare in that
> water is Soaked. Soaked nightmares take more from Dewdrops.

- **What you see in the first drift with a Dewdrop:** blue water on the path and a ripple running
  along it with every splash.
- **The last sentence is new** and is the game's existing rule (water hits +20% on a Soaked
  nightmare, at most +40%). It answers "why is wet good" for a Dewdrop start.
- **One ruling to accept:** the ripple is a normal Soaked application, so Soaked does not run out
  while Dewdrops keep hitting in that water. This is allowed **for Soaked only**: it is the
  family's own status from its own hit. No card pauses or refreshes any other status.

#### The 12 main class cards

| # | Card | Rarity | Direction | Text | What you see |
|---|---|---|---|---|---|
| 1 | **Levee** | Common | Flood | A row of up to 2 Thornwalls between two Dewdrops carries the water along the path beside them. | Water running on past the walls; the length number going up |
| 2 | **Backwash** | Uncommon | Flood | A Soaked nightmare leaving water is splashed at once by each Dewdrop touching that water. Up to 4. | A volley of splashes chasing it out |
| 3 | **Breakwater** | Rare | Flood | A fully Soaked nightmare leaving water 10 or more steps long is hit by a big wave, then dries off. | A wave breaking at the water's end; the water looks deeper at 10 |
| 4 | **Second Ford** | Common | Crossings | Water 4 steps or shorter is a ford. A nightmare wading its second ford at one Dewdrop is splashed by it at once. | The drop over its head bursting as it steps back in |
| 5 | **Both Banks** | Uncommon | Crossings | A Dewdrop with two fords splashes both: each splash also lands on the front nightmare in its other ford, at half. | Every shot matched by a smaller one into the far lane |
| 6 | **Riptide** | Rare | Crossings | A fully Soaked nightmare wading its second ford at one Dewdrop is pulled under for 2 s, then dries off. Once each. | The ford closes over it |
| 7 | **Caught Wading** | Common | Waterside | The first time a ripple Soaks a nightmare in a water, each other Warden touching that water attacks it at once. Up to 3. | The whole bank firing as it gets wet |
| 8 | **Wet Footprints** | Uncommon | Waterside | A Soaked nightmare leaving water carries a puddle under it for 3 s. It still counts as standing in that water. | A small puddle walking out with it |
| 9 | **Wash Away** (flagged) | Rare | Waterside | A fully Soaked nightmare in water loses half its resistances to the Wardens touching that water. Not bosses. | Its shield icons crack; fewer grey "resisted" puffs |
| 10 | **Swell** | Uncommon | Flood + Crossings | A Dewdrop's splash that lands in water spreads through that water, at half strength outside its own circle. | The whole water heaving on each splash |
| 11 | **Across the Water** | Uncommon | Flood + Waterside | A Warden touching water can also hit Soaked nightmares further along that water, up to 3 steps. | Shots skipping along the water past the range ring |
| 12 | **The Water Remembers** | Uncommon | Crossings + Waterside | A nightmare wading its second ford at one Dewdrop gets back half the statuses that wore off since the first. | Its badges part-refilling with a splash |

**Each direction has 5:** Flood 1, 2, 3, 10, 11. Crossings 4, 5, 6, 10, 12. Waterside 7, 8, 9,
11, 12.

**What changed, and why.**

| Was | Problem | Now |
|---|---|---|
| Second Soaking, Riptide, Welcome Back, The Water Remembers | "One sentence four times"; four wordings of "comes back to the same water" | Three cards with **one phrase** ("its second ford at one Dewdrop") and three different payoffs: a splash, a pull-under, statuses back. Welcome Back is merged into Second Ford |
| Second Soaking | Full Soaked is already nearly free; dead without Riptide | Replaced by Second Ford: pays on return by itself, and does not need Soaked |
| Seep | Grew the same shared board as Levee | Cut. Both Banks does its job for fords only |
| Welcome Back (Flood + Crossings) | Kept the two boards together | Its volley now pays on **leaving** (Backwash), which is Flood's moment |
| Bankside | A reach card; "never take" | Replaced by Caught Wading |
| Stir the Pond | Wake Ripple twice | Replaced by Wet Footprints |
| Riptide | Was the Drown Reaction without Bellflower, at the Soaked applier's full damage (about 1,800 with a Tidecaller) | A pull-under, not a Reaction (rules below) |

**Rules behind the short texts.**
- **Levee:** a chain of up to 2 Thornwalls, each touching the next, with a Dewdrop touching each
  end.
- **Backwash:** free splashes that do not reset the Dewdrops' own timing. More Dewdrops on one
  water means more splashes, so it grows with the Flood board without a length number. A ford gives
  one.
- **Breakwater:** the wave is 3 s of damage from the strongest Dewdrop-family Warden touching that
  water. Once for each nightmare and water. No push and no freeze.
- **Second Ford:** a full splash, with its ripple. Each later ford at that Dewdrop pays too.
- **Both Banks:** only for a Dewdrop with two or more fords. The second landing is a splash at
  half, with its normal Soaked.
- **Riptide:** calls the pull-under effect directly. It is **not** the Drown Reaction: no chain
  link, no Echo Hollow repeat, no Still Pool, the Reaction's "drowned" mark untouched, Deep Water
  does not read it. Damage is 3 times a **base** Dewdrop's hit at that Warden's rank, never the
  form's hit. Bosses: nothing.
- **Caught Wading:** free attacks that do not reset timing; once for each nightmare and water.
  Sprouts count, so it works before a second family.
- **Wet Footprints:** the puddle counts for ripples, Caught Wading, Wash Away and Across the Water
  only. It is never a ford, never adds length, and "leaving water" still happens at the real edge.
- **Wash Away:** family resistance ×0.5 becomes ×0.75, and status-length resistance moves half-way
  to normal. Immunities, the blight coat and shape multipliers stay. **Needs a ruling from enemy
  design.** If refused, the replacement Rare is **High Water**: "A fully Soaked nightmare in water
  takes the first hit from each other Warden touching that water twice."
- **Swell:** at most 4 steps each way; outside its own circle it adds no Soaked. It is the Flood +
  Crossings bridge because it helps a long water and a ford alike without rewarding one board for
  being both.
- **Across the Water:** path in that water within 3 steps of a point inside the Warden's reach,
  and never more than 5 cells from the Warden. Pulses are left out.
- **The Water Remembers:** half of the stacks lost since the first ford, by quiet add. A status
  that had ended comes back with 2 s on it. **Poisoned comes back as one batch that is not a native
  application, and no existing batch is refreshed.** Never Rooted. It stops one short of a bolt or
  a Reaction's need.

**Not repeats of the forms:** no card makes ground that Soaks walkers by itself, freezes, pushes
back, or pays Dew.

#### The 3 lent cards (Dewdrop picked second)

No water: there is no Calling. Each card is tied to "near a Dewdrop". While one is owned, a faint
wet square is drawn round each Dewdrop.

| Card | Rarity | Text | Change |
|---|---|---|---|
| **Wake Ripple** | Uncommon | When your [Sporeling]'s [Poisoned] lands on a Soaked nightmare near a Dewdrop, other Soaked nightmares within 4 steps get 1 too. Once a second. | Existing, changed. Kept, with the 4-step limit. **Barred from Charged** (line below) |
| **Skipping Stones** | Uncommon | Your [Sporelings] near a Dewdrop can hit Soaked nightmares anywhere in that Dewdrop's reach, up to 3 cells from it. | New. The 3-cell cap is for the 4-cell forms. Pulses count |
| **Soaked Through** | Rare | When a nightmare near a Dewdrop becomes fully Soaked, each of your [Sporelings] near that Dewdrop attacks it at once. Up to 4. | New. The set's Rare, and what "wet" is for on a second pick |

- **Wake Ripple by first family:**

| First family | The card reads | Limits |
|---|---|---|
| Sporeling | As above, with Poisoned | Quiet add, 1 stack; a rippled stack never sets off Fresh Spores and never counts as a second Warden |
| Bellflower | As above, with Drowsy | Quiet add; never takes Drowsy past half its limit |
| Firefly Jar | "When your Jar's bolt strikes a Soaked nightmare near a Dewdrop, other nightmares within 4 steps get 2 Soaked. Once a second." | It spreads **Soaked**, the Dewdrop's own status, credited to that Dewdrop. No Charged is ever added to another nightmare |

- "Once a second" is per Dewdrop. Never Rooted.
- **Soaked Through:** once for each nightmare. Free attacks that do not reset timing. A bell's free
  ring obeys the half-second rule (section 3).
- **Heavy Dew is no longer a lent card.** It stays where it is as built, on the Commons rework
  list; the player would never take the aim version.


### Bellflower: every fourth ring happens again

#### The Calling: Keeping Time

> Every 4th ring on a nightmare is a Toll: it lands again a beat later, at half. Its first Toll
> comes on ring 2.

- **What you see in the first drift with a bell:** on a nightmare's second ring, a deep note and a
  second, fainter ring on that nightmare. One loud Toll; the four pips over the nightmare are small
  and secondary.
- **Why "ring 2":** a lone bell on a straight lane gives a Shade 2 or 3 rings, so a plain count of
  4 never Tolled it and a count of 3 only sometimes did. The first Toll on ring 2 always lands;
  after that the rhythm is every 4th, as the owner's sentence says.
- **Small:** one half-strength ring per nightmare early, then about one eighth more bell damage.
- **Cut:** "Your Bellflower Wardens are bells."

#### The 12 main class cards

| # | Card | Rarity | Direction | Text | What you see |
|---|---|---|---|---|---|
| 1 | **Sound Carries** | Common | Peal | A bell's ring carries along the path to the next bell, up to 4 steps away, at half strength. | A band of sound sweeping from bell to bell |
| 2 | **Rounds** | Uncommon | Peal | A bell's Toll is heard at the next bell down the path, up to 4 steps on: nightmares in its reach get 2 Drowsy. | The next bell answers; a pink wave over its reach |
| 3 | **Call and Answer** | Rare | Peal | After a Toll, that nightmare's first ring from the next bell down the path, up to 4 steps on, is a Toll too. | Toll after Toll rolling down the row with it |
| 4 | **Nod Off** | Common | Lullaby | A Toll puts a Drowsy nightmare to sleep for 1 s and uses up half its Drowsy. One sleeper for each bell. | It stops and slumps under a sleep mark |
| 5 | **Tiptoe** | Uncommon | Lullaby | Nightmares touching a sleeper tiptoe past it at half speed until it wakes. | The line bunching up and creeping round the sleeper |
| 6 | **Rude Awakening** | Rare | Lullaby | A nightmare's first Toll puts it to sleep for 1 s. When a Toll's sleep ends, the next hit on that nightmare deals double. | It jolts upright; the next hit bursts with light |
| 7 | **Full Voice** | Common | Crescendo | Each Toll a bell lands widens its ring by half a cell, up to 4 cells in all. It shrinks back when its reach is empty. | The bell's ring growing; it snaps back after a gap |
| 8 | **Overture** | Uncommon | Crescendo | When a drift's first nightmare reaches a bell, its every ring is a Toll until its reach is empty. Up to 8 s. | The bell flaring as the first nightmare arrives, for as long as it stays busy |
| 9 | **Rising Song** | Rare | Crescendo | The longer a nightmare stays by one bell, the sooner it Tolls: every 4th ring, then every 3rd. | The pips over it dropping from four to three |
| 10 | **Sleep No More** | Uncommon | Peal + Lullaby | A Toll on a sleeping nightmare wakes it: that Toll lands in full on it and on nightmares touching it. | The sleeper jolts and a full ring bursts from it |
| 11 | **Hanging Note** | Uncommon | Peal + Crescendo | A bell's Toll leaves its ring hanging on the path for 2 s. Nightmares that walk into it are struck. One for each bell. | A ring left on the ground, fading |
| 12 | **Sung to Sleep** | Uncommon | Lullaby + Crescendo | A nightmare's 6th ring from one bell sings it to sleep for 1 s. | A nightmare that lingers by the bell slumps |

**Each direction has 5:** Peal 1, 2, 3, 10, 11. Lullaby 4, 5, 6, 10, 12. Crescendo 7, 8, 9, 11, 12.

**What changed, and why.**

| Was | Problem | Now |
|---|---|---|
| Rounds ("first ring from each bell counts as two") | Worked in a cluster; more half-strength rings | Same name, new effect: **Peal's Toll effect that is not damage.** Drowsy arrives ahead of the pack, so later bells hold it longer |
| Call and Answer | Worked at a gap of 0 | Needs a gap of 1 to 4 steps |
| Nod Off | Spent up to 40% slow for 3 s on a 1 s stop | Uses up half its Drowsy |
| Tiptoe | 30% within 1 cell; "never take" | Half speed, to make the jam the thing you see |
| Rude Awakening | The waking hit must be 10% of max health: never on elites, overkill on Shades | The next hit after the sleep ends, whatever its size |
| Overture | Did nothing when no nightmare was in reach at the drift's start; rewarded every board alike | Starts when the first nightmare arrives, and lasts only while the bell stays busy |
| Rising Song | 4, 3, 2: the auto-pick, and the whole of Crescendo | One step only (4 then 3), in the player's wording |
| Wake-Up Call | "Wake" also meant Wake Ripple | Renamed Sleep No More; same effect |
| Hanging Note | Every Toll on every nightmare left a ring: square growth | One per bell; struck once; not a ring for the count |
| With a Start | Dead for Crescendo without Lullaby cards; "never take" | Replaced by Sung to Sleep, which makes a sleeper from a long stay |

**Rules behind the short texts.**
- **Sound Carries:** gap of 1 to 4 steps. The carried ring is damage in the gap only; it is not a
  ring for the count, and each nightmare takes it once per pulse.
- **Rounds:** the Drowsy is the next bell's own application in its own reach. Once a second for
  each bell.
- **Call and Answer:** toward the Heartwood only, so a loop of bells cannot feed itself. The
  once-a-second Toll limit applies.
- **Nod Off:** the Drowsy it leaves keeps its clock.
- **Tiptoe:** it is a slow, so the game's floors hold (normal 0.5, elites 0.6, bosses 0.7).
- **Rude Awakening:** the first-Toll sleep is once for each nightmare and obeys the nap rules. The
  double hit must land within 2 s of the sleep ending; a hit that wakes it early counts. With
  Pinned, only the larger multiplier applies.
- **Full Voice:** 4 cells in all, whatever else is owned (Hush included).
- **Overture:** per bell, once a drift.
- **Rising Song:** back to every 4th when the nightmare leaves that bell's reach.
- **Sleep No More:** it wins over Nod Off on the same Toll. One such burst per nightmare per Toll.
- **Hanging Note:** it is the Toll's second landing, left on the ground at half strength, about 1
  cell wide. It does not keep a reach "busy".
- **Sung to Sleep:** counted for each bell and nightmare pair (the count the base form already
  keeps). Obeys the nap rules.

**Three ways into Lullaby:** Nod Off, Rude Awakening and Sung to Sleep each make sleepers alone.

**Not repeats of the forms:** no card adds Charged, sets off bolts, Catches, echoes Reactions,
Silences, or sleeps a whole ring.

#### The 3 lent cards (Bellflower picked second)

There is no Calling, so each card carries "every 4th ring" itself, with the same count rules (one
count on the nightmare, the half-second rule, the first on ring 2). A ring only lands in a bell's
reach, and "your [Sporelings]" must be near the bell.

| Card | Rarity | Text | Change |
|---|---|---|---|
| **Struck Bell** | Common | Every 4th ring on a nightmare is a Toll: it lands again at half. Hits from your [Sporelings] near a bell count as rings. | New. Was "more rings at half" ("never take", and those rings did not count). Now it lends the Toll itself and lets the first family's hits drive the count |
| **Chorus** | Uncommon | Every 4th ring on a nightmare, the bell repeats your [Sporeling]'s last hit on it, at half. | Existing, changed (was "bells pulse together, +30%"). The player's wording |
| **Knell** | Rare | Every 4th ring on a [Poisoned] nightmare sets off its [Poisoned]. (One line per status, below.) | New. The set's Rare |

**Knell, by first family.**

| First family | The card reads | What is used up |
|---|---|---|
| Sporeling | "Every 4th ring on a Poisoned nightmare makes its Poisoned tick once more, at once." | Nothing. **Stacks and every batch's clock are untouched.** It is one extra tick, not a burst, so it is not the "pop" the owner ruled out |
| Firefly Jar | "Every 4th ring on a Charged nightmare sets its Charged off as a bolt, for the charge it has." | All its Charged. The bolt is the built share (`stored_bolt_damage`) |
| Dewdrop | "Every 4th ring on a Soaked nightmare bursts half its Soaked: up to 2 Dewdrops near it splash it at once." | Half its Soaked. It never dries, so the water cards stay on |

- Rooted and Exposed are never set off.
- **Struck Bell:** a counted hit must land on a nightmare inside that bell's reach; once a second
  for each nightmare; the half-second rule applies. A nightmare still Tolls at most once every 2 s.
- **Chorus:** half, and never more than twice the bell's own ring. The hit is stored before
  defences (as Fifth Beat's is) and the repeat is not a hit. Its status stack comes with it as a
  quiet add of 1. Each hit is repeated once.
- **Knell (Dewdrop):** once every 2 s for each Dewdrop; the free splash does not reset its timing.
- **Knell (Firefly):** a bolt set off by a bell forks at most once, and never to a nightmare the
  same ring also set off.


---

## 19. Council pass on section 18, and "can other families use these cards?" (2026-10-12; nothing built)

Reviews: `final_roguelite.md`, `final_td.md`, `final_player.md` in the work folder. Nothing was
run; figures are paper arithmetic or read from code.

### Verdict

- **All four now read as classes** (player: "first draft where all four read as classes";
  Sporeling "went from worst to possibly the most fun").
- **Not ready for Balancing as a set.** Ready for a **Firefly Jar prototype** after two small
  changes (tower defence): it is the cheapest to build, one fork function and a distance check,
  with no status code.

### Can other families take advantage of the class cards? (owner question)

A = the family's own Wardens only. B = any Warden in the right place. C = rewards owning another
family. (Roguelite count of the 12 class cards.)

| Family | A | B | C | Build for a multi-family player | State |
|---|---|---|---|---|---|
| Firefly Jar | 4 | 8 | 0 | Spotlight | The most open; any Warden's hit forks on a Lit nightmare |
| Dewdrop | 7 | 4 | 1 | Waterside | The best shape |
| Sporeling | 7 | 2 | 3 | Garden | Right shape, but Garden's cards do nothing before the second family at drift 25 |
| Bellflower | 11 | 1 | 0 | none | Closed: every card counts only bell rings |

- Each family is really two builds for its own Wardens plus one "company" build. The council
  would accept that and say so.
- **Bellflower needs opening:** at least one class card that counts other Wardens' hits as rings.
- **The text hides it.** The player could not tell on most cards whether a second family
  benefits. "Each other Warden touching that water" and "another family's Warden" are clear; "a
  Warden", "a bolt" and "the hit" are not. Every card should say who it works for.
- **Wording that silently leaves attack kinds out** (read from code):
  - "The hit that dispels" excludes Poisoned ticks and clouds, so a Sporeling added to a Firefly
    start gets little.
  - "Slow Warden" can't be read from data (clouds, arcs and sparks share one attack kind); it
    needs a hand-set flag and a tag on the Warden.
  - Across the Water leaves out pulses, which are three of the nine base Wardens.
  - "Attacks it at once" is undefined for pulses, chains, clouds, traps and beams.
- **Cards that reward another family should not be offered before a second family is owned.**

### Lent cards: one rule

The drafts disagreed on whether a family's own start can draw its lent cards. Roguelite and
player: offer a lent card whenever its text can do something on the board, so anyone owning that
family plus another gets them, whichever came first, and Mycelium goes to every Sporeling owner
from drift 1. Tower defence: no, except Mycelium. **Owner call.**

### Bounds still open

- **Free attacks are the biggest hole** (Backwash, Second Ford, Caught Wading, Soaked Through,
  Knell on Soaked). A heavy Warden on a bank gets a free full hit per wet nightmare; a Tidecaller's
  free pulse per leaver grows with the square of the crowd. One rule: that nightmare only, at most
  one second of the Warden's damage, one per Warden a second.
- **Overnight** is about three times the Poisoned from one Sporeling; cap it at once a second per
  Warden and nightmare.
- **Knell** on Poisoned adds up to half again the Poisoned damage and spends nothing.
- **Kicked Up** needs a cap of 4 receivers.
- **Riptide** is weak, not strong: read from code it is a slow, pays 1.5 times a base hit, then
  dries the nightmare.
- **Plain boosters that slipped in:** Ground Strike, Knell on Poisoned and Soaked, Like to Like on
  a Dewdrop start.

### Boards and definitions

- **Ford is off by one:** two touching Dewdrops make exactly 4 steps. Use "water touching one
  Dewdrop, 3 steps or shorter".
- **"Next light" and "next bell" break in a winding maze;** measure from the nightmare.
- **Mushrooms go on route points** (the 1.25-cell path rule), or a half-cell nudge moves them.
- **Spotlight has no slow Warden at tier 1,** so its Common is dead until a branch is grown.
- **Sporeling's two Rares are on the wrong boards** (It Grows on You does little on a Bed; Spore
  Haze is off when the swarm arrives on a Carpet); swap or rework.
- **Shared boards left:** Dewdrop's Crossings and Waterside (a pond is a ford); Bellflower's
  Lullaby and Crescendo (one bell at a fold).

### Cards

- **Commons:** ten of twelve "exciting" to the player, up from seven.
- **Auto-picks:** Twin Caps, Mycelium, Nothing Wasted, Where Lights Meet, Caught Wading, Swell,
  Nod Off.
- **Dead or never taken:** Rising Song, Wet Footprints, Ground Strike, Sound Carries, Sickbed,
  Hothouse, Rounds, Sung to Sleep, Live Wire, Skipping Stones.
- **Second family:** Bellflower's lent set is the best, Sporeling's is now good, Firefly's is
  fine, Dewdrop's is the one the player would skip. In every set the "ooh" card is the Rare, so
  it is the one least likely to be seen.
- **Words:** dose, fork and Toll are fine. "Ford" and "wading its second ford at one Dewdrop" are
  the worst in the draft.

### Rulings the council gave

| Question | Roguelite | Tower defence | Player |
|---|---|---|---|
| Mushrooms as a third path idea | Fine | Accept, as things that are used up, never zones | Fine if countable and used up |
| Toll count | Keep 4, first on ring 2 | Same, shown as "starts with 2 of 4 pips" | The sentence needs a second read |
| Wash Away | Cut it | Allow at half, family resistance only | Clear, and wanted |

### Recommended next steps

1. **Prototype Firefly Jar first.** Before that: a hand-set "slow Warden" flag, and "the hit that
   dispels" widened to any dispel.
2. **Roguelite Code builds two shared pieces:** a quiet add (stacks without a clock refresh) and a
   card nap that never lands on a sleeper. Neither exists in `enemy_statuses.gd` today.
3. **One more edit of the other three**, no redesign: the free-attack rule, the caps, the ford
   and route definitions, one Bellflower card that counts other Wardens, "who it works for" on
   every card, and the dead cards replaced.
4. **Then Balancing.**

### Owner ruling on offers (2026-10-12)

*"Don't want given cards, want cards that players can risk to get if they get the build."*

Read as: nothing hands a player a card or raises its odds because of what they own. Cards sit in
the random pool, and a player may take one early as a bet that the build arrives.

What this settles:
- **No boosted odds for a new family's lent cards** (the "count three times" proposal is dropped),
  no lent card shown on the family pick, no card promised at the next rest.
- **Mycelium is not handed to every Sporeling owner.** It is a card in the pool like any other.
- **Cards that reward another family ARE offered before the second family is owned.** That is the
  risk: take Pass It Round at drift 10 and bet on what the drift 25 pick brings. This reverses the
  council's "don't offer them early".
- **A family's own start can be offered its lent cards**, for the same reason: they do nothing
  until another family is owned, and taking one is a bet.
- **Each such card must say plainly what it needs**, so the risk is a choice and not a trap.
- A second family may show none of its cards in a run. That is accepted.

---

## 20. The four starter class sets, edit 4 (2026-10-12; replaces section 18; unreviewed, nothing built)

This edit applies the owner ruling on offers and the council fixes from section 19. Every number is unchecked. Second-family lines, bounds, cards to retire, starting numbers, new code, change logs and doubts are in the work folder: `v4_sporeling_firefly.md` and `v4_dewdrop_bellflower.md`.

**Shared rules:**
- **Offers:** nothing is handed out or weighted. Cards that need another family are offered early as a bet, and say what they need. A family's 3 lent cards are in the pool for anyone who owns it, its own start included.
- **Safe or bet:** every card is marked. A bet pays more than a safe card when it lands.
- **Who it works for** is in every card text.
- **Distances:** touching, near (2 cells on both axes), steps (along the path), reach.
- **Free hits:** that nightmare only, at most one second of the Warden's damage, one per Warden a second.
- **New shared code:** a quiet add (stacks without a clock refresh) and one nap rule (fixed 1 s, never on a sleeper, never bosses).
- Each class is two directions for its own Wardens plus one company direction.

### Sporeling: spores pile on fast

#### Calling: Spore Print

> A Poisoned nightmare dispelled by any Warden leaves a mushroom on the path. The next nightmare to
> step on it takes a dose: 3 Poisoned at once. Flyers pass over.

Second line on the first-pick card: "Your Sporeling cards grow mushrooms and hand out doses."

**What you see at drift 1.** The first Shade falls and a small mushroom comes up where it fell. The
Shade behind walks onto it: the mushroom puffs and is gone, its badge jumps by 3, a cap pops up on
its back (up to 3 caps drawn). Mushrooms are objects you can count, never a tint on the path.

**Mushroom rules.**
- **Where:** on a route point, one per step, the step nearest where the nightmare fell. A nightmare
  that falls more than 1 cell from the route (a flyer over a wall) leaves none.
- **Used up:** one step, one dose, gone. No card reads "nightmares standing on mushrooms".
- **No timer. Mushrooms survive a rest** and are saved with the run. A mushroom goes only when it
  is stepped on, when its step leaves the route or gets a Warden planted on it, or when it is the
  oldest over the limit.
- **Nothing grows by waiting (owner ruling, section 21).** Mushroom Bed, Kept Ground and Side by
  Side run their timers only during a drift. When a rest starts, every step they could grow on is
  filled at once.
- **Limit:** 40 on the map. Over that, the oldest goes first, mushrooms no card regrows before
  mushrooms a card does.
- **Whose dose:** the spore Warden whose Poisoned was on the fallen nightmare (for card-grown
  mushrooms, the spore Warden it touches). If that Warden is sold, the nearest spore Warden takes
  it over; with none left it withers. A dose is one ordinary application: one batch, the normal 5 s.
- "Steps on" is a walker's centre reaching that route point. Flyers never do. Bosses and elites
  take doses like anyone else.
- A nightmare Poisoned only by Mycelium Sprouts leaves a mushroom too.
- Nothing is spent or burst. No pop.

#### Three directions

| Direction | Board | Pays in | Good against | Bad against |
|---|---|---|---|---|
| **Bed** | 3 or 4 spore Wardens packed round one fold, so steps of path touch two of them. A clump of mushrooms stands there before anything arrives, and at the rest | One nightmare takes dose after dose in one place, with no dispels needed: full of Poisoned in about 2 s | Elites, heavy single nightmares, the first seconds of a block. A boss on arrival and each time it returns to the fold | Swarms (the first few eat the bed; it takes 5 s to grow back). Flyers. A boss after the first 2 s: the bed stops at the Poisoned limit |
| **Carpet** | Spore Wardens strung singly down the route, each keeping the steps only it touches. Mushrooms in stretches along the whole path | The whole pack Poisoned at once, and doses that get bigger the further a nightmare walks | Swarms, long drifts, long routes | A lone boss or an all-elite drift (nothing falls, nothing is seeded). Flyers |
| **Garden** | One or two spore Wardens, each ringed by other kinds: Sprouts in act 1, another family later | Doses from every kind standing by; with another family, its status arriving 3 at once | Whatever the other family is good against; flyers a little (Pass It Round needs no mushroom) | A board that is all spore. Before another family it is two safe cards and Sprouts |

- **Opposite boards on the Commons.** Mushroom Bed counts steps touching **two** spore Wardens;
  Kept Ground counts mushrooms touching **only one**. No step is both, so a packed fold gets
  nothing from Kept Ground and a spread line gets nothing from Mushroom Bed.
- **Garden is the company build and says so.** Two of its five cards are safe (Pass It Round, Leaf
  Litter); three are bets on another family. Before one is owned, Garden is those two cards and
  Mycelium if drawn. That is the owner's ruling working as meant, not a hole.
- **3 of 5 without the Rare.** Bed: Mushroom Bed + Open Season + Twin Caps. Carpet: Kept Ground +
  Kicked Up + Leaf Litter. Garden: Pass It Round + Leaf Litter + Second Helping or Side by Side.
- **No boss direction.** Bed is an opener against a boss. The class has no answer to a lone boss or
  to flyers beyond Pass It Round; forms and another family cover those. Say it on the pick card:
  "Weak against flyers."

#### The 12 class cards

| # | Card | Rarity | Direction | Who it works for | Safe or bet | Text | What you see |
|---|---|---|---|---|---|---|---|
| 1 | **Mushroom Bed** | Common | Bed | Spore Wardens (by where they stand) | Safe | Path touching 2 spore Wardens grows a mushroom on each step every 5 s. Needs no dispels. | The build ghost lights the shared steps; mushrooms come up on them during a drift; when a rest starts every shared step fills at once (section 21) |
| 2 | **Open Season** | Uncommon | Bed | Spore Wardens | Safe | When a nightmare steps on a mushroom, each spore Warden's next attack on it is a dose too. | It steps, the mushroom puffs, then every spore Warden in reach lands one fat puff |
| 3 | **Spore Haze** | Rare | Bed | Single-target spore Wardens | Safe | A single-target spore Warden with 4 mushrooms near it attacks in clouds: each attack also lands on nightmares touching its target. | A haze over the full bed; puffs open into clouds until the bed is eaten down |
| 4 | **Kept Ground** | Common | Carpet | Spore Wardens (by where they stand) | Safe | A mushroom on path touching only one spore Warden grows back 6 s after it is stepped on. | It shrinks to a button and comes back; mushrooms elsewhere are gone for good |
| 5 | **Kicked Up** | Uncommon | Carpet | Any mushroom, whoever's dispel grew it | Safe | A nightmare stepping on a mushroom kicks up spores: up to 4 nightmares touching it take the dose too. | A green puff off the mushroom over the knot of nightmares |
| 6 | **It Grows on You** | Rare | Carpet | Any mushroom, whoever's dispel grew it | Safe | Each dose a nightmare takes is 1 bigger than its last, up to 6 Poisoned at once. Any mushroom counts. | The cap on its back grows with each dose; the badge jumps 3, 4, 5, 6 |
| 7 | **Pass It Round** | Common | Garden | Any Warden (Sprouts count); more for each other family | Safe | Each different kind of attacking Warden touching a spore Warden gives a dose with its first hit on each nightmare. Sprouts count. | A thread from the spore Warden to each kind beside it; their first shot lands green |
| 8 | **Second Helping** | Uncommon | Garden | Another family's Warden | **Bet** | Needs another family's Warden touching a spore Warden. After a nightmare takes a dose, that Warden's next hit adds 3 of its own status. | The dose puffs; the partner's next shot lands fat and its badge jumps 3 |
| 9 | **Everything Grows** | Rare | Garden | Another family's Warden | **Bet** | Needs another family's Warden. A mushroom on path touching one also gives 3 of that Warden's status with its dose. | Mushrooms beside a Jar, Dewdrop or bell wear its colour; stepping on one jumps both badges |
| 10 | **Twin Caps** | Uncommon | Bed + Carpet | Any mushroom | Safe | Each mushroom has two caps: it doses two different nightmares before it is used up. Mushrooms grow back 2 s slower. | Mushrooms drawn as a pair; one cap goes at a time |
| 11 | **Side by Side** | Uncommon | Bed + Garden | A spore Warden and another family's Warden | **Bet** | Needs another family's Warden. Path touching it and a spore Warden grows a mushroom on each step every 3 s. | Mushrooms coming up fast on the path between a spore Warden and its partner |
| 12 | **Leaf Litter** | Uncommon | Carpet + Garden | Any Warden | Safe | A nightmare dispelled near a spore Warden leaves a mushroom, Poisoned or not. Any Warden's dispel counts. | Mushrooms where a Sprout, a Jar's bolt or a bell did the work |

**Each direction has 5.** Bed 1, 2, 3, 10, 11. Carpet 4, 5, 6, 10, 12. Garden 7, 8, 9, 11, 12.
Nine safe, three bets.

**Rules behind the short texts.**
- **Mushroom Bed, Side by Side:** a step is a route point; it qualifies when that point is inside
  the path rule (1.25) of both Wardens. It regrows 5 s (3 s) after it is emptied. A step that
  qualifies for both grows one mushroom on the faster clock. Bed mushrooms never expire.
- **Kept Ground:** counted when the mushroom is stepped on. A lone spore Warden touches about 3
  steps of one lane, 6 in a fold. A mushroom touching two spore Wardens is not kept.
- **Open Season:** "attack" is whatever that Warden does next that lands on that nightmare (a puff,
  a cloud, a ring, a pulse); a cloud or ring counts once. Once per Warden and nightmare every 2 s.
  The dose replaces what that attack would have added; forms that add 2 or 3 add 3.
- **Spore Haze:** single-target = Sporeling, Driftspore, Inkcap, Lichenling, Old Lichen,
  Deliquescent. Counted each second. Stacks and puff damage both land on up to 4 others. It is not
  Mistveil's fog and adds no slow.
- **Kicked Up:** up to 4 others, nearest first. Each gets a fresh dose of 3 from the mushroom's
  Warden. A received dose counts for nothing else: not It Grows on You, Open Season, Second
  Helping or Everything Grows. Nothing is read or moved from the stepping nightmare.
- **It Grows on You:** counted on the nightmare for its whole life; only doses it stepped on.
- **Pass It Round:** one dose per kind per nightmare, however many of that kind stand there. A kind
  is a form (Sprout, Firefly Jar, Stormcap…). Spore forms and walls don't count. The dose rides
  that Warden's own first damage on the nightmare, from the spore Warden it touches. It needs no
  mushroom, so it is the class's one flyer card.
- **Second Helping:** "next hit" is the next time that Warden adds its status to that nightmare
  (a bell adds Drowsy on every second ring; a beam or cloud once a second). It adds 3 in place of
  its usual amount, inside its own application: its clock, its strength, no quiet add. Once per
  Warden and dose.
- **Everything Grows:** the mushroom takes the colour of the nearest other-family Warden it
  touches. Its 3 stacks are an ordinary application credited to that Warden (so it can start the
  status, with the normal clock). If that Warden is sold the colour goes. One colour per mushroom.
- **Twin Caps:** the 2 s is added to every regrow (Mushroom Bed 7 s, Kept Ground 8 s, Side by Side
  5 s). Against one lone elite it only slows the bed: that is its cost.
- **Leaf Litter:** the nightmare must be near a spore Warden when it falls. One mushroom per dispel.

**Family forms.** Fairy Ring and Elf Circle rings are attacks, not mushrooms; no class card counts
them. Deliquescent's pool is not a mushroom.

#### The 3 lent cards

In the pool for every Sporeling owner, the Sporeling start included. No mushrooms and no doses
here: a later family brings no Calling.

| Card | Rarity | Who it works for | Safe or bet | Text | What you see |
|---|---|---|---|---|---|
| **Mycelium** (existing, unchanged) | Uncommon | Sprouts | Safe | Sprouts touching a spore Warden puff spores too: each hit adds 1 Poisoned. | Sprouts wearing little caps, shooting green |
| **Hothouse** (reworked) | Uncommon | Another family's Warden | **Bet** | Needs another family's status. When a nightmare's Poisoned reaches 6, each other status on it gains 5 at once. Once per nightmare. | A burst of spores at 6; every other badge on it jumps |
| **Overnight** | Rare | A spore Warden, on another family's status | **Bet** | Needs another family's status. A spore Warden's attack adds 3 Poisoned at once to a nightmare carrying one. Once a second each. | Puffs on Charged, Soaked or Drowsy nightmares land fat; caps pop up on them |

- **Mycelium is the one lent card that works alone** (every start has Sprouts). It is a card in the
  pool, not a gift, and it is not a 13th class card.
- **Hothouse uses the quiet add. This is new code** (`EnemyStatuses.add_quiet`: stacks up to the
  normal limit; no clock, strength or source change; never starts a status). It is the only card
  in these two families that needs it. It counts Poisoned from any source, Mycelium Sprouts
  included. The 6 does not change with Brimming. The jump may complete a bolt or a Reaction's need.
- **Overnight:** once a second for each spore Warden and nightmare. The carried status must come
  from another family's Warden. It is the spore Warden's own application: one batch, the normal
  5 s, the limit unchanged. Forms that already add 2 or 3 add 3.
- The old Hothouse ("starts a third full") is gone: the player could not see it.


### Firefly Jar: damage spreads to other nightmares

#### Calling: Lantern Light

> Nightmares in a Firefly Warden's glow are Lit. When any Warden dispels a Lit nightmare, by hit,
> poison or cloud, half its hit forks to the nearest Lit nightmare.

Second line on the first-pick card: "Your Firefly cards make forks bigger, further and more often."

**What you see in the first drift with a Jar:** the glow on the path, and a small fork leaping off
every nightmare that falls in it, whoever dispelled it: the Jar, a Sprout, later a spore Warden's
poison.

- Small: half of one hit, once per dispel. A nightmare dispelled by a fork gives no fork.
- A bolt that dispels forks half the Jar's **hit**, not half the bolt.

#### Three directions

| Direction | Board | What forks | Good against | Bad against |
|---|---|---|---|---|
| **Storm** | Firefly Wardens packed so their glows cross: one big light with gold path through it. More Jars on a spot, more forks | Dispels on gold path, and bolts | Swarms and packed drifts | A lone boss; thin drifts |
| **Spotlight** | One or two good Firefly Wardens forward by the path, heavy Wardens covering that light (Sprouts at first) | Heavy hits, off whatever they strike | A tough leader with company; elites with an escort | Fast swarms of small nightmares; a lone boss |
| **Lanternway** | A string of separate lights down the route, some of them lit Sprouts | Damage handed forward, light to light, and saved for the next arrival | Long routes, fast nightmares, thin drifts | A short route; a lone boss |

- **Opposite pulls.** Storm joins glows into one light; Lanternway counts lights, so every joined
  glow is a light lost. Spotlight spends its Dew on heavy Wardens and on making its one Jar strong.
- **Storm wants Jars.** Gold path forks once per Firefly Warden lighting it, and bolts come only
  from Charged. No other family can stand in for either.
- **Jars are not lamps.** A fork started by another family's Warden is never bigger than 3 seconds
  of damage from the strongest Firefly Warden lighting the nightmare that was hit (**brightness**,
  shown on the light). A base Jar passes a Pebbling's fork whole and about a quarter of a
  Mossback's. To fork a big hit in full you grow the Jar. Firefly Wardens' own hits and bolts are
  never capped.
- **A lone boss is the family's bad matchup, and the class accepts it.** Ground Strike is cut and
  not replaced. Forks need a second nightmare. The answers are the family's own beam forms
  (Sunpetal's role line is "boss killer") and another family. Waiting Spark saves forks for a
  boss's escort, never for the boss.
- **3 of 5 without the Rare.** Storm: Where Lights Meet + Chain of Lanterns + Nothing Wasted.
  Spotlight: Hammerfall + Knock-On + Nothing Wasted or Ambush. Lanternway: Fireflies in the Grass
  + Signal Fires + Waiting Spark or Ambush.

#### The 12 class cards

| # | Card | Rarity | Direction | Who it works for | Safe or bet | Text | What you see |
|---|---|---|---|---|---|---|---|
| 1 | **Where Lights Meet** | Common | Storm | Any Warden's dispel; counts Firefly Wardens | Safe | Path lit by two or more Firefly Wardens glows gold. Any Warden's dispel there forks once for each Firefly Warden lighting it, up to 4. | Gold path, brighter with each Jar; two, three or four forks off each nightmare that falls on it |
| 2 | **Chain of Lanterns** | Uncommon | Storm | Bolts (any Warden that Charges; in practice Firefly) | Safe | A bolt on a Lit nightmare also forks to the 2 nearest Lit nightmares for half. Any Charged bolt counts. | Lightning forking through the glow |
| 3 | **Last Spark** | Rare | Storm | Any Charged nightmare | Safe | A Charged nightmare that is dispelled, or walks out of its last light, throws its charge as a bolt at the nearest Lit nightmare. | A spark leaping off each nightmare that falls, or back into the light as one walks out |
| 4 | **Hammerfall** | Common | Spotlight | Any heavy Warden of any family; Sprouts | Safe | A heavy Warden's hit on a Lit nightmare forks to the nearest other Lit nightmare for half. Sprouts count as heavy for this. | A flash and one fork from each Sprout or heavy shot into the light |
| 5 | **Knock-On** (new) | Uncommon | Spotlight | Any heavy Warden of any family | Bet: needs a heavy Warden (the family grows four) | When a heavy Warden's fork dispels a nightmare, it forks once more to the nearest Lit nightmare, for the same. | A heavy hit on the leader, the fork drops its escort, and leaps again |
| 6 | **Spotlight** | Rare | Spotlight | Any heavy Warden of any family | Bet: needs a heavy Warden | A heavy Warden's hit on the front Lit nightmare also forks to every other nightmare in that light, for a quarter. Up to 6. | A beam on the leader; each heavy hit flashes down the light |
| 7 | **Fireflies in the Grass** (existing, changed) | Common | Lanternway | Sprouts | Safe | For each Firefly Warden you own, one Sprout of your choice glows: a small light of its own. | A lantern button on Sprouts; small glows along the path |
| 8 | **Signal Fires** | Uncommon | Lanternway | Any Warden | Safe | Any Warden's dispel in one light also forks, for half, to the front nightmare in the next light ahead. | The next light flashes; a fork lands on its leader |
| 9 | **Lanternway** | Rare | Lanternway | Bolts | Safe | A bolt in any light also forks to the front nightmare in each of the next 3 lights ahead, for half. | Lightning running down the string of lights |
| 10 | **Nothing Wasted** | Uncommon | Storm + Spotlight | Any Warden | Safe | When any Warden's hit or a bolt dispels a Lit nightmare, the damage left over forks to the nearest Lit nightmare. | The rest of a big hit leaping to the next nightmare |
| 11 | **Ambush** | Uncommon | Spotlight + Lanternway | Any Warden | Safe | Any Warden's first hit on a nightmare in each light it enters forks to the nearest other Lit nightmare for half. | A flash and a fork as it steps into each glow |
| 12 | **Waiting Spark** | Uncommon | Storm + Lanternway | Any Warden | Safe | A fork with nowhere to go waits in its light for 5 s. Up to 3 wait; all strike the next nightmare to enter. | Sparks hanging on the path, one, two, three, then all striking the next arrival |

**Each direction has 5.** Storm 1, 2, 3, 10, 12. Spotlight 4, 5, 6, 10, 11. Lanternway 7, 8, 9,
11, 12. Eight of the twelve work for any Warden (1, 4, 5, 6, 8, 10, 11, 12); the class has no card
that needs another family.

**Rules behind the short texts.**
- **One fork per nightmare per event,** the largest wins. An event forks to at most 6 nightmares.
- **Brightness** (section 13) caps every fork started by a Warden that is not a Firefly Warden. A
  lit Sprout's light is as bright as a base Firefly Jar.
- **Where Lights Meet** replaces the Calling's fork on gold path; it is not added. Two Jars give 2
  forks (the last draft gave 3 for any gold path), three give 3, four give 4.
- **Last Spark:** "its charge" is the built share of a full bolt (`stored_bolt_damage`). On
  walking out its Charged ends. Leaving a glow with lit path still ahead does nothing, so a
  serpentine does not empty a nightmare at every lane end. This bolt is a fork: Chain of Lanterns
  and Lanternway add nothing to it.
- **Hammerfall:** one fork per attack, from the main target; a splash or a line forks once.
- **Knock-On:** the fork must come from a heavy Warden's hit (Hammerfall, Spotlight, Ambush,
  Nothing Wasted). One extra hop; the second fork never forks again and takes no leftover. It is
  the one exception to "a fork's dispel gives no fork".
- **Spotlight:** at most 6 others. The nearest takes Hammerfall's half, not both.
- **Fireflies in the Grass:** chosen on the Warden panel (a button, so it works on touch). The
  panel refuses a Sprout inside a Firefly Warden's glow. Growing the Sprout into a Warden frees the
  pick. A Sprout light is the path touching that Sprout. It never makes gold path.
- **Signal Fires:** once for each light each second. **Lanternway:** each of the 3 is the next
  light ahead of the one before.
- **Nothing Wasted:** never more than the hit or bolt itself; a tick or cloud has no leftover.
  With the Calling, the nearest nightmare takes the larger of the two.
- **Ambush:** once for each nightmare and light. A beam forks one second's worth. A pulse is one
  event, so the 6 cap holds.
- **Waiting Spark:** sparks never wait a second time, never strike a nightmare already in that
  light, and go out when a rest starts. Alone it now does a job: in a thin drift every fork is lost
  without it, and with it each dispel loads the light for the next arrival.

**Family forms not duplicated.** Stormcap chains its own hit, Sparkler adds Charged, Midsummer's
beam carries on, Jarlink is a standing line. No card forks a Jar's ordinary hit.

#### The 3 lent cards

In the pool for every Firefly owner, the Firefly start included. No Lit and no lights: these work
**near** a Firefly Warden. All three do nothing until another family's Warden stands near one.

| Card | Rarity | Who it works for | Safe or bet | Text | What you see |
|---|---|---|---|---|---|
| **Live Wire** (existing name, reworked) | Common | Another family's Warden | **Bet** | Needs another family's Warden near a Firefly Warden. When it dispels a nightmare, by hit, poison or cloud, its hit forks to the nearest nightmare. | A wire of light from the Jar to its neighbour; each of its dispels throws a full fork |
| **Crossfire** (existing, changed) | Uncommon | A Firefly Warden with another family's Warden | **Bet** | When a Firefly Warden and another family's Warden near it hit one nightmare within 1 s, the hit forks to the 2 behind for half. | The two shots cross; two forks leap back down the line |
| **Like to Like** | Rare | Another family's Warden, on Charged nightmares | **Bet** | Needs another family's Warden near a Firefly Warden. Damage it deals to a Charged nightmare forks to the nearest other Charged nightmare, for half. | Forks in the other family's colour running between Charged nightmares |

- **Live Wire** lends the Calling's fork at full size, for dispels only. It was "a hit forks for a
  third" (never taken). A tick or cloud dispel forks one second of that Warden's damage, so a
  spore Warden's poison counts. The receiver must be near the dispelled nightmare. One per dispel.
- **Crossfire:** half the weaker hit. Its 3 s wait per nightmare and "stored before defences" stay
  as built.
- **Like to Like, bounded.** Both ends must be Charged, so it follows what the Firefly Wardens have
  Charged and is not a flat boost on a Dewdrop start, where everything in the water is Soaked.
  - The receiver must be near the nightmare that was hit.
  - Hits fork per hit; a pulse or splash forks once. Poisoned ticks and clouds fork once a second
    per nightmare, half of that second's damage.
  - Bolts, Reactions and forks never fork from it. One fork per hit across the three lent cards.
  - It reads Charged and moves none: the receiver's Charged is unchanged.
- **Brightness applies** to all three (the near Firefly Warden's).
- On a Firefly start these sit beside the Calling; one fork per nightmare per event still holds,
  the largest wins.


### Dewdrop: water on the path

#### The Calling: Puddles

> The path touching your Dewdrops is water. A Dewdrop's hit there ripples: nightmares within 4
> steps in that water are Soaked. Dewdrops hit Soaked nightmares harder.

- **Drift 1:** blue water beside the Dewdrop, a ripple along it with every splash.
- "Within 4 steps" is now printed (the old text said "every nightmare in that water").
- The last sentence is the built rule (water hits +20% on Soaked, at most +40%).
- Accepted ruling, unchanged: the ripple is a normal Soaked application, so Soaked holds in
  water. Soaked only.

#### Three directions

| Direction | Kind | Board | Payoff | Good against | Bad against |
|---|---|---|---|---|---|
| **Flood** | own | Three or more Dewdrops and walls in a line: one water of 14 steps or more | Paid as each nightmare **leaves** | Swarms, slow walkers | Fast nightmares, flyers, short routes |
| **Crossings** | own | Lone Dewdrops in the dividing walls, walls round them, shooters set back out of touch; short loops round each turn | Paid when a nightmare **walks back in** | Tough walkers, elites, bosses (Riptide's damage lands) | Flyers; open maps that cannot fold; swarms |
| **Waterside** | company | One Dewdrop in a block with other Wardens packed on its bank | Paid by the **other Wardens touching the water** | Mixed drifts, resisting kinds | Flyers, fast nightmares; thin with Sprouts only |

- **Crossings and Waterside no longer share a board.** A Dewdrop is lone only while nothing else
  that attacks touches its water. Planting a Warden on the bank ends it, and the ghost says so.
  A water has a bank (Waterside) or an empty one (Crossings), never both.
- **Flood and Crossings:** a second Dewdrop on the water ends lone. Levee joins waters, which
  ends lone too.
- **3 of 5, no Rare.** Flood: Levee, Backwash, Swell. Crossings: There and Back, Both Banks,
  Swell. Waterside: Caught Wading, Across the Water, Wake Ripple (with Sprouts only: the first
  two, and Wash Away).

#### The 12 class cards

| # | Card | Rarity | Direction | Who it works for | Safe or bet | Text | What you see |
|---|---|---|---|---|---|---|---|
| 1 | **Levee** | Common | Flood | Dewdrops | safe | A row of up to 2 walls between two Dewdrops carries their water along the path beside it. Sprouts are not walls. | Water running on past the walls; the length number climbing |
| 2 | **Backwash** | Uncommon | Flood | Dewdrops | safe | A Soaked nightmare leaving water is hit once, free, by each Dewdrop touching that water. Up to 4 Dewdrops. | A volley of splashes chasing it out |
| 3 | **Breakwater** | Rare | Flood | Dewdrops | safe | A fully Soaked nightmare leaving water 14 or more steps long takes a wave: 3 s of damage from the strongest Dewdrop touching it. | A wave breaking at the water's end; water looks deeper at 14 |
| 4 | **There and Back** | Common | Crossings | A lone Dewdrop | safe | A nightmare that walks back into a lone Dewdrop's water is hit once, free, by that Dewdrop. Lone: only walls touch its water. | A drop over its head after the first pass, bursting as it steps back in |
| 5 | **Both Banks** | Uncommon | Crossings | A lone Dewdrop | safe | A lone Dewdrop with water on two sides splashes both: each splash also lands on the front nightmare in its other water, at half. | Every shot matched by a smaller one into the far lane |
| 6 | **Riptide** | Rare | Crossings | A lone Dewdrop | safe | A Soaked nightmare walking back into a lone Dewdrop's water is pulled under for 2 s and takes 3 s of that Dewdrop's damage. | The water closes over it; it wades out slowly, hurt |
| 7 | **Caught Wading** | Common | Waterside | Any other Warden touching the water | safe | The first time a nightmare is Soaked in a water, each other Warden touching that water hits it once, free. Up to 3 Wardens. | The whole bank firing as it gets wet |
| 8 | **Wake Ripple** (existing, moved, changed) | Uncommon | Waterside | Another family's Warden touching water | **bet** | When another family's Warden touching water adds its status to a nightmare in it, the ripple carries 1 stack to the others in that water. | The ripple running green, gold or pink; badges ticking up along the water |
| 9 | **Wash Away** (flagged) | Rare | Waterside | Any Warden touching the water | safe | A Soaked nightmare in water loses half its resistance to every Warden touching that water. Not bosses. | Shield icons crack while it wades; fewer grey "resisted" puffs |
| 10 | **Swell** | Uncommon | Flood + Crossings | Dewdrops | safe | A Dewdrop's splash that lands in water spreads through that water, up to 4 steps each way, at half outside its own circle. | The whole water heaving on each splash |
| 11 | **Across the Water** | Uncommon | Flood + Waterside | Any Warden touching water | safe | Any Warden touching water also reaches Soaked nightmares up to 3 steps further along that water. Pulses land on them too. | Shots skipping along the water past the range ring; a bell's pulse running down it |
| 12 | **The Water Remembers** | Uncommon | Crossings + Waterside | Another family's statuses | **bet** | A nightmare that walks back into a Dewdrop's water gets back every status from another family's Warden that wore off since it left. | Its badges refilling with a splash |

Each direction has 5: Flood 1, 2, 3, 10, 11. Crossings 4, 5, 6, 10, 12. Waterside 7, 8, 9, 11, 12.
Count: 7 for Dewdrops only, 3 for any Warden, 2 bets on another family.

**Rules behind the short texts.**
- **Levee:** up to 2 walls, each touching the next, a Dewdrop touching each end.
- **Backwash, There and Back, Caught Wading:** free hits (section 0). A Tidecaller's free hit is
  on one nightmare; an Edgestone on a bank gets 0.6 of its hit, once a second.
- **Breakwater:** that nightmare only; once for each nightmare and water. 14, because Dewdrop,
  2 walls, Dewdrop ending at a hairpin tip is about 13 steps for 56 Dew (tower-defence review).
  "Dries off" is cut.
- **There and Back:** each later water of that Dewdrop pays too.
- **Both Banks:** the far splash lands with its Soaked, so the nightmare arrives at the second
  side already wet. This is what makes Riptide land without needing "fully Soaked".
- **Riptide:** once for each nightmare and Dewdrop. The slow is the existing pull-under, inside
  the floors, so with Drowsy at the floor it adds no control. The damage is 3 s of that
  Dewdrop's own damage on that nightmare (about 65 for a base Dewdrop, about 300 for a
  Tidecaller, by the review's figure), paid over the 2 s. Bosses take the damage and the boss
  slow. It is not the Drown Reaction: no chain link, no Echo Hollow repeat, no Still Pool, the
  "drowned" mark untouched, Deep Water does not read it. It no longer dries the nightmare.
- **Wake Ripple:** the carried stack is that Warden's own application of 1 stack, to nightmares
  within 4 steps in that water, once a second for each receiver. Charged stops one short of a
  bolt. Never Rooted. A carried stack never counts as a second Warden for any Sporeling rule.
- **Wash Away:** family resistance only (×0.5 becomes ×0.75). Status length, immunities, the
  blight coat and shape multipliers stay. "Fully" is dropped: a 3-step pond rarely fills Soaked.
- **Across the Water:** path in that water within 3 steps of a point in the Warden's reach,
  never more than 5 cells from the Warden. A pulse only fires for a nightmare in its own reach.
- **The Water Remembers:** any Dewdrop, lone or not. Stacks lost since it left, never above
  what it carried when it left. A status that had ended comes back with 3 s. Poisoned comes back
  as one batch that is not a native application. Never Rooted, never Soaked. It stops one short
  of a bolt or a Reaction's need. Once for each nightmare and Dewdrop.

**Wash Away: the council split.** Roguelite: cut. Tower defence: allow at half, family
resistance only. Player: clear and wanted. **Recommendation: keep it** in the tower-defence
form, with the cracked shield drawn on the nightmare so it is not invisible. It is the only
Rare here that is not damage, and it is the card a mixed-family player reads and wants. It
still needs enemy design's yes. **Named replacement: High Water**, "A Soaked nightmare in water
takes the first hit from each other Warden touching that water twice." (the second landing is a
free hit; once for each nightmare, Warden and water).

**Not repeats of the forms:** no card makes ground that Soaks walkers by itself, freezes, pushes
back or pays Dew.

#### The 3 lent cards

In the pool for every Dewdrop owner, the Dewdrop start included. No water (a later family
brings no Calling): each is tied to "near a Dewdrop".

| Card | Rarity | Direction | Who it works for | Safe or bet | Text | What you see |
|---|---|---|---|---|---|---|
| **Something in the Water** | Common | lent | A Dewdrop near another family's Warden | **bet** | A Dewdrop's splash adds 1 to each status another family's Warden near it has put on that nightmare. Once a second. | The splash tinted with the partner's colour; that badge ticks up |
| **Soaked Through** | Uncommon | lent | Another family's Wardens near a Dewdrop | **bet** | When a nightmare near a Dewdrop becomes fully Soaked, each Warden of another family near that Dewdrop hits it once, free. Up to 4. | The drop over it bursts and the whole block fires |
| **Run-Off** | Rare | lent | Another family's statuses | **bet** | When a Soaked nightmare is dispelled near a Dewdrop, the statuses on it from another family's Wardens wash onto the nearest Soaked nightmare. | Its badges pour off in a stream to the next wet nightmare |

- **Three different cards:** my Dewdrop helps your status along; your Wardens pounce on what I
  soak; what you built is not lost when the nightmare falls.
- **Something in the Water:** quiet add, on the splash's main target, once a second for each
  Dewdrop, at most two statuses. It never starts a status, so a Dewdrop is never a second Jar.
- **Soaked Through:** free hits; once for each nightmare.
- **Run-Off:** the stacks move, they are not copied. The receiver must be within 2 cells. It
  takes them up to its limit and keeps the longer clock. Charged stops one short of a bolt.
  Poisoned arrives as one batch that is not a native application. Never Rooted.
- **Why this set is worth a second pick:** each card reads stacks or gives a free hit with its
  status, so it pays a family whose damage is ticks (Sporeling was the worst receiver).
  Skipping Stones (reach) is gone; Wake Ripple moved into the class set.


### Bellflower: every fourth ring happens again

#### The Calling: Keeping Time

> Every 4th ring on a nightmare is a Toll: it lands again, at half. Each nightmare starts with
> 2 of its 4 pips filled.

- **Drift 1:** on a Shade's second ring from your bell, a deep note and a second, fainter ring.
- One rule and one number; the owner's sentence is whole. ("Its first Toll comes on ring 2"
  needed a second read.)
- A ring is a hit from one of your bells: the card shows the bell icon beside the word.

#### Three directions

| Direction | Kind | Board | Payoff | Good against | Bad against |
|---|---|---|---|---|---|
| **Peal** | own | Bells in a row down a long stretch, 1 to 4 steps of path between reaches | Tolls rolling down the row with each nightmare | Swarms, fast nightmares | Short routes, flyers |
| **Crescendo** | own | One pulsing bell at a hairpin tip, path on two or three sides, drifts called early | A bell whose reach and Tolls grow while it stays busy | Slow, tough nightmares; bosses | Fast nightmares, drifts with gaps |
| **Ensemble** (was Lullaby) | company | A bell bedded in a block, path on one side, other Wardens touching it | Other Wardens' hits fill the pips, wake sleepers and are repeated | Mixed drifts, elites | Bosses (no naps), flyers out of reach |

- **Ensemble and Crescendo no longer share a board.** Ensemble cards count Wardens touching
  the bell: a block bell has up to five such places, a hairpin-tip bell one or two. Crescendo
  cards grow on a pulsing bell's own pulses over a long stay, and a block bell with one side of
  path gets 2 or 3 rings on a Shade. Hits counted by Join In or Struck Bell never grow Full
  Voice or Rising Song.
- **Peal and Crescendo:** Peal cards need a next bell across a gap; Full Voice closes gaps.
- **3 of 5, no Rare.** Peal: Sound Carries, Rounds, Hanging Note. Crescendo: Full Voice,
  Overture, Hanging Note. Ensemble: Join In, Nod Off, Sleep No More.

#### The 12 class cards

| # | Card | Rarity | Direction | Who it works for | Safe or bet | Text | What you see |
|---|---|---|---|---|---|---|---|
| 1 | **Sound Carries** | Common | Peal | A pulsing bell | safe | A pulsing bell's ring carries 4 steps down the path past its reach, at half, stopping at the next bell's reach. Carried rings count. | A band of sound running on down the lane; pips filling between bells |
| 2 | **Rounds** | Uncommon | Peal | Bells | safe | A Toll is heard again: when that nightmare walks into the next bell's reach, within 4 steps, it lands once more, at half. | The next bell answers as it arrives |
| 3 | **Call and Answer** | Rare | Peal | Bells | safe | After a Toll, the next bell down the path, within 4 steps, Tolls that nightmare on its first ring. | Toll after Toll rolling down the row with it |
| 4 | **Join In** | Common | Ensemble | Any other Warden touching a bell | safe | Hits from other Wardens touching a bell count as rings on nightmares in its reach. Sprouts count. Each Warden, once a second. | Pips filling on their shots; a thread from each Warden to the bell |
| 5 | **Nod Off** | Uncommon | Ensemble | Bells; every Warden gains from the stop | safe | A nightmare's first Toll puts it to sleep for 1 s. One sleeper for each bell. | It slumps under a sleep mark |
| 6 | **Rude Awakening** | Rare | Ensemble | Any Warden | safe | The next hit on a nightmare waking from any sleep, from any Warden, deals double. | It jolts upright; the next hit bursts with light |
| 7 | **Full Voice** | Common | Crescendo | A pulsing bell | safe | Each pulse that Tolls makes a pulsing bell's reach half a cell bigger, up to 4 cells. It resets when its reach is empty. | The reach growing; it snaps back after a gap |
| 8 | **Overture** | Uncommon | Crescendo | A pulsing bell | safe | When a drift's first nightmare enters a pulsing bell's reach, every ring is a Toll until that reach is empty. Up to 8 s. | The bell flaring for as long as it stays busy |
| 9 | **Rising Song** (reworked) | Rare | Crescendo | A pulsing bell | safe | A pulsing bell's Tolls land again harder each time: half a ring, then three quarters, up to double. It resets when its reach is empty. | Each Toll's second ring bigger and deeper than the last |
| 10 | **Sleep No More** | Uncommon | Peal + Ensemble | Any Warden | safe | The hit that wakes a sleeping nightmare, from any Warden, lands in full on every nightmare touching it too. | The sleeper jolts and the hit bursts out of it |
| 11 | **Hanging Note** | Uncommon | Peal + Crescendo | A pulsing bell | safe | A pulsing bell's Toll leaves a note on the path for 2 s. Nightmares walking into it are struck, at half. One per bell. | A note left on the ground, fading |
| 12 | **Refrain** | Uncommon | Ensemble + Crescendo | Another family's Warden, anywhere | **bet** | A Tolled nightmare rings on for 2 s: the next hit on it from another family's Warden lands again, in full. | The nightmare humming; a partner's shot struck twice |

Each direction has 5: Peal 1, 2, 3, 10, 11. Crescendo 7, 8, 9, 11, 12. Ensemble 4, 5, 6, 10, 12.
Count: 7 for bells only, 4 that pay any Warden, 1 bet on another family (was 11, 1, 0).

**Rules behind the short texts.**
- **Sound Carries:** toward the Heartwood only. Each nightmare takes a carried ring once per
  pulse. Carried rings fill pips, and a Toll in the gap repeats the carried ring (a quarter
  ring). A lone bell gains too; a row gets unbroken sound.
- **Rounds:** one third landing per Toll. It is not a ring and cannot be repeated again.
- **Call and Answer:** the once-a-second Toll limit applies. Toward the Heartwood only.
- **Join In:** the Toll is always the bell's own ring, from the bell whose reach holds the
  nightmare. Free hits and forks do not count. A counted hit is not a pulse, so it never grows
  Full Voice or Rising Song.
- **Nod Off:** the nap rule. Once for each nightmare. The Toll's second landing still lands.
- **Rude Awakening:** every sleep counts: naps, full Drowsy, a Lullaby Bell, a Dreamcatcher.
  The hit must land within 2 s of waking; the hit that wakes it counts. Once per sleep. With
  Pinned, only the larger multiplier applies. It no longer makes its own sleeper, so it does
  not repeat Nod Off.
- **Full Voice:** one step per pulse, however many nightmares that pulse Tolled. 4 cells in
  all, Hush included.
- **Overture:** per bell, once a drift. Its Tolls always land at half, whatever Rising Song
  says, and obey one sleeper per bell.
- **Rising Song:** one step per pulse that Tolls: 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2. At the top
  it is about half again a bell's damage on what it Tolls.
- **Sleep No More:** up to 6 nightmares. Each takes that hit before its own defences, never
  more than one second of that Warden's damage. A Toll's landing can be the waking hit.
- **Hanging Note:** it is the Toll's second landing left on the ground, about 1 cell wide.
  Struck once each. Not a ring. It does not keep a reach busy.
- **Refrain:** the repeat is a free hit at full strength (section 0), so never more than one
  second of that Warden's damage; each Warden once every 2 s. Sprouts and bells don't count:
  it says "another family's".

**If any hit wakes a sleeper** (assumed from the earlier drafts; not read in code), a nap under
fire is short. That is intended: naps are what Sleep No More and Rude Awakening fire from, and
control stays small. Tiptoe (a second slow on top of the nap) is cut.

**Not repeats of the forms:** no card adds Charged, sets off bolts by itself, Catches, echoes
Reactions, Silences, or sleeps a whole reach.

#### The 3 lent cards

In the pool for every Bellflower owner, the Bellflower start included. A later family brings no
Calling, so each card carries "every 4th ring" itself, with the same count (on the nightmare,
the half-second rule, 2 pips filled). On a Bellflower start that sentence is already true and
adds nothing twice.

| Card | Rarity | Direction | Who it works for | Safe or bet | Text | What you see |
|---|---|---|---|---|---|---|
| **Struck Bell** | Common | lent | Another family's Wardens near a bell | **bet** | Every 4th ring on a nightmare lands again at half. Hits from another family's Wardens near a bell count as rings. | Their shots filling the pips; the bell's deep second ring |
| **Chorus** (existing, changed) | Uncommon | lent | Another family's Wardens near a bell | **bet** | Every 4th ring on a nightmare, the bell also repeats the last hit another family's Warden near it landed there, at half. | The bell flashes in the partner's colour and its shot lands again |
| **Knell** | Rare | lent | Another family's statuses | **bet** | Every 4th ring on a nightmare sets off one status from another family's Warden: it pays out at once and is used up. | The badge bursts on the beat |

**Knell, by status. Each line uses up what it pays.**

| Status | What happens | What is used up |
|---|---|---|
| Poisoned | It ticks once more, at once | Its oldest batch is gone. At the cap that batch was about to be pushed out anyway, so the bet pays most in a full pile. One tick, not a burst of the pile |
| Charged | It goes off as a bolt for the charge it has | All its Charged. The card's tooltip warns that this keeps it from Thunderclap and Ignite |
| Soaked (must be fully Soaked) | Up to 2 Dewdrops near it hit it once, free | All its Soaked: it is wrung dry and has to fill again. The cost is no longer fake |

- Rooted, Exposed and Drowsy are never set off. One status per Toll, the fullest first.
- **Struck Bell:** a counted hit must land on a nightmare inside that bell's reach; once a
  second for each Warden. Near (2 cells) is wider than Join In's touching, so on a Bellflower
  start the two add up rather than repeat. The Toll is always the bell's own ring.
- **Chorus:** half, never more than half a second of that Warden's damage. The hit is stored
  before defences. Its status comes with it as a quiet add. A Poisoned tick is never "the last
  hit". Each hit is repeated once, by Chorus or by Refrain, never both.
- **Knell on Charged:** a bolt set off by a bell forks at most once.


---

## 21. Owner rulings on the edit 4 cards (2026-10-12)

| # | Card or question | Ruling |
|---|---|---|
| 1 | Run-Off, Wake Ripple, Something in the Water (Dewdrop cards that put statuses on other nightmares) | **All three stay.** Inside the water this is Dewdrop's thing, not Whirligig's copying |
| 2 | Wash Away (halves a wet nightmare's resistance to Wardens touching the water) | **Stays.** Still needs a check with enemy design |
| 3 | Knock-On (the one "fork forks again" exception) | **Allowed** |
| 4 | Rising Song, Rounds | **Both stay.** "Damage boosts with conditions are ok." Only plain, unconditional damage boosts are out |
| 5 | Guiding Light (spreads Exposed from a Firefly form) | **Fix it.** Firefly spreads damage, never statuses |
| 6 | Mushrooms through rests, brightness, three lent cards per family | **Fine**, with one condition: the player must never feel they have to wait for something to finish |

**What ruling 4 changes.** The standing rule is now: a card may raise damage when it asks something
of the board or the play (a row of bells, a bell kept busy, a place, a timing). It may not be a flat
"+N% damage". Earlier council notes that struck cards out as "position-gated numbers" (Hammerfall
in section 14, Heavy Going, Firefly Trail) were stricter than the owner wants.

**What ruling 5 changes.** Proposed new text for Guiding Light (Rare, needs Lanternmoth):
"A hit on a fully Exposed nightmare forks to nightmares within 1 cell of it, for half."
Guiding Light II: "…within 2 cells…". It keeps its place, its need for full Exposed and its two
levels; what spreads is damage. The fork follows the Firefly fork rules (damage only, never forks
again, one per nightmare per event, bosses take half).

**What ruling 6 changes (Sporeling).** Mushroom Bed, Kept Ground and Side by Side grow mushrooms on
a timer, and the draft let that run during rests, which pays a player for sitting at a rest. New
rule: **when a rest starts, every step that can grow a mushroom is filled at once, and nothing
grows by waiting.** During a drift the timers run as written. The same test applies to every
family: no card may get stronger while the player waits at a rest with nothing arriving.
- Checked against the other three: Firefly's waiting sparks go out when a rest starts; Bellflower's
  Full Voice, Overture and Rising Song reset when a bell's reach is empty; Dewdrop has nothing on a
  timer. No other card needs changing.

### Cards cut earlier for being conditional damage (re-checked against ruling 4)

The council struck these out as "numbers behind a condition". Under the owner's ruling they are
allowed. Whether each should return is a design choice, not a rule question.

| Card | Family | Text when cut | Worth bringing back? |
|---|---|---|---|
| Firefly Trail | Firefly Jar | A nightmare that has passed through 3 different lights takes 30% more damage for the rest of its walk. | **Yes, for Lanternway.** It is the build's own payoff and asks for a string of lights. It would replace Ambush, which the player would never take |
| Hammerfall (first form) | Firefly Jar | Wardens that attack once a second or slower deal 25% more damage to Lit nightmares. | No. The fork version is built and fits the family's thing better |
| Ground Strike | Firefly Jar | A heavy Warden's hit on the only Lit nightmare in its light strikes it a second time for half. | **Maybe.** It was the family's only answer to a lone boss, which is now its accepted bad matchup |
| Heavy Caps | Sporeling | Outside spore reach, Fruiting nightmares walk 15% slower. | No. Its build (Host) is gone |
| Old Growth | Sporeling | Each spore reach a nightmare has walked out of adds 1 Poisoned to later spore hits on it. Up to 3. | No. Carpet's It Grows on You does this with mushrooms |
| Heavy Going | Rootling | Nightmares walk 20% slower on root ground. | Hold for Rootling's turn |
| Deep Frost (existing) | Dewdrop | Frozen nightmares take 45% more damage. Needs Frostfern. | Already in the game; no longer a candidate for retiring |

---

## 22. Generic cards after the Firefly playtest (owner, 2026-10-13)

**Owner, after a Firefly Jar run on the prototype:** *"feels more impactful the cards but i feel
like the regular generic cards arent good enough now. Should feel like a big choice between class
cards and generic."* Direction chosen: generic cards get **a different job**, and *"the generic
cards should be good for every class."*

**The run** (lost in act 2, five offers, from `run_history.json`):

| Drift | Offered | Taken |
|---|---|---|
| 5 | Waiting Spark, Knock-On, Where Lights Meet (all Firefly) | Waiting Spark |
| 10 | Switchback, Brimming, Thicket | Switchback |
| 15 | Heartwood's Reach, Spotlight (F), Where Lights Meet (F) | Where Lights Meet |
| 20 | Lasting Dreams, Lanternway (F), Call of the Wild | Lanternway |
| 25 | Twig Walls, Guiding Light (F), First Light | Guiding Light |

A Firefly card was taken every time one was offered. Seven of the 15 cards shown were Firefly cards.

**The new rule for generic cards:**
- **Class cards make the build better at what it does. Generic cards change the run around it:**
  the maze, the economy, the tempo, the risk, or a weak spot the class has.
- **Good for every class.** A generic card must do something useful on a board of any of the four
  starters with only that family, Sprouts and Thornwalls. No generic card is keyed to one status
  or one family's mechanic.
- Held to the bar the class Commons passed: it changes where the player builds or how they play,
  and can be seen working. Conditional damage is allowed; flat damage is not.
- Class cards are not weakened.

**Order of work:** the Commons and Uncommons first, since they sit beside class cards in act 1
offers. Balancing is also asked how often class cards appear per offer.

### Audit and council pass on the generic Commons and Uncommons (2026-10-13; nothing built)

Audits: `generic_commons.md`, `generic_uncommons.md`. Reviews: `generic_roguelite.md`,
`generic_td.md`, `generic_player.md` (all in the work folder). Nothing was run; Dew figures are
paper arithmetic.

**The pool today.** 82 generic cards in the start pool: 45 Commons (keep 20, rework 17, retire 8)
and 37 Uncommons (keep 19, rework 13, retire 5). No generic card is a bet. No generic Common
answers a lone boss, elites or flyers. Ten of the 37 Uncommons fail "good for every class". Four
Uncommons are in every run's pool (`PLAIN_STAT_CARDS`) and three of them are plain numbers.

**Verdict of the council: the reworks alone do not fix the owner's complaint.** All three replayed
the five offers from the playtest with the reworked cards in the generic slots:
- Player: still the Firefly card every time; one hesitation in five.
- Roguelite: one real hesitation in five. "Most reworks fire once per nightmare while a class card
  works every second."
- Two of the five offers had no class-against-generic choice at all (three class cards; three
  generics).

**What the council agrees on**

1. **The offer mix matters more than any rework.** Seven of 15 cards shown were class cards. All
   three recommend **at most one class card per offer** (family cards stay at two in total;
   nothing reserved or weighted). About four offers in five would then hold exactly one class
   card. Balancing must check a direction still completes.
2. **Only about ten generics are "a different kind of card".** The player's list: Growth Rings,
   Seedfall, Snag, Press On, Held Breath, Call of the Wild, Thorny Walls, Long Way Round, Many
   Hands, Mulch. They change the run (Dew, leaves, ranks, the maze, the tempo). Most of the rest
   are combat tricks (a trigger, then a small hit, slow or crit) and read as class cards without
   the class.
3. **Tempo is the job that competes.** Press On, Call of the Wild, Quick Step and Head Start can
   stand beside a class card at drifts 5 and 15. Economy competes only at drift 5; weak-spot cards
   only just before a boss; tending is still weak.
4. **Weak-spot cards have no target in act 1** (read from the drift data): flyers appear in 9
   drifts, all from drift 31; act 1 has one elite, in drift 23; the demo has no fast walkers. So
   flyer and elite answers should be act 2 and later, and must not be always-in-pool basics.
   The player would only take one if the card shows what is coming and the player's own number.
5. **The generic Rares were not audited,** and the last offer of the playtest was decided by two
   of them (Twig Walls, First Light).

**Reworks and new cards that are too strong or exploitable**

| Card | Problem | Council fix |
|---|---|---|
| Growth Rings (a free rank every rest) | About 1,450 Dew over a demo run with no decision; better than two Uncommons | Split: retire (roguelite), cap at rank III (tower defence), "best card in either audit" (player) |
| Call of the Wild (40% more Dew, a leaf per clean block) | About 1,820 Dew plus 10 leaves from a Common | 20% to 40% more Dew and no leaf; or each leak from that drift costs 1 more leaf |
| Thorny Walls (1% of health per lash) | 60 walls take about 45% off any boss; cancels the health curve | Flat damage that grows with the drift, or once per wall per nightmare with a ceiling |
| Evergreen as a bet | Grow, take 40% back, sell at the rest for 75%: 115% back every block | Refund only on Wardens still standing at the next rest, or drop the rework |
| Fresh Growth as a burst | Sell, replant and regrow buys the burst again | Growing only, never planting; once per Warden per block |
| Many Hands | Plant and sell Sprouts beside a boss for +5% each | Count Wardens standing when the nightmare is dispelled, or cut |
| Long Way Round, and every per-bend card | Any half-cell jog counts as two bends, so bends are farmable | Define a bend as one full cell of straight path on each side |
| Hunter's Wager | Worth about minus 110 Dew in act 1; the player would not take it | Elites only, or cut |
| Heartwood's Reach | About 150 Dew: still too small | Merge Mulch into it |

**Wrong facts in the audits** (tower-defence reviewer, read from code): Bellflower can crit (5%),
so "starters cannot crit" is wrong; a forced crit on a Warden with no crit chance is ×2; the rest
bonus is 30 + 4 per block; `Enemy.ground()` already makes a flyer land and walk, so Snag is small
code.

**Recommended plan**

1. **Owner call: cap class cards at one per offer.**
2. **Build a short list of run-shaping generics first** (about ten, fixed as above), and make sure
   they are Commons and Uncommons that turn up in act 1.
3. **Retire the combat-trick generics** rather than rework them: Rush, Weary Feet, Edge of Sight,
   Deep Breath, Tripvine, Stung, Head of the Line, plus the 13 the audits already listed.
4. **Weak-spot answers are act 2 and later,** one per weak spot, and say what is coming.
5. **Replace the always-included basics** with one plain anchor per job, never a matchup answer.
6. **Audit the generic Rares** the same way.

### Owner rulings (2026-10-13)

1. **One class card per offer.** An offer of three holds at most one class card. Family cards stay
   at two in total. Nothing is reserved or weighted.
2. **Growth Rings stays, capped at rank III, and "you have to stop building your maze for it."**
   Read as a condition: the free rank is the reward for a block in which the player planted no
   Warden and no wall. Proposed text: "At a rest, if you planted nothing since the last rest, your
   block's top Warden gains a free Nurture rank, up to rank III." Growing and Nurturing still
   count as not planting. (If the owner meant only "ranks already cost you maze", the condition
   comes off and the cap alone stands.)

---

## 23. Run-shaping generic cards and the generic Rares (2026-10-13; nothing built, unreviewed)

Full specs in the work folder: `generic_final.md` (the batch, bets, weak-spot cards, retire list,
basics, pool counts) and `generic_rares.md` (the Rare and Legendary audit). Dew figures are paper
arithmetic.

### Facts found in code that change the picture

- **The drift 5 offer is class-only** (`CLASS_OFFER_UNTIL_DRIFT = 5` in `dream_state.gd`), and the
  drift 25 rest is Rare or better. So generic Commons and Uncommons can only appear at rests 10,
  15 and 20 in act 1: three offers. A class-only first offer was never asked for by the owner.
- **The one-class-card cap is not built yet.**
- **The always-included cards are `RUN_POOL_BASICS`** (quickened_sap, deeper_calm, longer_roots,
  deep_roots, thick_bark, evergreen, morning_dew). `PLAIN_STAT_CARDS` is the one-per-offer list.
  Earlier notes in this document mixed the two up.
- **Every bet, tempo card and "few Wardens" build among the Rares is Grove-only.** The start pool
  has 18 generic Rares and Legendaries: 4 maze, 9 "more of a build", 3 plain numbers, 1 risk
  (Bittersweet, so Grove-gated in practice), none for economy, tempo or tending. The Grove has 40.
- **The boss-rest "defining" slot is always generic** (no class card has the tag) and picks among
  four cards: Twig Walls, Root Network, Brimming, Heart of the Maze.

### The batch: 12 run-shaping generics for act 1

| Card | Rarity | Job | Text | Paper value over a demo run |
|---|---|---|---|---|
| **Growth Rings** | Common | Tending | At a rest, if you planted nothing since the last rest, your block's top Warden gains a free Nurture rank, up to rank III. | 170 to 600 Dew |
| **Heartwood's Reach** (Mulch merged in) | Common | Tending | Your next 5 clears are free. The first Warden planted on each cleared cell arrives at rank I. | |
| **Seedfall** | Common | Economy | Your first 2 Sprouts after each rest are free. Free Sprouts sell for nothing. | |
| **Winding Path** | Common | Economy | Your maze income is tripled. | The weakest of the twelve |
| **Call of the Wild** (bet) | Common | Tempo | Drifts you call early pay 25% more Dew. Each nightmare from one that gets through costs 1 more leaf. | 620 to 1,040 Dew |
| **Press On** (bet, new) | Uncommon | Tempo | Call 3 drifts of a block early and lose no leaf: your next Dream has 4 cards. | |
| **Fresh Growth** | Uncommon | Tempo | Grow or Nurture a Warden during a drift: it and every Warden touching it attack twice as fast for 8 s. | |
| **Held Breath** (bet, new) | Uncommon | Risk | Lose no leaf in a block: its rest bonus is tripled. Lose a leaf: it pays nothing. | Break-even at one clean block in three |
| **Dark Skies** (new) | Uncommon | Risk | You can no longer choose Clear Skies. Every Omen you see through pays 25 more Dew. | |
| **Thorny Walls** | Common | Maze | Thornwalls lash one nightmare beside them every second. The lash grows stronger every drift. | About 9% of the act 1 boss for 30 walls |
| **Cozy Corners** | Uncommon | Maze | The Warden on the inside of each bend deals 50% more damage. One Warden per bend. | |
| **Passing Thread** | Uncommon | Maze | Wardens deal 50% more to a nightmare the second time it passes them. | |

- **Growth Rings, made watertight:** the window runs from one rest's start to the next. Any plant
  ends it, including a free one or one made while paused; selling does not undo it. Growing,
  Nurturing and clearing are allowed.
- **Fresh Growth** is closed against sell-and-replant: Grow or Nurture only, on Wardens standing
  at the last rest, once per Warden per drift.
- **A bend** is one full cell of straight path on each side, so half-cell jogs don't count.

**Weak-spot answers, act 2 and later, never basics:**
- **Snag** (Uncommon, flyers): a flyer that crosses a Thornwall lands and walks the maze for 4 s.
  Once per flyer; each wall once a drift.
- **Long Way Round** (Uncommon, bosses and elites): bosses and Deeply Blighted nightmares take 4%
  more damage for each bend behind them, up to 40%.

Both cards print what is coming and the player's own number.

### Retire from offers (25 ids, kept for old saves)

The audits' 13, plus rush, weary_feet, edge_of_sight, stung, head_of_the_line, close_guard,
watchful_rest, glinting_dew, deeper_calm, quickened_sap, mulch (merged) and lantern_glow.
Blockers are listed per card in the spec (two are in `RUN_POOL_BASICS`, two are bases of successor
pairs, one is named in seven tests). The generic Common and Uncommon pool goes from 82 to 62.

**Basics after the change:** longer_roots, morning_dew, thick_bark stay; quick_step and
tender_care join; evergreen moves to the random pool.

### Generic Rares

- **Keep:** Twig Walls, Root Network (and II), Borrowed Branch, the Kinship cards, Quick
  Reactions, Dawnbreak.
- **Rework:** First Light becomes a maze card (double damage for a nightmare's first 2 s in a
  Warden's reach, and again each time it re-enters). Thinning the Herd becomes a boss and elite
  answer for act 2. The Long Walk gets a +60% cap (it has none). Steadfast moves to Uncommon.
  Hunter's Moon gets clearer text. Brimming needs two statuses on the map and act 2: it is pure
  gain for Sporeling and a trap for Dewdrop and Bellflower, where "full" takes twice as long.
- **Retire:** Heart of the Maze (Solitude does it better at Uncommon), Shared Mycelium.
- **Four new Rares, each defining a way to play:**
  - **Hot on Their Heels** (tempo): +10% damage per early call until the rest, up to +40%; a lost
    leaf clears it.
  - **A Clean Night** (risk): a clean block gives 1 Dreamlight; any leaf lost means no rest bonus
    at that rest.
  - **Front Line** (maze, a bet): nightmares take 40% more damage in the first half of the route
    and 20% less in the second.
  - **Tall Hedges** (maze and flyers, act 2): flyers follow the path, 30% faster.

### Calls for the owner

1. **The class-only drift 5 offer.** Keep it, or make the first offer mixed like the rest? It is
   why the playtest's first offer was three Firefly cards.
2. **Grove exclusives.** Press On is the Grove's Second Wind, and the Seedfall rework is the
   Grove's Seedling Gift doubled. Either the Grove gives them up or the start pool needs different
   cards. More widely: every bet and tempo Rare is Grove-only, so a fresh profile has none.
3. **Wagers in the start pool.** Held Breath, Call of the Wild, A Clean Night and Front Line have a
   stake but are not tagged Bittersweet, which would lock them behind the Grove node and act 2.
4. **Seeing the batch.** With three generic rests in act 1 and about 55 eligible generics, a
   player sees one or two batch cards before the first boss. Should the batch always be in the
   run's pool (as the basics are)? That is a pool rule, not a weighted offer.
5. **Monoculture** (Grove): now +100% damage for any one-family board that simply never adds a
   second family.

### Owner rulings on section 23 (2026-10-13)

1. **The class-only drift 5 offer stays.**
2. **New players get meaningful choices too:** *"want basic cards to have a meaningful choice as
   well for new players."* The start pool has its own run-shaping cards and bets; a fresh profile
   is not waiting on the Grove for them. Grove exclusives stay exclusive, so the two start-pool
   cards that copied them must change: Press On (the Grove's Second Wind: "Call 4 drifts of a
   block early: the next Dream offers 4 cards, one Rare or better") and the Seedfall rework (the
   Grove's Seedling Gift: "At every rest, gain a free Sprout charge").
3. **Wagers without the Bittersweet lock:** the owner asked for a view. Recommendation recorded
   here, to confirm: a **wager** (a stake the player can win or lose by how they play) is a
   different thing from a **Bittersweet** card (a permanent price paid whatever happens). Wagers
   belong in the start pool, unlocked, from the drift 10 rest. Bittersweet stays behind its Grove
   node and act 2. At most one wager per offer, each marked with a visible "Wager" line that
   states the stake, so a new player sees the risk before taking it.
4. **The batch is always in a run's pool,** like the basics, and is never guaranteed to be seen.
5. **Monoculture is fine as it is.**

---

## 24. Council pass on the generic batch and Rares; the consolidated batch (2026-10-13; nothing built)

Reviews: `batch_roguelite.md`, `batch_td.md`, `batch_player.md` in the work folder. Nothing was
run; Dew figures are paper arithmetic.

### Verdict

**Better, not yet ready for a build prompt.** The player as a new player: "partly"; about half the
offers now hold a real class-against-generic choice, two hesitations in three mixed offers.
Roguelite: a class-against-batch offer turns up about once per act 1, and one run in four has
none, because the 12 batch cards are a third of the eligible generics.

### Findings that change things

- **The working files contradict the owner.** The uncommitted `dream_state.gd` has the
  one-class-card cap (good) but has deleted the class-only drift 5 offer, which the owner ruled to
  keep. It needs restoring.
- **"Called early" is free in code:** a press one second before a drift finishes arriving counts
  (`drift_director.gd`). Every tempo card needs "at least 10 s of arrival skipped".
- **"No leaf lost" must read leaves actually lost,** not the `perfect` flag, which any leak sets
  even when Hardened Bark absorbs it.
- **Clearing is locked until a clearing card is taken,** so Heartwood's Reach is the clearing
  opener; its text should say so.
- **Thorny Walls is unbounded against packs:** 30 walls deal about 70% of a drift 20 stream's
  health. It needs a ceiling per nightmare.
- **Passing Thread and the reworked First Light were the same card.** One keeps the re-entry.
- **Tall Hedges** removes flyers as a threat and does nothing in most drifts: cut.
- **A wager is only a wager if the player can stop paying by playing differently.** Dark Skies and
  Front Line are permanent prices and need a "Price" line, not a "Wager" line. Held Breath, A Clean
  Night and Deep Sleep all stake the same rest bonus and must exclude each other.
- **New-player words:** "maze income", "Omen", "Clear Skies" and "see through" are unknown at
  drift 10 (the first Omen screen comes after that Dream). Call of the Wild's leaf penalty on a
  Common that reads as a Dew card "would put me off the game".
- **Growth Rings:** the player would not notice losing it. It needs a confirm on the first plant
  and a line in the rest report.

### The consolidated batch (recommendation)

Always in a run's pool; never guaranteed. Every number unchecked.

| Card | Rarity | Job | Text |
|---|---|---|---|
| **Growth Rings** | Common | Tending | At a rest, if you planted nothing since the last rest, your block's top Warden gains a free Nurture rank, up to rank III. |
| **Heartwood's Reach** | Common | Tending | You can clear obstacles. Your next 5 clears are free. The first Warden planted on each cleared cell arrives at rank I. |
| **Seedfall** | Common | Economy | Sprouts always cost 10 Dew: their price no longer climbs. |
| **Winding Path** | Common | Economy | The Dew your maze pays at each rest is tripled. |
| **Call of the Wild** (wager) | Common | Tempo | Drifts you call early pay 25% more Dew. Lose a leaf in one and it pays no bonus. |
| **Press On** (wager) | Uncommon | Tempo | Call 3 drifts of a block early and lose no leaf: regrow 1 leaf. |
| **Fresh Growth** | Uncommon | Tempo | Grow or Nurture a Warden during a drift: it and every Warden touching it attack twice as fast for 8 s. |
| **Held Breath** (wager) | Uncommon | Risk | Lose no leaf in a block: its rest bonus is tripled. Lose a leaf: it pays nothing. |
| **Thorny Walls** | Common | Maze | Thornwalls lash one nightmare beside them every second. The lash grows stronger every drift. |
| **Cozy Corners** | Uncommon | Maze | The Warden on the inside of each bend deals 30% more damage. One Warden per bend. |
| **Passing Thread** | Uncommon | Maze | Wardens deal 50% more to a nightmare the second time it passes them. |
| **Switchback** (existing, unchanged) | Common | Maze | Nightmares rounding a bend in an attacking Warden's reach are slowed by 25% for 1 s. Once every 3 s each. |

- **Changed from section 23:** Seedfall and Press On no longer copy the Grove's Seedling Gift and
  Second Wind. Call of the Wild stakes its own bonus, not leaves. Cozy Corners is 30%. Dark Skies
  leaves the batch for act 2 with a "Price" line and +50 Dew. Switchback joins (the one generic
  the owner took).
- **Rules behind the texts:** an early call needs 10 s of arrival skipped. Thorny Walls is 3 ×
  the drift's growth with a ceiling per nightmare. A bend is one full cell of straight path on
  each side. Passing Thread counts stretches of route, so a serpentine's lanes count and a pull-back
  does not. Growth Rings asks for a confirm on the first plant and reports "lost" at the rest.
- **Wager line** on the three wagers, one format with the player's own numbers: "Stake: this
  block's 46 Dew. Win: 138." At most one wager per offer.

**Act 2 and later:** Snag (only Thornwalls touching an attacker), Long Way Round (2% a bend, up to
40%), Dark Skies (Price).

**Rares:** First Light stays a first-hit card (once per Warden and nightmare, counted by source so
Poisoned ticks count). Brimming needs two statuses on the map and act 2. New: Hot on Their Heels;
A Clean Night (two clean blocks in a row give 1 Dreamlight; the demo only has about 4 Dreamlight
to spend); Front Line at ±30% with a Price line. Tall Hedges is cut. The run's Rare sample goes
from 6 to 12 so a fresh profile's drift 25 offer can hold one of these.

**Retire:** the 25 ids in section 23, unchanged. Swift, precision and reach tags each drop to four
live cards; check the fog nightmares before retiring Lantern Glow.

### Open calls for the owner

1. Confirm the wager rule (section 23, ruling 3) with the "Price" label for permanent costs.
2. **Thin the other generics in act 1?** The batch is 12 of about 36 eligible act 1 generics, so a
   player sees two or three of them before the first boss. Holding the leftover non-batch generics
   to act 2 would make the batch about half of generic slots. It is a pool rule, not a weighted
   offer.
3. Press On's reward is a leaf. Up to one a block; Balancing should check it against the leaf
   economy.

### Owner rulings on section 24 (2026-10-13)

1. **Wagers:** confirmed as recommended. Wagers sit in the start pool with a visible "Wager" line
   in the player's own numbers, at most one per offer; permanent costs carry a "Price" line.
2. **The other generics are NOT held back to act 2.** *"Isn't that too little, don't want to be
   seeing the same offers every [playthrough]."* Variety comes first. The batch stays always in
   the pool beside the full generic pool; the way to see more run-shaping cards is to write more
   of them over time and retire the weak ones, not to shrink what act 1 can offer.
3. **Press On's leaf reward:** explained to the owner; pending.
4. **Wager and Price lines: yes.** **Press On gives a leaf back: yes** (up to one a block; for
   Balancing to check). **"Jumps" replaces "fork"** in all player-facing Firefly text, with "at
   half damage" for "for half". The owner also approved committing this document.
