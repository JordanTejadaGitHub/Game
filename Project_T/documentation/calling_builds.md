# Calling builds

Every build a player can make from the starting Calling, its evolutions and the Dream cards that fit.
Compiled 2026-10-19 from the working tree: `scripts/combat/calling_paths.gd` (with the uncommitted wording pass),
`scripts/combat/callings.gd`, the live cards in `resource/dream/` (no `retired = true`), `dream_batch_rules.gd` and
`RUN_POOL_BASICS` in `dream_state.gd`. Judgement and playtest numbers reuse `D:\Projects\logs\dream_council\build_reference.md`
and `lent_evolution_builds.md`. Read-only research; nothing was run.

---

## 1. How to read this

- **A build** = the starting Calling + one style + that style's evolutions + the cards that pay it. There are 12:
  4 Callings × 3 styles (Spread, Focus, Support).
- **Lent cards** belong to a family. Any player who owns that family can be offered them, so the first family's lent
  cards are your build's core, and the second family's lent cards are your "partner" cards.
- **Generic cards** have no family. "Always in pool" = the 12 batch cards and the 6 basics (section 1.2). Cards marked
  **(Grove)** are not in the start pool: they only show up once planted or discovered.
- Rarity: C / U / R / L = Common / Uncommon / Rare / Legendary. "Act 2" = offered from drift 26.
- **Partner ratings:** strong = the two families feed each other with Commons or Uncommons; works = one or two links;
  thin = little connects.
- **Numbers are quoted from the data.** Every "expected stop" and every Dream panel share is a **target, unmeasured**
  unless a human run is named.
- Status words: Soak, Poison, Charge, Sleep (Drowsy), Exposure, Root. A nightmare at full Sleep is asleep.

### 1.1 The timeline

| When | What happens |
|---|---|
| Drift 1 | First family pick. Its Calling is set for the whole run. |
| Drift 5 rest | Choose a style: Spread, Focus or Support. This replaces that rest's Dream. |
| Rests 10, 15, 20 | One Dream each. Omens start at 10. |
| Drift 25 (act 1 boss) rest | One follow-up of your style. Second family pick; that rest's Dream holds one lent card of the new family. |
| Rests 30–40 | One Dream each. At most 2 family cards per offer. |
| Drift 45 rest | The capstone of the follow-up you took (moved from 50 on 2026-10-19, so the demo plays it for its last block and the act 2 boss), plus that rest's Dream. |
| Drift 50 rest | Act 2 boss rest. **The demo ends here.** |
| Drift 75 rest | The style's other follow-up (full game only). |

- Evolutions only deepen. You never switch style.
- No reroll, let-go or "let it pass" on an evolution pick.
- The capstone follows the follow-up you took at 25. At 75 you get the other follow-up, but never its capstone.
- Test Grove and "Unlock all families" never set a Calling, so these builds only exist in a normal run.

### 1.2 Generic cards always in the pool

| Card | Rarity | What it does | Fits |
|---|---|---|---|
| Winding Path | C | Maze bonus at each rest doubled. | Every Spread build (long routes). |
| Switchback | C | Nightmares rounding a bend in range slowed 25% for 1 s. | Every build; an answer to fast streams. |
| Thorny Walls | C | Each Thornwall hits a touching nightmare every second. | Maze-heavy Spread builds. |
| Seedfall | C | Sprouts always cost 10 Dew. | Glowworms, Borrowed Spores, Riverside, Accompaniment. |
| Growth Rings | C | Plant nothing for a block: its top Warden gets a free rank, up to III. | Focus builds (few, strong Wardens). |
| Call of the Wild | C | An early-called drift holds +1% Dew per second skipped, up to +30%. | Any. |
| Heartwood's Reach | C | Clearing opener: 5 free clears; first Warden on each cleared cell is rank I. | Any. |
| Cozy Corners | U | The attacking Warden inside each bend deals 30% more. | Focus builds with a kill zone at a bend. |
| Passing Thread | U | Wardens deal 25% more to a nightmare from the second time it passes them. | Spread builds. |
| Fresh Growth | U | Grow or Nurture during a drift: it and touching Wardens attack 100% faster for 8 s. | Any. |
| Press On | U | Every 5th early call regrows a leaf. | Any. |
| Nipped in the Bud | U | Dispels before halfway pay 20% more Dew. | Builds that kill early on the path. |
| Back-row Roots, Deep Roots, Hardened Bark, Morning Dew, Quick Step, Tender Care | C | The basics: range, leaves, Dew, tempo, Nurture. | Any. |

---

## 2. Spore Print (Sporeling)

> A nightmare dispelled with Poison leaves a mushroom on the path. The next nightmare to step on it takes a dose:
> 3 stacks of Poison.

- Any Warden's dispel counts. Mushrooms stay through a rest; 40 at most.
- **Flyers pass over mushrooms.** Every Spore Print build is weak to flyers.
- Sporeling lent cards (10): Breathe It In (C), Pass It Round (C), Spore Huddle (C), Fruiting (C), Mycelium (U),
  Overnight (U), Settling Spores (U), Parting Puff (U), Gone to Seed (R), Mixed Company (R). None of them names mushrooms
  or doses: most make every status stack faster; Fruiting and Parting Puff pay plain hits (non-status builds).
- **Overnight** is offered only once the run has a second family.

### S1 Windblown carpet (Spread)

**Windblown:** each time a mushroom gives a dose, a new mushroom grows 3 steps further on. Planted mushrooms don't
plant again, and are the first to go when there are too many.

**Follow-ups (drift 25):**
- **Drifting Spores:** a dose also adds 2 stacks to each other status the nightmare already has.
  → Capstone **Spore Season:** while 15 or more mushrooms are growing, every dose is 50% bigger.
