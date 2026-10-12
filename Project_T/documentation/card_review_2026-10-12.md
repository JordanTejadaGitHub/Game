# Dream card review — 2026-10-12

Owner: design hub (story chat). A read-only review of every active Dream card after the Codex pass and the
Callings commit (67940fac): 252 build cards (the 251 listed plus `dream_residue`) and 116 form-unlock cards.
Nothing was run. Findings come from reading the card files and the code; each needs its owner's check before a fix.
Owners: card data and Dream rules = Roguelite Code; Warden data and attack code = Tower Code; Grove nodes = Meta Game
Code; decisions = the user.

Counts: build cards 116 clean / 135 flagged (most for wording); unlock cards ~72 clean / ~45 flagged. Every rule id
is read somewhere in `scripts/`; no active card needs, deepens or excludes a retired card; no card triggers on
trample.

## 1. Exploits and uncapped effects
| Card | Problem | Suggested fix |
|---|---|---|
| `fresh_growth` | +50% to anything planted or grown during a drift, until the rest. Sell the maze at a rest (full refund), replant one second into the drift: the whole board has +50% every block. Maze juggling. | Grown only (not planted), or once per Warden per block. |
| `rooted_bond` | Rewards selling and replanting a bonded Warden. | Retire, or keep only as "moving keeps the bond" via Memory Seed. |
| `the_last_light` + `rootbound` + `whirlwind_heart` | Two Legendary +100% attack speed cards and a card that doubles every attack-speed bonus: about ×5, no cap. | Cap the total attack-speed bonus, or Whirlwind Heart skips Legendary bonuses. |
| `rooted_nightmares` | Every 8th hit Roots, no per-nightmare cooldown: fast multi-hit Wardens near-permanently Root. | Per-nightmare cooldown. |
| `spore_cascade` | Copies all Poisoned stacks to 2 nightmares on every dispel; snowballs through a drift. | Half the stacks. |
| `winding_path` (Common) | Uncapped Dew each rest for covered path, on top of the new maze bonus for the same behaviour. | Cap it, or raise the rarity. |
| `drumbeat` | No limit on how much neighbours shorten a cooldown (code review, 2026-10-11). | One trigger per attack. |
| `sunlit_rest` + `fresh_beginnings` | Two free ranks a rest together. | Watch in play. |

## 2. Text that doesn't match the game
| Card | Text | Game |
|---|---|---|
| `thorny_walls` | "for a Sprout's damage" | fixed 5 (a Sprout deals 12) |
| `second_wind` | "every drift of a block" early | 4 of 5; it also forces a Rare+ into the next Dream |
| `call_of_the_wild` | double Dew "up to 40" | the doubling caps at 20; the 40 is a separate per-dispel bonus |
| `heartwoods_reach` | "3 half-price clears on top" | reads as a contradiction with "clearing costs half" |
| `many_threads` | Caught from 16 Drowsy | 32 with Brimming, unsaid |
| `last_breath` | no boss limit stated | 5% cap on bosses |
| `dream_rootlight` | nightmares in the light are Exposed | applies no status; Rooted lasts longer there, Hidden shown |
| `dream_whirligig` | "nudges nightmares back" | copies a status; no knockback |
| `dream_starling_murmuration` | three starlings | five |
| `dream_boulderback` | splashes half | 75%; omits double damage on Exposed |
| `dream_old_lichen` | "at 8 Poisoned" | 32 |
| `dream_lullaby_bell` | sets off "like Chime Stone" | 16 vs 12 |
| `dream_jarlink` | within 4 cells | 4.5 |
| `dream_frostfern` | freezes Soaked nightmares | needs 8 Soaked |
| `dream_beacon`, `dream_lanternmoth` | Exposes at once | builds by stacks |
| `dream_acorn` | "damages everything around it" | throws bouncing acorns; omits its aura |
| Warden text: `chime_stone` "3 or more", `lullaby_bell` "4 or more", `hoarfrost` "Soaked twice", `puffball` "up to 16", `frostfern` says Rooted, `dreamcatcher` "Asleep" only | | now 12 / 16 / 8 / 64 / Frozen / also full Drowsy |

Fix for all number cases: read the number from the data with a `{field:…}` token.

