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

## 12. Built on 2026-10-11 (uncommitted)

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