- **Fairy Path:** a step touching 2 or more attacking Wardens grows a mushroom, and grows it back 8 s after it is used.
  → Capstone **Witch Ring:** 3 mushrooms within 4 s gives 1 Root (1 s, bosses 0.5 s).
- **Most players take Drifting Spores first.** It arrives with the second family and turns every dose into extra
  stacks of that family's status. Take Fairy Path when kills are thin and the carpet keeps dying out: it makes
  mushrooms without dispels.
- Windblown's own mushrooms count toward Spore Season's 15 (fixed 2026-10-19), so the carpet feeds its capstone.

**Cards that fit (Sporeling lent):**
- Spore Huddle (C): a Sporeling's hits add 1 more Poison per touching Sporeling, up to 3. More Poison dispels, more mushrooms.
- Pass It Round (C): Wardens touching a Sporeling add 3 more stacks with their first hit on each nightmare.
- Breathe It In (C): statuses added in a Sporeling's range get 1 more stack (3 on asleep or Rooted nightmares).
- Settling Spores (U): for 12 steps after a Sporeling hit, each status gains 3 stacks every 6 steps. It follows the
  walker down the route, which is Windblown's ground.
- Mycelium (U): Sprouts touching a Sporeling add Poison and 1 more stack to every other status.
- Gone to Seed (R): a hit near a Sporeling that fills a status or sets off a Reaction gives the other statuses 5 stacks.

**Generic cards that fit:** Winding Path, Passing Thread, Switchback, Thorny Walls; Straightaway (U); Long Way Round
(U, act 2); Brimming (R, act 2); Spore Cascade (R, needs Driftspore); Snag (U, act 2) to land flyers on the carpet.

**Second family partners:**
| Family | Rating | Key cards | Why |
|---|---|---|---|
| Firefly | strong | Brushfire (R), Chain of Lanterns (U), Thunderstruck (R) | Jars bring Charge; Drifting Spores adds 2 to it on everyone walking the carpet. Ignite. Brushfire jumps the Poison ticks. |
| Dewdrop | strong | Ebb (U), Steeped (C), Heavy Going (U) | Linger keeps Poison ticking; Ebb brings it back at half. Soaked Rot (C, two-family) doubles ticks on Soaked nightmares. |
| Bellflower | works | Second Verse (U), Knell (U) | Second Verse lands the last status again as nightmares leave a bell. Bell repeats are damage only, and Sporelings deal most damage through ticks. |

**Signs it's working:**
- Drift 25: thin mushrooms through every corridor; 6+ Sporelings by drift 8. Dream panel 25%+.
- Drift 45: Drifting Spores flashes as statuses fill; the second family's statuses carry extra stacks. Panel about 50%+.
- Not working: few mushrooms by drift 15; Phantoms (flyers) leak at 33–42; shelled Husks soak the Poison.

**Expected stop:** the drift 50 boss (target, unmeasured). Measured before the power budget: runs 35, 37 and 39
died at 45, 32 and 49.

### S2 Clump and Mire (Focus)

**Clump:** a new mushroom joins one within 3 steps, up to 4 in a clump. A clump gives a dose for each mushroom in it.
A clump loses one mushroom each time a nightmare steps on it. Clumps form where Poisoned nightmares fall.

**Follow-ups (drift 25):**
- **Sticky Caps:** a nightmare stepping on a clump walks at half speed, 1 s per mushroom, up to 3 s (bosses half).
  → Capstone **Mire-Mouth:** the 2 nearest nightmares behind it are slowed too, for half as long.
- **Rot:** a clump's dose also adds 2 stacks per mushroom to each other status the nightmare has.
  → Capstone **Rotburst:** a clump's last mushroom bursts: nightmares within 1.5 cells take a dose and 2 stacks of each
  status the stepper had (at most 6).
- **Most players take Rot first:** it multiplies the second family's statuses at the kill zone. Take Sticky Caps if
  the run is leaking to fast streams (the known wall at drift 39).

**Cards that fit (Sporeling lent):**
- Mixed Company (R): hits near a Sporeling add 1 more stack per status the nightmare carries, up to 4.
- Gone to Seed (R): see S1. Pays at a dense kill zone.
- Overnight (U): a Sporeling's hit adds 2 stacks to each status other families put on the nightmare. Needs the second family.
- Spore Huddle (C), Pass It Round (C), Breathe It In (C): pack Sporelings at the kill zone for more Poison dispels there.

**Generic cards that fit:** Cozy Corners, Growth Rings; Gauntlet (R); Crowd Breaker (U); Brimming (R, act 2);
Spore Cascade (R, needs Driftspore); Deep Sleep (R, act 2, bittersweet).

**Second family partners:**
| Family | Rating | Key cards | Why |
|---|---|---|---|
| Dewdrop | strong | Topped Up (C), Ebb (U), Never Quite Dry (R) | Rot fills Soak from clumps. Mushrooming. Never Quite Dry lets the Reaction fire again on the same walker. |
| Firefly | strong | Brushfire (R), Chain of Lanterns (U), Flashover (C) | Ignite at the kill zone; Chain of Lanterns jumps the burst. |
| Bellflower | works | Knell (U), Nod Off (C), Rude Awakening (R) | Knell repeats per status. Sticky Caps' slow is not asleep or Root, so it never sets off Rude Awakening. |

**Signs it's working:**
- Drift 25: stacked 2–4 cap clumps at your kill zone; Sticky Caps slows or Rot flashes. Panel 25–35%.
- Drift 45: Rot fills other statuses; Gone to Seed bursts. Panel about 50%+.
- Not working: clumps stay single (your kills are spread out).

**Expected stop:** the drift 50 boss (target). Likely break: flyers and the drift 39 fast stream.

### S3 Borrowed Spores (Support)