## 3. Offered but does nothing
- Needs a crit Warden but has no such requirement: `hobble`, `opening_fracture`, `steady_aim` (Common, start pool), `shattering_blow`, `sharpened_light`. Most of the roster has no crit.
- Wrong requirement: `eddy` and `ill_wind` require Whirligig but only change Gust / Zephyr; `deep_water` requires Dewdrop but needs Drowsy too.
- No Kinship requirement: `twin_strike`, `spore_kin`, `shared_training`, `close_quarters` (also missing its discovery gate).
- `wildwood_reclaimed` (Legendary) has no minimum obstacle count; `wake_ripple` needs Drowsy and the Drown discovery, which no starting family gives.
- `deep_sleep` removes Omens, which kills `double_or_nothing`: exclude each other.
- Start-pool cards for Grove-only families, inert on a fresh profile: `chorus`, `resonance`, `murmur`, `homing_instinct`, `eddy`, `ill_wind`, `spinning_corners`, `falling_weight`, `warm_hearth`, `lullaby`, `long_light`.
- Deepened cards are sampled into the run's pool separately from their base (`root_network_ii`, `rolling_thunder_ii`, `guiding_light_ii`, `tender_care_ii`): a II can take a pool slot while its base is out.
- Woven cards (8, all Rare though the script says Legendary): each needs three specific forms from three families; about a 6% chance the branches even appear in a run.
- `quiet_vigil` and `afterroot` add 3 and 2 Exposed stacks; Exposed needs 10.

## 4. Tiny effects (against "fewer, bigger cards")
`kins_keepsake` (1 Dew per Kinship a drift), `emergency_reserves` (8 Dew, and it pays for leaking; `close_shave` too),
`cheap_seeds`, `groundskeeper`, `weed_puller`, `weathered_walls`, `seedfall`, `early_bird`, `bountiful`,
`growth_rings`, `lullaby` (+1 s Caught), `patient_roots` (+0.5 s Rooted), `prism_heart` (+0.5 cells), `hedge_maze`,
`grand_tour` (+1 s), `corner_sign`, `crossed_sparks`, `first_frost`, `thorn_snare`, `undergrowth`, `wide_swing`,
`steady_roots`, `weary_feet`, `moonflip` (averages +5%), `glimmering_hunt`, `rolling_thunder_ii` and
`root_network_ii` (barely more than their base), `thinning_the_herd` (Rare, 2% a dispel), `canopy` (Rare, +1 range
under a hard condition).

## 5. Rarity out of line
- Too strong for its tier: `lasting_dreams` (Common: statuses last twice as long), `bright_marks` (Common: Exposed 25% → 55%), `call_of_the_wild` (Common).
- Weak Legendaries: `crossroads` (+40%, beaten by Uncommon `cozy_corners`), `full_moon` (+10% crit), `briar_crown`, `restless_night`, `the_old_ones` (+1 effective rank; Uncommon `specialist` does more), `wildwood_reclaimed` (weaker than Uncommon `solitude`).
- `lantern_glow` (Common) is a flat +15% to everything.

## 6. Overlaps
| Same idea | Cards | Keep |
|---|---|---|
| Hit by two Wardens within a second | `overlap`, `crossfire`, `opening_fracture`, `crosswind`, `twin_strike`, `murmur` | `overlap`, `crossfire`, `murmur` |
| Two Wardens add the same status | `crossed_sparks`, `shared_mycelium` | both, but the text is identical |
| Every Nth attack repeats | `flurry`, `rhythm`, `twin_puff`, `glinting_dew`, `wide_swing` | one generic |
| Idle, then a charged hit | `watchful_rest`, `quiet_vigil`, `patient_aim` | `watchful_rest` |
| Call a drift early (7 cards) | `early_bird`, `bold_opening`, `call_of_the_wild`, `quick_step`, `head_start`, `restless_night`, `second_wind` | cut `early_bird`; merge two |
| A wall touches the first passer | `thorn_snare`, `hushed_hedge` | one |
| Damage on cleared ground | `mulch`, `wildwood_reclaimed`, `reclaimed_earth` | `mulch` + the Legendary |
| Statuses jump on dispel or switch | `passing_dream` (Common), `spore_cascade` (Rare), `passing_thread`, `wake_ripple` | the Common nearly covers the Rare |
| Flat damage for a price | `deep_sleep` +80%, `thin_bark` +75% | one |
| Dew each rest | `morning_dew`, `harvest_moon` | `morning_dew` |