**Borrowed Spores:** a mushroom also gives 2 stacks of the status of the strongest Warden touching it, and 2 more
Poison if a Sprout touches it.

**Follow-ups (drift 25):**
- **Stomping Ground:** a nightmare stepping on a mushroom takes a free hit from each attacking Warden touching that
  step (up to 3, the strongest first; each Warden once a second; bosses half).
  → Capstone **Second Crop:** any dispel within 2 steps of a mushroom leaves a pale mushroom, Poison or not.
- **Feeding Ground:** for 4 s after a dose, Wardens touching that step add 1 more stack with each status hit on it.
  → Capstone **Mother Spore:** a mushroom left by a dispel keeps that nightmare's statuses; the next stepper gets
  2 stacks of each (at most 4 statuses).
- **Pick by your board.** Feeding Ground pays status Wardens beside the mushrooms. Stomping Ground is the hit line:
  any attacking Wardens on the mushroom steps strike every stepper, and Second Crop keeps the carpet alive without
  Poison dispels. It is Spore Print's non-status build.

**Cards that fit (Sporeling lent):**
- Pass It Round (C): the touching Wardens are the ones Borrowed Spores reads.
- Mycelium (U): Sprouts touching a Sporeling; matches the Sprout clause.
- Breathe It In (C), Mixed Company (R), Overnight (U, needs the second family).

**Generic cards that fit:** Seedfall; Root Network (R); Undergrowth (C); Mother's Hand (U, act 1); Graft of Dreams
(R, act 2); Shared Fever (U); Sap Rising (U); Mixed Grove (U, Grove); Shared Light (R, Grove).

**Second family partners:**
| Family | Rating | Key cards | Why |
|---|---|---|---|
| Bellflower | works | Second Verse (U), Knell (U), Nod Off (C) | Mushrooms hand out the bell's Sleep; Sleepwalkers walk back over mushrooms and take more doses. |
| Dewdrop | strong | Steeped (C), High Tide (U), Heavy Going (U) | Borrowed Soak plus Poison, held on by linger. Mushrooming. |
| Firefly | works | Thunderstruck (R), Hammerfall (C) | Every dosed nightmare carries a status, so Thunderstruck always has targets. Jars give Charge to borrow. |

**Signs it's working:**
- Drift 25: before 25 it only borrows Poison. **Damage first:** run 46 (this style plus 3 Bloomcaps) died at 10.
- Drift 45: Feeding Ground or Stomping Ground visible; panel about 50%.
- Not working: fewer than about 20 attackers at 25.

**Expected stop:** 45–50 (target). The weakest act 1 of the three Sporeling styles.

---

## 3. Lantern Light (Firefly Jar)

> Nightmares in a Firefly's glow are lit. When any Warden dispels a lit nightmare, half that hit jumps to the nearest
> other lit nightmare.

- Any dispel counts: a hit, a Poison tick or a cloud, but not a Reaction.
- Firefly lent cards (9): Hammerfall (C), Sparks Fly (C), Flashover (C), Struck Twice (C), Chain of Lanterns (U),
  Nothing Wasted (U), Brushfire (R), Gathering Storm (R), Thunderstruck (R). They work from Fireflies themselves.
- With Lantern Light, Gathering Storm and Struck Twice are always offerable (the Calling's jumps count).

### F1 Strung Lights (Spread)

**Strung Lights:** glows up to 4 steps apart join up. Fireflies deal 5% more to a nightmare for each glow it has
entered, up to +25%. A joined stretch is not a new glow; hits only.

**Follow-ups (drift 25):**
- **Torchbearers:** when a lit nightmare is dispelled, half the dispelling hit jumps to the nearest lit nightmare ahead
  of it (up to 8 steps).
  → Capstone **Bale-fires:** if a Torchbearers jump dispels, it jumps again ahead, up to 4 more times.
- **Glowworms:** up to 2 Sprouts touching each Firefly glow too, so the path next to them is lit.
  → Capstone **Swarm Night:** while 6 or more nightmares are lit, every jump jumps one extra time.
- **Most players take Torchbearers first:** kills chain forward up the path. Take Glowworms on a Sprout-heavy board
  where cheap glow is worth more than damage.

**Cards that fit (Firefly lent):**
- Sparks Fly (C): after a Firefly hit, every 3rd hit another Warden lands within 2 s jumps half.
- Struck Twice (C): a jump readies the next hit on that nightmare for 30% more.
- Chain of Lanterns (U): a Reaction on a nightmare a Firefly hit jumps at half to the 2 nearest.
- Gathering Storm (R): each jump on a nightmare makes the next 25% stronger, up to +200%.
- Hammerfall (C): heavy Wardens and Sprouts near a Firefly jump half. With Glowworms, Sprouts are already in the glow.

**Generic cards that fit:** Winding Path, Passing Thread, Switchback; Straightaway (U); Thinning the Herd (R);
Seedfall, Root Network (R) and Undergrowth (C) with Glowworms; Hunt's Rush (C, Grove).

**Second family partners:**
| Family | Rating | Key cards | Why |
|---|---|---|---|
| Dewdrop | strong | Sodden (C), High Tide (U) | Rain on Glass (C, two-family): Fireflies deal 70% more to Soaked nightmares. Sodden pays a long stretch of path. Thunderclap. |
| Sporeling | works | Settling Spores (U), Pass It Round (C) | Poison ticks dispel lit nightmares, and each tick dispel jumps. |
| Bellflower | works | Refrain (U), In Time (C) | Refrain doubles a Firefly's hit after a bell; more dispels on the lit stretch. |

**Signs it's working:**
- Drift 25: 15+ Jars by 10, glows joined along the route; Torchbearers jumps run up the path. Panel 25%+.
- Drift 45: Gathering Storm grows the jumps; panel about 55%.
- Not working: shelled Husk elites at 33–39 walk through. Add heavies.

**Expected stop:** 50 (target). Measured, run 44 (Torchbearers, Dewdrop at 25): Dreams 38–54% of act 2, died at 40
to four Deeply Blighted Husks; 21 Jars dealt 1 a hit through the shell.

### F2 Bonfire (Focus)

**Bonfire:** path inside 2 or more Fireflies' glows turns gold. Fireflies deal 25% more there, and a dispel there
jumps to 2 lit nightmares. Hits only, not jumps or bolts.

**Follow-ups (drift 25):**
- **Moth to Flame:** a jump landing on a nightmare on gold path adds 2 Exposure (bosses 1).
  → Capstone **Pyre:** a jump that dispels on gold path jumps again at full strength, up to 3 times.
- **Embers:** a nightmare dispelled on gold path leaves an ember for 4 s; the next nightmare over it takes half the
  dispelling hit (at most 8 embers).
  → Capstone **Witchfire:** embers within 2 steps gather into a pile (at most 3); it hits every nightmare within 1 cell.
- **Pick by what you face.** Embers is the safer first pick: it works with Fireflies alone and punishes streams.
  Moth to Flame wants the elites: Exposure needs 10 stacks before it does anything (then the nightmare takes more
  damage). Bright Marks is offered with Moth to Flame, no Lanternmoth needed.

**Cards that fit (Firefly lent):**
- Flashover (C): an area Warden near a Firefly that hits 2+ nightmares jumps half to the nearest it missed.
- Struck Twice (C), Gathering Storm (R): every Bonfire jump feeds them.
- Nothing Wasted (U): damage a shell stops jumps to the nearest unshelled nightmare. The answer to Husks.
- Brushfire (R): needs Poison or clouds near a Firefly (a second-family card).

**Generic cards that fit:** Cozy Corners, Growth Rings; Gauntlet (R); Crowd Breaker (U); First Light (R);
Steady Aim (C); Bright Marks (C) with Moth to Flame. Called Shot (R) and Guiding Light (R) still need Lanternmoth;
Starlit Aim (R) also needs Standing Stone.

**Second family partners:**
| Family | Rating | Key cards | Why |
|---|---|---|---|
| Sporeling | strong | Mixed Company (R), Pass It Round (C), Breathe It In (C) | Fills Poison and Charge fast at the kill zone: Ignite. With Moth to Flame, Exposure + Charge = Lightning Rod. |
| Dewdrop | strong | High Tide (U), Wash Away (C), Old Rain (R) | Thunderclap at the gold path; Wash Away breaks shells. Rain on Glass (C, two-family). |
| Bellflower | works | Refrain (U), Da Capo (U), Reprise (R) | Bells double the hits on gold path; Reprise repeats the Reactions there. |

**Signs it's working:**
- Drift 25: gold path at one kill zone; Exposure building (Moth) or embers glowing. Panel 25–35%.
- Drift 45: crits or ember piles; panel about 55%.
- Not working: you grew every Jar into a Lanternmoth (run 34: dead at 10).

**Expected stop:** 50 (target). Its single-target hits answer the elites.

### F3 Borrowed Light (Support)

**Borrowed Light:** when a Warden that is not a Firefly hits a lit nightmare, a third of the hit jumps to the nearest
other lit nightmare. Sprouts count. Each Warden once a second. Its jump and another card's jump from one hit go to
different nightmares.

**Follow-ups (drift 25):**
- **Lantern Wake:** a jump carries statuses: the nightmare it lands on gets 1 more stack of each status it shares with
  the first one (at most 4).
  → Capstone **Show the Way:** a Borrowed Light jump jumps once more, to another lit nightmare, at half damage.
- **Sightline:** when 3 different Wardens hit the same lit nightmare within 2 s, a quarter of each hit jumps.
  → Capstone **Constellation:** jumps from 3 different Wardens on one nightmare within 3 s give it full Exposure.
- **Most players take Lantern Wake first:** it is Lantern Light's only status link inside the demo, and it arrives
  with the second family. Take Sightline on a dense mixed board where 3 Wardens hit the same targets.

**Cards that fit (Firefly lent):**
- Hammerfall (C): heavy non-Firefly Wardens and Sprouts near a Firefly jump half. Same verb as Borrowed Light; the two
  jumps go to different nightmares.
- Thunderstruck (R): a heavy Warden near a Firefly jumps a quarter to up to 4 nightmares hit in the last 2 s, adding Charge.
- Sparks Fly (C), Chain of Lanterns (U), Struck Twice (C), Gathering Storm (R).

**Generic cards that fit:** Millstone (U, act 1); Heavy Heart (R, act 2); Seedfall, Root Network (R); Mother's Hand
(U); Graft of Dreams (R, act 2); Mixed Grove (U, Grove).

**Second family partners:**
| Family | Rating | Key cards | Why |
|---|---|---|---|
| Sporeling | strong | Pass It Round (C), Mixed Company (R) | Lantern Wake carries Poison down the jumps. |
| Dewdrop | strong | High Tide (U), Steeped (C) | Jetreed and Torrent heavies count for Hammerfall; Thunderclap. |
| Bellflower | works | Refrain (U), On the Beat (C) | Silver Bell is a heavy for Hammerfall and Thunderstruck; bells' hits jump a third. |

**Signs it's working:**
- Drift 25: Sprouts in glow, jump lines from non-Jar hits. Panel 25%.
- Drift 45: heavies' hits fan out; check the panel's Borrowed Light row. About 55%.
- Not working: few jumps from other Wardens.

**Expected stop:** 50 (target).

---

## 4. Puddles (Dewdrop)

> The path touching your Dewdrops is water. A Dewdrop's hit there splashes: nightmares within 4 steps in that water
> gain Soak.

- Touching = within 1.25 cells. A step is one cell of path. A splash Soaks each nightmare at most once a second.
- Dewdrop lent cards (10): Sodden (C), Steeped (C), Topped Up (C), Wash Away (C), Ebb (U), Heavy Going (U), High Tide
  (U), Last Drop (U), Never Quite Dry (R), Old Rain (R). Heavy Going (Dewdrops and Wardens near them +25% on slowed
  nightmares, not Sleep's slow) replaced Slow to Dry on 2026-10-19: the payoff for every slow.
- **No human run has started on Dewdrop.** Every Dewdrop-first number is a target.
- The Calling's own linger (Riverside, Stagnant Water) has its own cap: up to 4 s past the last landing, on top of the
  linger cards.

### D1 Stream (Spread)

**Stream:** water runs 4 steps further down the path. A splash reaching 3 or more nightmares makes that Dewdrop's
next hit deal 30% more.

**Follow-ups (drift 25):**
- **Millrace:** a splash also spreads 1 stack of up to 3 other statuses from the nightmare it hit to every nightmare it
  reaches (never Sleep or Root; Charge stops 1 short of a bolt).
  → Capstone **Flood:** a splash runs the whole length of its water, up to 24 steps each way.
- **Lapping Water:** when a non-Dewdrop Warden touching water hits a Soaked nightmare there, nightmares within 2 steps
  in that water get Soak too.
  → Capstone **Spring Flood:** every 10 s, up to 8 nightmares in the longest water reach full Soak and walk 25% slower
  for 2 s.
- **Most players take Millrace first:** it spreads the second family's statuses down the water. Take Lapping Water
  with few Dewdrops and many other Wardens on the banks.

**Cards that fit (Dewdrop lent):**
- Sodden (C): +10% per second since first Soaked, up to +40%; long stretches of path.
- Ebb (U): a status running out in a Dewdrop's range comes back at half its highest stacks for 3 s.
- Last Drop (U): Soak running out deals 40% of the hit per stack, up to 3 hits.
- High Tide (U): hits near a Dewdrop deal 10% more per status, up to +30%. Millrace gives them more statuses.
- Steeped (C): statuses last 40% longer from Wardens touching a Dewdrop.

**Generic cards that fit:** Winding Path, Passing Thread, Switchback; Straightaway (U); Long Way Round (U, act 2);
Shared Fever (U); Wide Petals (C) and Crowd Breaker (U) for Rain Lily splashes.

**Second family partners:**
| Family | Rating | Key cards | Why |
|---|---|---|---|
| Firefly | strong | Chain of Lanterns (U), Struck Twice (C) | Millrace spreads Charge; Thunderclap through Soaked crowds. Rain on Glass (C, two-family). |
| Sporeling | strong | Settling Spores (U), Overnight (U) | Millrace spreads Poison; Mushrooming. Soaked Rot (C, two-family). |
| Bellflower | thin | Knell (U), Second Verse (U) | Millrace never carries Sleep. Knell counts Soak as a status. |

**Signs it's working:**
- Drift 25: water joins between Dewdrops; Millrace threads. Panel 25%.
- Drift 45: linger cards on; panel about 50%.
- Not working: a second linger card shows no gain on the panel.

**Expected stop:** 45–50 (target).

### D2 Black Pond (Focus)

**Black Pond:** water touching 2 or more Dewdrops is a pond. Nightmares in it walk 25% slower and take 25% more from
Dewdrops (bosses slowed half as much; hits only).

**Follow-ups (drift 25):**
- **Whirlpool:** a Dewdrop's 3rd hit on a nightmare in a pond pulls it back 2 steps (once per pond and nightmare;
  never bosses or flyers). It needs no Soak, so Black Pond is Puddles' non-status build (with Heavy Going).
  → Capstone **Drowning Deep:** the pull drags nightmares within 1 cell back too (at most 4), and every Warden touching
  the pond gets a free hit on the pulled one.
- **Stagnant Water:** statuses on nightmares in a pond don't run down while they stay in it (not Sleep or Root).
  → Capstone **Drowned Hands:** a nightmare in a pond with 4 or more statuses gains 1 Root (1 s, bosses 0.5 s).
- **Most players take Whirlpool first:** more time in the pond, and it counts as a pull for Homesick. Take Stagnant
  Water when the second family brings several statuses.

**Cards that fit (Dewdrop lent):**
- High Tide (U), Never Quite Dry (R), Old Rain (R): Reaction and multi-status payoffs at the pond.
- Wash Away (C): Soaked nightmares' shells wear down twice as fast. Pond elites.
- Topped Up (C): a Dewdrop's hit resets statuses to their starting time. Less useful inside a Stagnant pond.

**Generic cards that fit:** Cozy Corners, Growth Rings; Gauntlet (R); Homesick (R, act 2: Whirlpool counts as a
pull); Deep Water (U, needs Dewdrop: Drown lasts 4 s and grows faster); Deep Sleep (R, act 2, bittersweet).

**Second family partners:**
| Family | Rating | Key cards | Why |
|---|---|---|---|
| Sporeling | strong | Overnight (U), Gone to Seed (R), Mixed Company (R) | Overnight's +2 lands on Soak. Pulled-back nightmares walk the spore range again. Mushrooming. |
| Firefly | strong | Struck Twice (C), Nothing Wasted (U) | Thunderclap in the pond. Rain on Glass (C, two-family). |
| Bellflower | thin | Knell (U), Nod Off (C), Rude Awakening (R) | Drown needs bells to fill Sleep alone; Stagnant Water never holds Sleep. |

**Signs it's working:**
- Drift 25: a dark pond at the kill zone; Whirlpool pulls. Panel 25–35%.
- Drift 45: Reactions via the second family; panel about 55%.
- Not working: no pulls by drift 30.

**Expected stop:** 50 (target). Whirlpool never touches flyers or bosses.

### D3 Riverside (Support)

**Riverside:** statuses that Wardens touching water add there last 2 s longer. Sprouts touching water deal 25% more
to Soaked nightmares in it. Dewdrops count for the time; only Sprouts for the damage.

**Follow-ups (drift 25):**
- **Rain on the Bank:** a splash gives each nightmare it reaches 1 stack of the status of each Warden touching
  that water, Dewdrops too (at most 3; Sleep stops 1 short of full).
  → Capstone **Downpour:** a splash reaching 4 or more nightmares makes every other Warden touching that water attack
  one of them at once (each Warden once every 4 s).
- **Wet Footprints:** a Soaked nightmare leaving water leaves wet steps for 3 s; wet steps count as water.
  → Capstone **Reflection:** when a Warden touching water hits a Soaked nightmare there, half the hit also lands on the
  nightmare furthest back in that water.
- **Most players take Rain on the Bank first:** it spreads the second family's statuses through every splash. Take
  Wet Footprints on spread-out boards with short water.

**Cards that fit (Dewdrop lent):**
- Steeped (C), Topped Up (C), Ebb (U): linger. Riverside adds on top of them.
- Old Rain (R): a Reaction near a Dewdrop deals 40% more if it spends a status a card made last longer.
- Never Quite Dry (R): a Reaction near a Dewdrop leaves the spent statuses at half.

**Generic cards that fit:** Seedfall, Root Network (R), Undergrowth (C), Thicket (U); Mother's Hand (U);
Shared Fever (U); Slow Burn (U, offered once you hold a linger card or Riverside / Stagnant Water).

**Second family partners:**
| Family | Rating | Key cards | Why |
|---|---|---|---|
| Sporeling | strong | Pass It Round (C), Mixed Company (R), Breathe It In (C) | Bank statuses fan through every splash. |
| Firefly | strong | Thunderstruck (R), Hammerfall (C), Sparks Fly (C) | Splashes give everyone a status, so Thunderstruck always finds targets. |
| Bellflower | works | Knell (U), Nod Off (C) | Rain on the Bank carries Sleep to 1 short of full: one bell hit from Drown along the water. |

**Signs it's working:**
- Drift 25: puffs on the bank; works alone because Dewdrops count. Panel 20–30%.
- Drift 45: panel about 50%.
- Not working: few Wardens touch water.

**Expected stop:** 45–50 (target).

---

## 5. Keeping Time (Bellflower)

> Each bell hit rings the nightmare; at 4 rings it is a Toll: the hit lands again at half damage. Nightmares start
> with 2 rings.

- Hits less than 0.5 s apart count as one ring. Each nightmare takes one Toll a second at most.
- Bellflower lent cards (9): In Time (C), Nod Off (C), On the Beat (C), Da Capo (U), Knell (U), Refrain (U),
  Second Verse (U), Reprise (R), Rude Awakening (R). They make things happen again.
- Since 2026-10-18 (council fix F1), Tolls count as hits by their bell for other families' lent cards.

### B1 Carrying Tune (Spread)

**Carrying Tune:** each ring also lands, at half damage, on nightmares up to 4 steps further down the path, ringing
them too. It stops at the next bell's range; a shot carries to up to 4 nightmares.

**Follow-ups (drift 25):**
- **Hand to Hand:** when a nightmare reaches a new bell, that bell's first hit on it counts as 2 rings.
  → Capstone **Peal:** a Toll adds 1 ring to every nightmare within 4 steps (at most 8), but never makes their Toll.
- **Lingering Note:** a Toll leaves a note on the path for 2 s; every nightmare walking through it is rung once.
  → Capstone **Night Choir:** a note touching a Warden repeats that Warden's last hit at half on each walker (at most
  3 Wardens).