## 7. The set as a whole
- Rarity: Common 65, Uncommon 96, Rare 70, Legendary 20. **Start pool has 2 Legendaries** (`hunters_moon`, `dawnbreak`, which needs a 10-chain): a new player's Legendary is always Hunter's Moon. The Long Walk was retired.
- Every card has one stack; 228 of 251 are rule cards.
- Family cards (single family): Whirligig 11, Firefly 7, Bellflower 7, Nestling 6, Acorn 5, Sporeling 5, Rootling 4, Dewdrop 4, Pebbling 3, walls 3 (none in the start pool). Cards name only the older branches; the newer ones (Lichenling, Inkcap, Jarlink, Sparkler, Cloudlet, Jetreed, Whetstone…) have none.
- At the first Dream a fresh player has one family and about 50 offerable cards: plenty of Commons and Uncommons, few Rares, 1–2 family cards.
- Offer rules in code: rarity weights 65/28/7/0 (act 1), 50/32/15/3, 38/34/22/6; boss rests are Rare+ with one guaranteed defining card; at most 1 Legendary; a pity Rare after 3 dry offers; no family weighting; no card guaranteed except the run pool's 7 basics + `heartwoods_reach`. `restless_dreams` (Waking Dreams: the next Dream offers 3 Legendaries) and `second_wind` (forces a Rare+) are the only cards that steer an offer.
- Grove: three paid nodes give nothing (`golden_harvest` 120, `menagerie` 80, `light_feet` 60; the code blocks buying them); `bitter_hedges`, `sharpened`, `thorn_and_bramble`, `whirligig_hidden` still list retired cards. Three final forms are in the start pool unlike every sibling: `dream_moonstone`, `dream_lullaby_bell`, `dream_great_dreamcatcher`.
- All nine Blessings are retired, Stone Relay / Stored Rain / Spore Reserve included (67940fac). CLAUDE.md still lists them as live.