- **Most players take Hand to Hand first:** spaced bells Toll sooner. Take Lingering Note against packed streams.

**Cards that fit (Bellflower lent):**
- Second Verse (U): when a nightmare leaves a bell's range, the last status another Warden gave it lands again.
  Spaced bells pay more.
- In Time (C): every 5th hit by a Warden touching a bell lands again.
- Knell (U): a bell's hit lands again once per status, up to 3 times.
- Refrain (U), Da Capo (U): more bell hits, more rings.

**Generic cards that fit:** Winding Path, Passing Thread, Switchback; Straightaway (U); Long Way Round (U, act 2);
Hush (C, Grove: pulsing bells get 50% more range).

**Second family partners:**
| Family | Rating | Key cards | Why |
|---|---|---|---|
| Dewdrop | works | Sodden (C), Steeped (C) | Long path, long Soak; Tolls now count as hits for Sodden. |
| Sporeling | works | Breathe It In (C), Settling Spores (U) | Second Verse lands Poison again at each bell. |
| Firefly | works | Sparks Fly (C), Struck Twice (C) | Bells hit often, so Sparks Fly's every-3rd-hit jumps come fast. |

**Signs it's working:**
- Drift 25: bells every few corridors; Hand to Hand double rings. Panel 30%.
- Drift 45: panel about 55%.
- Not working: Night Hounds or Sobs stream through at 39–44.

**Expected stop:** 50 (target). Silver and Vesper Bells pick the toughest nightmare, not the fastest (run 47).

### B2 Steady Beat (Focus)

**Steady Beat:** nightmares in range of 2 or more bells start with 3 rings instead of 2, and their Tolls hit at full
damage instead of half. Where bells overlap, the path glows gold.

**Follow-ups (drift 25):**
- **Crescendo:** each Toll makes the next Toll on that nightmare 25% stronger, up to +100%.
  → Capstone **Midnight Bell:** the 12th ring is a Midnight Toll: the bell hits for triple damage (with Crescendo), and
  every damaging status deals its damage at once and stays. A hit build gets the triple blow alone.
- **Hush-a-bye:** each Toll adds 2 Sleep; 3 Tolls within 6 s puts a nightmare asleep for 1 s (never bosses).
  → Capstone **Sleeping Hall:** when it wakes, its next Toll within 3 s also hits up to 4 touching nightmares at half.
- **Most players take Crescendo first** for damage against elites. Take Hush-a-bye when fast streams leak: it is the
  build's only stop.

**Cards that fit (Bellflower lent):**
- Da Capo (U): every 6 s a bell's next attack happens twice.
- Knell (U), Refrain (U), On the Beat (C): more hits in the overlap.
- Nod Off (C): a bell's first Sleep on a nightmare puts it asleep for 1 s.
- Rude Awakening (R): when a nightmare wakes or its Root ends, the last hit of up to 3 Wardens lands again. Pairs with
  Hush-a-bye and Nod Off.