## 8. Wording (rewrites, same mechanics)
Code words to remove everywhere: "primary attack target", "Aiming Wardens", "Light Wardens", "count as lightning",
"affected output", "Quiet Wardens", "Potency" / "Effects" without a definition, "leak", "sniper", "mortar", "ramps".
- `drumbeat`: "A Warden touching 2 or more attackers attacks sooner: each time two different neighbours attack, its next attack comes 35% sooner."
- `canopy`: "A group of 6 or more touching attackers gets +1 range while it is fighting 6 or more nightmares."
- `grand_tour`: "A new status on a nightmare makes its other statuses last 1 s longer (once each; not Rooted or Asleep)."
- `crossfire`: "When two Wardens hit a nightmare within 1 s, the next nightmare behind it (within 2 cells) takes 40% of the weaker hit."
- `brimming`: "Nightmares hold twice as many stacks of every status. Reactions need twice the buildup and hit 2.2 times as hard."
- `old_growth` (Steadfast): "A Warden that has stood 5 drifts stops each new target for 0.4 s with its first hit (once per nightmare every 4 s; not bosses). Selling resets it." (Its "Pinned" clashes with the Pinned Reaction.)
- `passing_thread`: "When a Warden changes target, it carries 1 stack of the old target's biggest status to the new one (every 2 s per Warden)." Add a tag.
- `quickened_sap` (Target Turnover): "A Warden that changes target attacks 35% faster for 3 s."
- `heart_of_the_maze`: "The attacking Warden furthest along the path from any other attacker deals double damage. Ties: the one nearer the Heartwood."
- `lucid_dream` (Borrowed Branch): "Pick one of your families: unlock one of its branch Wardens you haven't found this run, free."
- `shared_training`: "Two Wardens in a Kinship that both made the same Nurture choice four times gain that choice's rank V reward at rank IV."
- `the_quiet_ones`: "Wardens that don't attack are 50% stronger: their auras, their damage, and the speed of their Drowsy scent. Catcher income and Dreamcatchers are unchanged."
- `venom_bloom`: "Status and Reaction damage is doubled." `seeping`: "Status and Reaction damage is 8% higher for each status on the nightmare (up to +40%)."
- `starlit_aim`: "Every Warden has +25% crit chance against nightmares at full Exposed stacks."
- `scented_hedge`: "A Thornwall touching a Honeysuckle also makes nightmares beside it Drowsy, at half strength."
- `needle_point`: "Hummingbird Bower pecks ignore the dread shell." `rain_on_glass`: "The Firefly Jar line deals 70% more damage to Soaked nightmares." `resonance`: "Chime Stone pulses add 2 Charged stacks to each nightmare they hit." `hairpin_winds`: "Pinwheel and Windmill gain their per-path-tile bonus from 1 more tile."
- Name the Warden: `backspin` (Samara's returning seed), `encore` (Echo Hollow), `conductive_soil` (Stormcap), `windborne_rain` (Samara seeds), `dew_trail` (Dewcatchers, not "Catchers").
- Unlock cards that don't say what the form does: `dream_dream_oak`, `dream_pebbling`, `dream_crown_of_thorns`, `dream_thorncoil`, `dream_earthbind`, `dream_vesper_bell`, `dream_grove_keeper`, `dream_torrent`, `dream_mother_log`, `dream_nurse_log`, `dream_rain_lily`, `dream_driftspore`: reuse the Warden's own sentence.
- Tokens missing: plain status words in `brimming`, `the_quiet_ones`, `many_threads`, `dream_dreamcatcher`, `dream_great_dreamcatcher`, `dream_hushbell`; plain "rest" / "block" / "drift" in `moonflip`, `double_or_nothing`, `kins_keepsake`; raw Dew numbers in `endless_rings`, `deep_well`, the `cheap_seeds` caption; "neighbors" in `cheap_seeds` and the Graftling Wardens.
- Ids that differ from their names (lookups go wrong): `deeper_calm` = Clear Minds, `old_growth` = Steadfast, `quickened_sap` = Target Turnover, `rhythm` = Fifth Beat, `cheap_seeds` = Scattered Seedlings, `dew_line` = Last Collection, `restless_dreams` = Waking Dreams, `restless_night` = Impatient Night, `lucid_dream` = Borrowed Branch, `lullaby` = Slow Waking, `resonance` = Thunder Chimes.

## 9. Decisions for the user
1. Tiny cards (section 4): enlarge, merge or retire?
2. Weak Legendaries (section 5) and the 2-Legendary start pool: bring The Long Walk back, or move one Grove Legendary to the start?
3. Overlaps (section 6): cut to one per idea?
4. `restless_dreams` (Waking Dreams) and `second_wind` steer the next Dream: keep as the two exceptions, or change?
5. The three empty Grove nodes: remove, or give them new cards?
6. Newer branches with no cards: write a card for each, or leave?

## 10. Proposal for the 17 tiny cards (drafted 2026-10-12; numbers are starting points for Balancing)
Rule: merge where cards share a theme, enlarge the ones with a clear identity, retire what has no idea of its own.
Result: 17 cards become 10 (7 retired or merged away).

| Card | Now | Proposal |
|---|---|---|
| `early_bird` (Common) | calling a drift early gives +5 Dew | **Retire.** `call_of_the_wild` already doubles early-call Dew; seven cards share this trigger. |
| `emergency_reserves` (Common) | 8 Dew the first time leaves are lost in a block | **Retire.** It pays for leaking and is too small to matter. |
| `moonflip` (Uncommon) | coin flip each rest: +25% or −15% damage | **Retire.** No decision, averages +5%. |
| `weed_puller` (Common) | clearing a Mossy Boulder refunds 6 Dew | **Merge into Groundskeeper**, retire. |
| `groundskeeper` (Common) | +3 Dew at a rest per obstacle cleared that block | **Enlarge:** "Clearing an obstacle gives back half its cost." (6–9 Dew each, at once, every kind.) |
| `wide_swing` (Common) | every 3rd area attack is 0.75 cells wider | **Merge into Wide Petals**, retire. Wide Petals becomes "Splashes, pulses and clouds reach 0.75 cells wider." |
| `kins_keepsake` (Uncommon) | 1 Dew per Kinship each drift, at most 6 | **Enlarge and simplify:** "At each rest, +10 Dew for every Kinship on the map (up to 40)." |
| `cheap_seeds` / Scattered Seedlings (Common) | Sprouts not touching another Sprout cost 4 less | **Enlarge:** "A Sprout planted away from other Sprouts costs half." The spread-out answer to Undergrowth's cluster. |
| `undergrowth` (Common) | Sprouts touching 2+ Sprouts reach 0.5 cells further | **Enlarge:** "Sprouts touching 2 or more other Sprouts get +1 range." (2.5 → 3.5.) |
| `growth_rings` (Common) | each Nurture rank also gives +0.1 range | **Enlarge:** "Each Nurture rank gives +0.25 range instead of +0.1." (Rank V: +1.25 cells, was +0.5.) |
| `patient_roots` (Uncommon) | Rooted lasts 0.5 s longer | **Enlarge:** "Rooted lasts 1 s longer (bosses 0.25 s)." Doubles a normal Root; bosses stay bounded. |
| `lullaby` / Slow Waking (Uncommon) | Caught lasts 1 s after leaving a Dreamcatcher | **Enlarge:** 3 s. |
| `thorn_snare` / Briar Trap (Uncommon) | each Thornwall Roots the first nightmare beside it for 0.5 s, once a drift | **Enlarge:** 1.5 s. Keep it and Hushed Hedge mutually exclusive (same trigger). |
| `corner_sign` (Uncommon) | +1 status stack after a bend, once per bend | **Enlarge:** "After a nightmare passes a bend, each Warden's first status hit on it applies double stacks." Scales with the new high caps. |
| `crossed_sparks` (Rare) | two Wardens add Charged within 2 s: +2 stacks | **Enlarge:** +6 (Charged now needs 20). `shared_mycelium` likewise: +6 Poisoned (cap 32). |
| `prism_heart` (Rare, Woven) | Prismstorm shards fly 0.5 cells further, +3 Charged | **Enlarge:** "Prismstorm shards fly twice as far and add 8 Charged stacks." A Woven card is hard to reach; it should be worth it. |
| `grand_tour` (Rare) | a new status adds up to 1 s to the others, once | **Rework:** "A nightmare carrying 3 or more different statuses takes 30% more damage from every Warden." The reward for a real multi-status build; different from Seeping (status damage only) and Lasting Dreams (duration). |

## 11. Proposal for the open decisions (drafted 2026-10-12, waiting for the user)
**A. A new player's Legendaries.** Un-retire `the_long_walk` (start pool, the user's 2026-10-06 decision): three start
Legendaries instead of two.

**B. Weak Legendaries, enlarged** (starting numbers for Balancing):
| Card | Now | Proposed |
|---|---|---|
| `crossroads` | +40% for a Warden touching two far-apart path tiles | double damage |
| `full_moon` | +10% crit chance for all | +25%; crit above 100% still becomes crit damage |
| `briar_crown` | a nightmare beside a Thornwall takes 25% of the strongest touching Warden's damage | 60% |
| `restless_night` (Impatient Night) | +40% while two early-called drifts overlap | double damage while they overlap |
| `the_old_ones` | Wardens touching a rank V Warden count one rank higher | two ranks higher |
| `wildwood_reclaimed` | +30% on cleared cells, +2% per obstacle cleared (up to +60%) | +50%, +3% per obstacle (up to +100%) |

**C. Overlaps: cut only what another card clearly covers.**
- Retire `twin_strike` (Kinships already have their own bonuses; Overlap and Crossfire cover the trigger).
- Retire `harvest_moon` (+15 Dew a rest; Common Morning Dew gives more).
- Retire `quiet_vigil` (same trigger as Watchful Rest, weaker payoff). This replaces the "5 stacks" fix in section 3.
- `reclaimed_earth` loses its "refunds 40%" line: Groundskeeper now gives half back. It keeps the half-price first Warden and the Sprout damage.
- `flurry` and `rhythm` (Fifth Beat) exclude each other (every 5th attack repeats, twice over).
- Keep the six call-early cards as the "daring" build, the idle pair Watchful Rest / Patient Aim (damage vs crit), and both Bittersweet damage cards.

**D. Cards that steer the next Dream.** Keep `restless_dreams` (Waking Dreams) and `second_wind` as the two exceptions:
they promise a rarity, never a named card, and both are paid for.

**E. The three empty Grove nodes** (`golden_harvest` 120, `menagerie` 80, `light_feet` 60). Remove them from the tree
(88 nodes); nothing depends on them. Meta Game Asset tidies the three twigs. No refunds (pre-release).

**F. Newer branches with no cards.** Not now. After the next playtests, one card per branch as its own batch
(Roguelite Mechanic Discussion designs it).

**G. Paused tutorial cards.** Keep: they are the Lessons the user asked for on 2026-10-06 ("learning new things should
pause and put a text up"), extended with a three-card opening that has Skip. onboarding.md's older "no tutorial
windows" line is the one to retire.