- Reprise (R): a Reaction in a bell's range goes off again at half.

**Generic cards that fit:** Cozy Corners, Growth Rings; Gauntlet (R); First Light (R); Momentum (U); Steady Aim (C);
Hunter's Patience (R, Grove); Still Target (U, Grove) with Hush-a-bye.

**Second family partners:**
| Family | Rating | Key cards | Why |
|---|---|---|---|
| Firefly | strong | Thunderstruck (R), Chain of Lanterns (U), Sparks Fly (C) | Hush-a-bye's Sleep plus Jars' Charge: Night Terror. Silver Bell is a heavy for Thunderstruck. |
| Dewdrop | works | High Tide (U), Sodden (C) | Tolls now count as hits for them. Drown with Deep Water (U). |
| Sporeling | works | Mixed Company (R), Overnight (U) | Hush-a-bye Sleep plus Poison: Sleepwalk. Midnight Bell bursts the Poison (capstone). |

**Signs it's working:**
- Drift 25: gold path at one bend; Crescendo or Hush-a-bye shows. Panel 30%+.
- Drift 45: panel about 60%.
- Not working: no answer to a fast stream by 38 (Switchback, Snag, a slow).

**Expected stop:** 50 (target). Measured, run 47 (this path, Dewdrop at 25): 15/15 leaves through 37; Refrain 455k,
Da Capo 191k (the old card), Steady Beat 154k. Ten Night Hounds leaked at 39; dead at 42.

### B3 Accompaniment (Support)

**Accompaniment:** Wardens touching a bell join the song: their hits add rings too, and their Tolls repeat that
Warden's hit and status. Other Wardens add a ring once a second; a Sprout adds one with every hit.

**Follow-ups (drift 25):**
- **Counterpoint:** when a non-bell Warden makes a Toll, the nearest bell within 4 cells rings that nightmare too
  (a free hit).
  → Capstone **Symphony:** when 4 different Wardens have added rings to a nightmare, its Toll repeats each one's last
  hit at half.
- **Chime of Many:** a Toll also repeats the nightmare's last status hit on up to 4 touching nightmares.
  → Capstone **Last Chord:** a Toll on a nightmare with 3 or more statuses sets off any Reaction it is halfway to.
- **Most players take Chime of Many first** when the second family brings statuses: it spreads them into packs.
  Take Counterpoint on a damage board.

**Cards that fit (Bellflower lent):**
- In Time (C), On the Beat (C): both pay Wardens touching a bell, which Accompaniment needs anyway.
- Refrain (U), Second Verse (U), Knell (U).
- Reprise (R): with Last Chord (capstone), Reactions go off twice.

**Generic cards that fit:** Seedfall, Root Network (R), Undergrowth (C); Mother's Hand (U); Sap Rising (U);
Close Kin (C), Kin and Kindling (R); Mixed Grove (U, Grove); Rootbound (R, Grove).

**Second family partners:**
| Family | Rating | Key cards | Why |
|---|---|---|---|
| Sporeling | strong | Pass It Round (C), Mixed Company (R), Gone to Seed (R) | Spore Wardens beside bells ring; Chime of Many repeats Poison onto 4 neighbours. |
| Firefly | strong | Chain of Lanterns (U), Sparks Fly (C), Hammerfall (C) | Jars beside bells Toll; their Charge spreads. |
| Dewdrop | strong | Steeped (C), Ebb (U), Never Quite Dry (R) | Soak spreads by Toll; linger keeps it for Reactions. |

**Signs it's working:**
- Drift 25: pink rings from neighbours. Panel 25–30%.
- Drift 45: panel about 50%.
- Not working: the act 1 boss lasts past about 60 s.

**Expected stop:** 50 (target). Measured, run 45 (Firefly at 25; Chime of Many 56k): the act 1 boss was not
dispelled, dead at 32 (before the boss was eased). Run 43 died at 44 to elites.

---

## 6. Comparison table

| # | Calling | Style | Core idea | Key evolutions | Key cards | Best second family | Cousins |
|---|---|---|---|---|---|---|---|
| S1 | Spore Print | Spread | Mushroom carpet down the whole route | Windblown → Drifting Spores | Settling Spores, Spore Huddle, Pass It Round | Firefly | S2, F1, D1 |
| S2 | Spore Print | Focus | Clumps of doses at one kill zone | Clump → Rot / Sticky Caps | Mixed Company, Gone to Seed, Overnight | Dewdrop | S1, D2, F2 |
| S3 | Spore Print | Support | Mushrooms hand out neighbours' statuses | Borrowed Spores → Feeding Ground | Pass It Round, Mycelium, Mixed Company | Dewdrop | F3, D3, B3 |
| F1 | Lantern Light | Spread | Joined glows, kills chain forward | Strung Lights → Torchbearers | Sparks Fly, Gathering Storm, Struck Twice | Dewdrop | F2, B1, D1 |
| F2 | Lantern Light | Focus | Gold kill zone, double jumps | Bonfire → Embers / Moth to Flame | Flashover, Nothing Wasted, Gathering Storm | Sporeling | F1, B2, D2 |
| F3 | Lantern Light | Support | Other families' hits jump in light | Borrowed Light → Lantern Wake | Hammerfall, Thunderstruck, Chain of Lanterns | Sporeling | S3, D3, B3 |
| D1 | Puddles | Spread | Long water carries Soak and statuses | Stream → Millrace | Sodden, Ebb, High Tide | Firefly | D2, S1, B1 |
| D2 | Puddles | Focus | Slow pond pulls nightmares back | Black Pond → Whirlpool | High Tide, Never Quite Dry, Wash Away | Sporeling | S2, F2, B2 |
| D3 | Puddles | Support | Bank Wardens' statuses ride the splash | Riverside → Rain on the Bank | Steeped, Old Rain, Ebb | Sporeling or Firefly | S3, F3, B3 |
| B1 | Keeping Time | Spread | Rings carry down a long maze | Carrying Tune → Hand to Hand | Second Verse, In Time, Knell | Dewdrop | B2, F1, D1 |
| B2 | Keeping Time | Focus | Overlapping bells, full-damage Tolls | Steady Beat → Crescendo / Hush-a-bye | Da Capo, Refrain, Rude Awakening | Firefly | B1, F2, D2 |
| B3 | Keeping Time | Support | Neighbours ring and Toll too | Accompaniment → Chime of Many | In Time, On the Beat, Refrain | Sporeling | S3, F3, D3 |

Cousins by style: every Spread build wants Winding Path and a long route; every Focus build wants Cozy Corners and a
bend kill zone; every Support build wants Sprouts and mixed Wardens touching the family's Warden.

---

## 7. Gaps and fixes

### Fixed 2026-10-19 (commit 815a41ea)

1. **Capstones in the demo.** Capstones came at the drift 50 rest, the demo's last, so no demo run played one. They
   now come at the drift 45 rest (Calling drifts 5 / 25 / 45 / 75). Witch Ring and Drowned Hands, the two Root
   makers, arrive there too.
2. **Spore Season vs Windblown.** Windblown's own mushrooms now count toward Spore Season's 15.
3. **Slow Burn and Old Rain.** Riverside and Stagnant Water already counted in code. Slow Burn is now offered with
   either of them, and both tips say a Calling evolution counts.
4. **Moth to Flame's Exposure.** Bright Marks is offered with Moth to Flame, no Lanternmoth needed. Called Shot,
   Guiding Light and Starlit Aim still need their Wardens.
5. **Peal.** The tip now says its rings never make a Toll on their own: a hit has to. It no longer reads as a rule
   against Accompaniment's Tolls.
6. **Thunderstruck.** The tip now says Firefly heavy forms count too, as the code does. Hammerfall still excludes
   them.
7. **Breathe It In.** The tip now says only stacks a Warden's own attack adds count, not stacks from other cards or
   the Calling.
8. **Riverside** now gives the Charge 2 s limit like the other linger texts.
9. **Stagnant Water** now says "bosses' statuses run down at half speed".

### Non-status builds (2026-10-19, commit 9cf6d480)

A build that wins with hits, jumps, Tolls, heavy hits and placement, not statuses or Reactions. Every family's
Wardens still put their own status on; nothing in these builds reads it.

- **Spore Print:** Borrowed Spores → Stomping Ground → Second Crop. Cards: Fruiting, Parting Puff; Cozy Corners,
  Gauntlet, First Light. Partner: Bellflower (In Time, On the Beat, Refrain) or Firefly (Hammerfall, Sparks Fly).
- **Lantern Light:** Strung Lights → Torchbearers → Bale-fires, or Bonfire → Embers → Witchfire. Cards: Sparks Fly,
  Struck Twice, Gathering Storm, Flashover. Partner: Bellflower (Refrain) or Sporeling (Fruiting, Parting Puff).
- **Puddles:** Black Pond → Whirlpool → Drowning Deep. Cards: Heavy Going, Sodden, Wash Away; Switchback. Partner:
  Bellflower (Da Capo, On the Beat) or Firefly (Hammerfall, Thunderstruck).
- **Keeping Time:** Carrying Tune → Hand to Hand → Peal, or Steady Beat → Crescendo → Midnight Bell (the triple blow).
  Cards: In Time, Refrain, Da Capo, On the Beat. Partner: Firefly (Sparks Fly, Struck Twice) or Sporeling (Fruiting).
- Every family's lent set now holds cards a hit board wants: Sporeling 2, Firefly 7 (Thunderstruck now targets
  nightmares hit in the last 2 s), Dewdrop 3, Bellflower 4.
- **How to tell it works:** status cards under 20% of card damage in the Dream damage panel, and the run within 3
  drifts of a status run on the same Calling. Unmeasured.

### Still open (design calls)

- **Dewdrop Stream / Black Pond with Bellflower second is thin.** Neither evolution carries Sleep, so Drown relies on
  bells alone. Riverside with Bellflower works (Rain on the Bank carries Sleep).
- **Embers, Witchfire and Peal** have no card that names them; they feed the jump and Toll cards.
- **Bonfire's "Hits only, not jumps or bolts"** is correct (the +25% is for hits) but easy to misread on a jump
  evolution.

### Cards that fit no Calling build directly

- **Nothing Wasted, Wash Away, Last Drop:** shell and edge-case cards. They fit any build of their family but pay no
  style. Take them for the elites, not the build.
- **Brushfire** does nothing on a Firefly-first run until Poison or cloud Wardens arrive. It is a partner card.
- **Overnight** needs another family's status, so it waits for a second family.
- **Spore Huddle** pays only Sporelings packed together: Clump and Windblown, not Support boards.
