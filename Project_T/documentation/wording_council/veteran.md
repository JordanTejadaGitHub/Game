# Wording Council: the genre veteran / min-maxer

Seat: reads every card like a contract and asks what a theorycrafter would post on Reddit. Corpus: corpus_resources.txt and corpus_ui.txt (2026-10-22), house rules text_style.md, text_pass.md and wording_review_2026-10-13.md §1. Where I say **checked**, I read the code. **(check)** means I did not verify it. All numbers come from the data or the code. I made none up.

---

## 1. Top 10 ambiguities (ranked by wrong plays and forum arguments)

### 1. Do Dream damage bonuses add or multiply? And the hidden ×4 cap
- **Where:** every "deal N% more damage" card. Only Crown of Leaves, Gauntlet, Towering, Passing Thread, Ember Count and Struck Twice say "Multiplies with your other Dream damage."
- **Readings:** (a) Cards without the line multiply too, so Blood Is Thicker 100% × Chosen Few 100% gives ×4. (b) They add, so the same pair gives ×3.
- **Code (checked):** `Tower._refresh_dream_rows` sorts the bonuses into two buckets. The plain bucket adds up: stat cards, Blessings, and every row without a bucket. The synergy bucket multiplies on top. Per-hit card factors also multiply. Then `DreamState.card_cap_factor` caps all non-Reaction card power on one hit at **×4** (`CARD_PRODUCT_CAP`, `CARD_CAP_ON = true`). No player text mentions this cap. The only place it appears is the dev run report ("Past the x4 card line").
- **Rewrite:** give every damage card one of two fixed tip lines. Synergy cards keep "Multiplies with your other Dream damage." Every plain card gets "Adds to your other Dream damage." Add one glossary entry, **Dream damage**: "Most Dream damage bonuses add together; cards that say so multiply. All Dream cards together make one hit at most ×4 as strong (Reactions have their own limit)." Link it from both tip lines.

### 2. The +150% attack speed cap is stated only on Whirlwind Heart
- **Where:** Rootbound (100%), Fresh Growth (100%), The Last Light (100%), Desperate Bloom (50%), Quick Step (50%), Close Shave, Hunt's Rush, and others.
- **Readings:** speed bonuses stack without limit, or there is a cap. A player who stacks Rootbound, The Last Light and Fresh Growth expects +300%.
- **Code (checked):** `DREAM_SPEED_CAP := 1.5`. All Dream cards together add at most +150% attack speed to one Warden. The only player text that says so is Whirlwind Heart's tip ("Dream cards still make one Warden attack at most 150% faster").
- **Rewrite:** add an **Attack speed** glossary line: "Dream cards together make one Warden attack at most 150% faster." Every "% faster" card links to it on first use. Whirlwind Heart's tip can then drop the sentence.

### 3. "a Sporeling", "a Firefly", "a Dewdrop", "a bell": the base Warden or the whole family?
- **Where:** Breathe It In ("in a Sporeling's range"), Gone to Seed, Mixed Company, Fruiting, Parting Puff, Pass It Round, Overnight, Spore Huddle, Mycelium, Brushfire, Chain of Lanterns, Flashover, Hammerfall, Thunderstruck, Nothing Wasted, Sparks Fly, Struck Twice, Rain on Glass, Ebb, Steeped, Topped Up, High Tide, Heavy Going, Sodden, Last Drop, Never Quite Dry, Old Rain, Wash Away, and every "bell" card.
- **Readings:** (a) Only the base Warden named Sporeling. (b) Any Sporeling-family form, including Puffball and Sporemother. Players will sell their Puffball "because the card says Sporeling."
- **Code (checked):** `class_kit.is_own` returns true for "A Warden of this family, any form" (attacking only). So reading (b) is correct. "Bell" is only defined inside the Codex Toll entry, as "any Bellflower form". Nod Off's tip suggests Dreamcatcher counts as a bell.
- **Rewrite:** the house rule already says families are names ("Any Nestling-family final form"). Write the family token, e.g. "Statuses added to nightmares in range of a {family:sporeling} Warden…". Phrases like "Fireflies' own heavy forms" become "{family:firefly_jar} Wardens' own heavy forms". "Bell" gets its own keyword entry: "Bell: any {family:bellflower} Warden."

### 4. Poison: one shared clock, or 5 s per stack?
- **Where:** `icon_info.gd:21` (the glossary) says "Every new stack keeps the whole pile going; it wears off 5 s after the last one." `lesson_card.gd:222` (the Lesson) says "Each stack lasts 5 s, so keep hitting it."
- **Readings:** the glossary describes one shared timer. The Lesson describes a separate timer for each stack. The two lead to different refresh habits.
- **Code (checked):** `EnemyStatuses._share_spore_clock`. The whole pile shares one clock: every application refreshes it, and every stack goes at once (owner 2026-10-15, which replaced the old rule of one expiry per application). The glossary is right and the Lesson is wrong.
- **Rewrite (Lesson):** "It takes damage every second, more per stack. Each new stack restarts the clock; the whole pile wears off 5 s after the last one. At {stacks:need_spored} stacks it can set off {reactions}."

### 5. Beacon and Bright Marks: how much extra damage does a full Exposure give?
- **Where:** dream_beacon.tres says "nightmares at {full} {marked} take +{pct:beacon.marked_bonus} damage **on top of what {marked} gives**". The beacon.tres Warden text says "its {marked} is stronger: +50% damage taken". Bright Marks says "take 55% more damage instead of 25%", but its tip says "Adds 30%…so Beacon and Potency still raise it".
- **Readings:** Beacon gives 25% + 50% = 75%, or a flat 50%. Bright Marks gives a flat 55%, or 25% + 30% plus whatever Beacon and Potency add.
- **Code (checked):** `get_damage_taken_multiplier` takes the **larger** of the base 25% and Beacon's `marked_bonus` 0.5, so Beacon **replaces** the 25% with 50%; it does not add to it. Bright Marks adds 30% on top. Potency raises the result, but only up to `EXPOSED_CAP` 40%, unless the result is already higher than that. Exposure applies to **all** damage the nightmare takes (ticks and Reactions too), not just hits.
- **Rewrites:**
  - Beacon card: "…and its {marked} at {full} makes nightmares take {pct:beacon.marked_bonus} more damage, not 25%."
  - Bright Marks: "{full} {marked} makes nightmares take 30% more damage on top (55% instead of 25%)." Keep the tip.
  - Exposure glossary: "…takes 25% more damage from everything (Potency raises it, up to 40%)."

### 6. Diagram captions that contradict their own card
Players trust the picture over the sentence. **Checked** against the constants:

| Card | Description (matches code) | Caption (stale) |
|---|---|---|
| Crossroads | "deals 100% more damage" (`CROSSROADS_BONUS 1.0`) | "Touches the path at steps 1 and 7, 6+ apart: +40%." |
| Briar Crown | "60% of a hit" (`BRIAR_SHARE 0.60`) | "…takes 25% of the strongest Warden touching it." |
| Thicket | "Sprouts touching 2 or more path cells attack 20% faster" (`SPROUT_CHORUS_SPEED 0.20`) | "W touches another Sprout and at least 2 distinct route cells: +30% attack speed." (old rule, old number, "route") |
| Bitter Hedges | "each Thornwall, Bramble or Honeysuckle" | "Each Thornwall a nightmare walks past" |

- **Rewrites:**
  - Crossroads: "Touches the path at steps 1 and 7, 6 or more apart: +100%. ✗ Steps 2 and 6 are only 4 apart."
  - Briar Crown: "A nightmare stepping beside the Thornwall takes 60% of a hit from the strongest Warden touching it."
  - Thicket: "W touches at least 2 path cells: attacks 20% faster."
  - Bitter Hedges: "Each wall a nightmare walks past: +8% damage taken from hits for 2 s (up to +40%)."
- Captions should read their numbers from the data. The same `{field:}` token problem was fixed for Warden numbers in text_pass.md.

### 7. Wellspring interest cap: 130 or 260?
- **Where:** the Codex "Harvest and interest" entry (`codex_data.gd:52`) says "at most 130 a rest for all Wellsprings together". wellspring.tres says "all Wellsprings together up to {dew:260}". `lesson_demo.gd` and `warden_header_view.gd` read the cap from code.
- **Code (checked):** `DewCatch.INTEREST_CAP := 260` ("130 before the Dew x2 second pass").
- **Rewrite:** in the Codex, use "…at most %s a rest for all Wellsprings together" filled from `DewCatch.INTEREST_CAP`. Never hardcode it.

### 8. Which walls count as a "Thornwall"?
- **Where:** Hedge Maze, Thorny Walls, Briar Trap, Hushed Hedge, Snag, Living Walls and Hedgerow Roots say only "Thornwall". Bitter Hedges and Briar Crown list "Thornwall, Bramble or Honeysuckle". Rootbound, Few and Mighty and Odd One Out don't say whether walls or Sprouts count among the Wardens.
- **Readings:** a Bramble is still a Thornwall (it grew from one), or it is not.
- **Code (checked, Hedge Maze only):** `_hedge_maze` counts only `get_id() == "thornwall"`. Brambles, Honeysuckles and stone walls give **nothing**, and a twig wall counts **half** (`wall_weight`). The other cards are **(check)**.
- **Rewrite:** add a tip line on every wall card, either "Brambles and Honeysuckles count too" or "Only plain Thornwalls count; twig walls count half." For Hedge Maze: "Plain Thornwalls only; a twig wall counts half." Rootbound needs the same line: "Walls don't count" or "Walls count" **(check)**.

### 9. "×12 damage", "16× the stored Charge", "×3", "×4": times what?
- **Where:**
  - Thunderclap: "×12 damage, ×6 per arc"
  - Charge glossary: "goes off as a strong bolt (16× the stored Charge)"
  - Pinned: "a guaranteed crit for ×3 damage"
  - Shatter: "deals ×4 damage"
  - Lightning Rod: "for ×2 damage"
- **Readings:** ×12 the hit that set it off, ×12 the status damage, or ×12 the Warden's damage stat. For Pinned and Shatter: does ×3 or ×4 replace the Warden's own crit multiplier, or stack with it?
- **Code (checked):** `THUNDERCLAP_DAMAGE := 12.0  # × the applier's damage`, and `THUNDERCLAP_MAX_ARCS := 8`. The 8-arc limit is unstated, but Rolling Thunder's cost line "at most 3 arcs" only makes sense if players know the base limit. The Charge bolt is 16 × the applier's damage × Potency (`STATIC_BOLT_MULTIPLIER`), scaled down when set off early. "Stored Charge" is not a number a player can see. Pinned and Shatter: **(check)** whether they replace or multiply the crit.
- **Rewrite:** name the base once in each text.
  - Thunderclap: "deals 12× the damage of the Warden that set it off, and arcs (up to 8) for 6× to nightmares with {damp} within 2.5 cells."
  - Charge: "…goes off as a bolt for 16× the hit of the Warden that added it (less if set off early)."
  - Pinned and Shatter: add "instead of its usual crit" or "on top of its crit", whichever the code does.
- Also: Thunderclap and Lightning Rod hardcode "10 {static} (15 on bosses)". Use `{stacks:need_static}`-style tokens like the other Reactions so the numbers can't drift.

### 10. "Water hits" (Soak) and "Water" (the Puddles area) share one word
- **Where:** the Soak glossary and Lesson say "Water hits deal 20% more damage". The Dewdrop Warden text says "from water hits". The Codex "Water" entry is "The path touching a {warden:dewdrop} (within 1.25 cells)". Soaked Rot's cost says "{damp} no longer makes {family:dewdrop} hits stronger".
- **Readings:** hits that land in the Puddles water, or hits from Dewdrop-family Wardens. A Firefly hitting a Soaked nightmare standing in water: does it count?
- **Code (checked):** `enemy.gd`: `line == "water"`, which means hits from Dewdrop-family Wardens only. Where the nightmare stands doesn't matter. Potency raises the 20%.
- **Rewrite:** "Hits from {family:dewdrop} Wardens deal 20% more damage to it (more with Potency)." Do the same in icon_info, the Lesson and dewdrop.tres. Reserve "water" for the Puddles area.

---

## 2. Every other flagged string

| Where | Now | Ambiguity | Rewrite |
|---|---|---|---|
| hunters_patience.tres tip | "Hits only, not statuses. Wardens' hits also deal 40% more to flyers." | A second effect is hidden in the tip. Players reading the card face never learn the flyer bonus. | Move it into the description: "…to {deeply_blighted} nightmares and bosses, and 40% more to flyers. Hits only." |
| icon_info `marked` / lesson `marked` | "takes 25% more damage from every Warden" | "From every Warden" suggests hits only. Code: all damage, ticks and Reactions included (checked). | "takes 25% more damage from everything" |
| lanternmoth.tres | "takes 25% more damage from every Warden" | Same as above. | Same as above. |
| thousand_cuts.tres | "take 2% more damage from every Warden, up to +60%" | Same; also, does an area attack count once or once per nightmare? (check) | "…from everything… Each hit counts, an area attack once." |
| world_root.tres / dream_world_root | "take 30% more damage from every Warden" | Same (code multiplies all damage: `held_bonus`). | "from everything" |
| icon_info `static` | "(16× the stored Charge)" | See #9. | See #9. |
| thunderclap.tres | "Needs … 10 {static} (15 on bosses)" | Hardcoded numbers, and arc count and range missing. | See #9. |
| lightning_rod.tres | "10 {static} (15 on bosses)" … "for ×2 damage" | Hardcoded; ×2 of what? | Token, plus "for twice the bolt's damage" |
| drown.tres | "takes more damage each second" | No number; Deep Water's "grows 50% faster" has nothing to scale against. | State the base growth (check `reactions.gd` drown) |
| mushrooming.tres | "most {reactions}" | Which Reactions don't count? | List the exceptions, or "every Reaction but X" (check) |
| combo_feedback CHAIN_LINE | "Past the fifth link each one hits a little softer" | Unquantified falloff. | "Past the fifth link each one deals N% less" (check `CHAIN_FALLOFF`) |
| dawnbreak.tres / codex Dawnburst | "nightmares within 4 cells take 10%…" | Within 4 cells of what: the nightmare that made link 10, or the Heartwood? | "within 4 cells of the nightmare that made the 10th link" (check) |
| brimming.tres | "Nightmares hold twice as many {stacks}…" | "Reactions still fire at their usual count" is in the tip, but card payoffs double (Many Threads 32, Sparking Spores 40, Hushed Hedge 24). Players can't tell which thresholds double. | Tip: "Reactions fire at their usual count; Charge bolts and card thresholds need twice as many." (check the bolt cap) |
| stormcap.tres | "chains to 4 nightmares" | 4 jumps after the first, or 4 in total? | "hits up to 4 nightmares in all" (check) |
| thunderhead.tres | "Chains to 4" | Same. | Same. |
| stormheart.tres | "(−15% per jump)" | 15% of the original each jump (linear), or 15% less than the last (compounding)? | "each jump deals 15% less than the one before" (check) |
| autumn_gale.tres / dream_autumn_gale | "10% stronger (up to 50%)" | Per seed, per throw, reset when? | "+10% for each seed that hits and returns, up to +50%; resets when a throw catches none" (check) |
| grove_heart.tres | "…deal X more damage and attack Y faster, 3% more for each Warden in that area (up to 45%)" | 3% on both bonuses? Is 45% the cap on each or on the extra? | "Both bonuses grow by 3% for each Warden in that area, each up to 45%." (check) |
| grandfather_stump.tres | "aura gets 4% stronger for each Warden touching it, up to 45% faster in all" | +4 points or ×1.04? Is 45% the aura total? | "Its aura gives 4% more attack speed for each Warden touching it, up to 45% in all." (check) |
| acorn.tres / elder_stump.tres | "a second Acorn's boost on the same Warden counts half" | And the third? | "each further Acorn's boost counts half" or "a third adds nothing" (check) |
| prism_jar.tres | "crit X more often, for Y more damage. Two Prisms don't add up." | Percentage points or relative? Do Prism Jar and Rainbow Prism add up? | "+X crit chance (points) …; only the strongest Prism aura counts." (check) |
| full_moon / starlit_aim / still_target | "gain 25% crit chance" / "25% extra crit chance" | Points or relative? Three wordings for one thing. | One form: "+25% crit chance". Full Moon's overflow rule already shows they're points; say it once in the Crit glossary. |
| patient_aim.tres | "crit chance rises 15% for each second it hasn't attacked, up to +45%" | Does it reset on every attack? Points? | "+15% crit chance for each second since its last attack, up to +45%; resets when it attacks." |
| icon_info `crit_damage` / crit glossary | "How much harder a critical hit lands" | The base crit multiplier differs by Warden (×2.5, ×4…); players don't know Sharpened Light's base. | Glossary: "Each Warden's crit multiplier shows on its panel." |
| sharp_beaks.tres | "Multi-hit Wardens hit 2 more times with each attack" | Jewelwing Court has 3 birds: +2 per bird or +2 in all? | "…2 more pecks per bird" (check) |
| hummingbird_bower.tres | "six times in a second; every peck is a full hit" | Is the damage stat per peck? | "each peck deals its full damage" (fine if so) |
| quick_draw.tres | "When a nightmare enters a Warden's range, the Warden's next attack is ready at once." | No limit stated. Code (checked) has no cooldown, so a stream of entries keeps resetting the cooldown; vets will ask. | "Each time a new nightmare enters…, its next attack is ready at once." (Balancing should know it is uncapped) |
| quickening.tres (Hunt's Rush) | "attacks 30% faster for 4 s" | Does another dispel stack or refresh? The II version explains; the base doesn't. | Tip: "Another dispel restarts the 4 s." (check) |
| close_shave.tres | "all Wardens attack 30% faster for 8 s" | Do several Heartwood arrivals stack? | Tip: "Another arrival restarts the 8 s." (check) |
| thinning_the_herd.tres | "for the rest of the {drift}" | Drifts overlap when called early: which drift? | "until the next {rest}" or "until this drift's last nightmare is gone" (check) |
| desperate_bloom.tres | "less than half its {leaves}" | Half of the maximum, or of the starting leaves? | "less than half its maximum {leaves}" |
| few_and_mighty.tres | "With fewer than 12 attacking Wardens" | Do Sprouts count? (Last Light says yes.) | Add a tip: "Sprouts count; walls don't." (check) |
| odd_one_out.tres | "no other Warden of the same form" | Sprouts and walls? | Tip: "Sprouts and walls never get it." (check) |
| rootbound.tres | "touching 3 or more other Wardens" | Do walls count among the 3? | "…3 or more other Wardens (walls count / don't)" (check) |
| forest_floor.tres tip | "Withered Trees and Mossy Boulders count." | Do Fallen Logs, Thorn-Saplings, the Fallen Giant gift count? | "Any obstacle counts: Withered Trees, Mossy Boulders, Fallen Logs, Thorn-Saplings." (check) |
| spore_cascade.tres | "half its {stacks}…spread to the 2 nearest nightmares" | Each gets half, or the half is split between them? | "each of the 2 nearest gains half its {stacks}" (check) |
| spillover.tres / edgestone.tres | "the leftover damage hits nightmares within 1 cell" | Each takes the full leftover? | "each nightmare within 1 cell takes the leftover damage" (check) |
| great_ripple.tres | "hits again 1 s later in a ring 1 cell wider" | Only the new outer ring, or the whole widened area? Do clouds count as "splash"? | "hits again 1 s later over an area 1 cell wider, for half damage. Clouds don't." (check) |
| dream_echo_hollow | "one nearby repeats" | "Nearby" is banned (§1: "in range"). | "one in its range repeats…" |
| dream_pinwheel / windmill.tres | "stronger the more of those cells are path" / "35% more damage for each extra path cell" | Extra beyond what? | "+35% damage for each path cell among the 8 around it beyond the first" (check) |
| hairpin_winds tip | "Path cells: the cells around it that the path runs through." | OK, but the Windmill and Pinwheel wordings differ. | Use one phrase: "path cells among the 8 around it" |
| bastion.tres | "Heavier hits. Every N s each Thornwall beside it drops a rock" | Rock damage? Do Brambles count? | (check) |
| jetreed.tres | "takes X of its target's max health (0.5% on bosses)" | The Codex Erosion cap "never more than 4× the hit itself" is missing here. | Add: "never more than 4× the hit" |
| nestling / wrens_nest / starling | "Extra damage to Phantoms" | How much? Phantoms only, or all flyers? | "+N% damage to {nightmare:dandelion_seed}s" (check) |
| hobble.tres / switchback / rockslide / gift Bell Stone | "slowed 30% for 1 s" etc. | Slows stack, and there is a hidden floor ("Slowed to the limit"). | Glossary "Slow": "Slows from different sources add up to a limit." (check `slow_capped`) |
| icon_info `drowsy` | "walks 2% slower per stack" | Same floor. Does Potency raise it? (the Potency glossary says yes) | "2% slower per stack (more with Potency)" |
| icon_info `asleep` | "a big hit (10%+ of its health) wakes it" | Current or max health? | "(a hit of 10% or more of its maximum health)" (check) |
| icon_info `held` | "Builds up to N stacks; …can't move while it lasts" | How long does Root last: does each source set its own time, and do stacks extend it? | "Each Root lasts the time its source gives; more stacks don't lengthen it." (check) |
| sporemother.tres | "(2 {spored} each)" | Per second, while the cap is 80: say "per second". | "Every second … 2 {spored} to everything in range" (already in the dream text) |
| monsoon / morning_fog | "{damp} for N s" | Does Soak's duration normally differ? Fine; keep. | — |
| silver_bell.tres | "the strongest nightmare" | Most health left (as the target mode says) or Deeply Blighted? | "the nightmare with the most health left" |
| vesper_bell.tres | "the next strongest for half damage" | Same. | Same. |
| graftling / grafted_elder | "strongest neighbour" | By damage per second, or by damage? | "the neighbouring Warden with the highest damage" (check) |
| dewcatcher.tres | "drop X more {dew}" | Does it stack with another catcher? The answer ("only the strongest catcher in range counts") is only in the Warden header tooltip. | Add to the description: "Only the strongest catcher in range counts." |
| dew_bowl grows_text | "catch 15% more {dew}" | +15 points on the catch share, or ×1.15? | "catch share +15%" or "catch 15% more than they do now" (check) |
| morning_dew.tres | "every {drift} holds 10% more {dew}" | Fine; "pot" is the defined word. | "every {drift}'s Dew pot is 10% bigger" (matches Scarred Bark) |
| blood_moon / bountiful_night | "give 40% more {dew}" | The Dew pot is fixed per drift (Codex): is the pot bigger, or does each nightmare pay more? | "each {drift}'s Dew pot is 40% bigger" (text_pass.md already asked for this) |
| omen giants_walk | "each with 2.4× health" | OK. Does the Dew pot stay the same (half as many nightmares sharing it)? | Add "same Dew pot" (check) |
| omen hollow_wind | "For the next 5 {drifts}: the first 3 are all flyers." | The first 3 drifts, or the first 3 nightmares? | "the first 3 of those {drifts} are all flyers" |
| omen tramplers | "each {drift}, the first nightmare to pass a Thornwall tramples it" | One wall per drift, or the first nightmare at each wall? | "each {drift}, one Thornwall is trampled: the first one a nightmare passes" (check) |
| omen burrowers | "burrow 2 cells ahead" | Path steps or straight-line cells? | "2 {steps} ahead" |
| omen frozen_ground | "no planting, growing, selling or Nurture during a {drift}" | Does clearing count? | (check) |
| omen wilting / fog_bank | "22% slower" / "1 less range" | Before or after Dream bonuses? | Fine as is; low risk |
| heartwood_gifts | "Each one pays {dew:60} × the {act}" | "× the act" means the act number? | "{dew:60} × the act number (act 2: 120)" |
| tangled_release / rootcurl / tidecaller tower / long_way_home tower / heartroot | "pulled back 1 cell", "back N cells" | The dream_ versions say "{steps}"; distance along the path is a step (glossary). | Use "{steps}" everywhere a pull moves along the path |
| tidecaller dream vs tower | "pushes it back 1 {step}" vs "drags it back 1 cell along the path" | Two wordings for one effect. | "pulls it back 1 {step}" (one verb) |
| last_stand / forests_edge | "within 4 cells of the Heartwood" | Straight-line square (as "near" is), or path steps? | Fine per the Cell glossary; add "in a straight line" once to the Cell entry |
| solitude caption | "No other attacking Warden within 2 cells" vs text "{near}" | Fine, consistent. | — |
| rooted_nightmares / eternal_static / rootling.tres | "Every 8th hit from a Warden" / "Every 4th hit" | Counted per Warden, or per Warden and nightmare? How do area pulses count (Rootling pulses)? | Use Old Hand's wording: "Counted for each Warden; an area attack counts once." (check per card) |
| first_frost.tres | "The first 5 nightmares of each drift to enter an attacking Warden's range" | Any Warden's range, in total, or per Warden? | "The first 5 nightmares each {drift} that come into any attacking Warden's range" (check) |
| afterroot / opening_fracture / refrain | "Each nightmare once every 4 s" / "Each Warden once every 4 s" | Clear, but the subject changes between cards. Good as written. | — |
| knell.tres | "Each nightmare once every 6 s" | Fine. | — |
| da_capo.tres | "Every 6 s, a bell's next attack…" | One clock per bell, or one shared clock? | "Every 6 s, each bell's next attack…" (check) |
| encore.tres | "can echo once more, at half strength" | Half of the echo, or half of the original? | "once more, at half the echo's strength" (check) |
| reprise.tres | "goes off again 1 s later at half damage" | Can it also be echoed by an Echo Hollow? The tip says no. Fine. | — |
| mixed_grove / mixed_grove_ii | "for each other {family} among the Wardens…" | Do Sprouts count as a family? | Tip: "Sprouts and walls aren't a family." (check) |
| close_kin.tres | "{kinships} reach 3 cells." | From 2. Say the base. | "{kinships} reach 3 cells instead of 2." |
| the_old_ones.tres | "count 2 {ranks} higher" | For what: damage and speed only, or Nurture choices and signatures? | "…count 2 {ranks} higher for damage, speed and range" (check) |
| elder_kin.tres | "share 25% of their {rank} bonuses" | The bonuses from rank alone, or from Nurture choices too? | (check) |
| specialist.tres | "double the bonus from each {rank}" | Base rank damage too, or only the choice? | "double the bonus of each Nurture choice" (check) |
| signatures ALL_ROUNDER / MASTERY / Codex | "its main job is 20% stronger" | What is the main job of a support Warden or of Dewcatcher? | Name it per Warden in the panel ("Main job: damage") (check) |
| codex Rank / icon_info `rank` | "each rank adds damage and attack speed" | No numbers; range also grows (+0.1 per rank, per CLAUDE.md). | "each rank adds 10% damage, 4% attack speed and 0.1 range" (check current values) |
| icon_info focus_swift | "Attacks faster: +12%." | Fine. Power reads as a verb, Swift as a number: mixed. | "Attacks 12% faster." |
| codex Dread shell / nightmare_icons | "absorbs part of every hit" | A flat amount per hit or a percentage? This decides the whole counter-play (Hard Bark "75% thicker"). | "absorbs up to a set amount of every hit, so big hits get through best" (check `coat_per_hit`) |
| hard_bark omen | "{dread_shells} are 75% thicker" | More total, or more blocked per hit? | (check) |
| bulky (nightmare_icons) | "Area hits deal less to it." | How much less? | "Area hits deal N% less to it." (check) |
| deep_sleep.tres | "Wardens' hits deal 80% more damage to nightmares carrying 2 or more statuses" | Clear. Two different statuses, or 2 stacks? Elsewhere the text says "2 different statuses". | "2 or more different statuses" |
| high_tide / seeping / nightshade / knell | "for each status on the nightmare" | Root counts? Knell says no; the others are silent. | Tip: "Each different status counts once; Root does (or doesn't)." (check) |
| nightshade.tres | "statuses from 3 different families" | Statuses don't have families in the player's model; families do. | "on nightmares carrying 3 or more different statuses" if that is the rule (check) |
| crowd_breaker | "for each nightmare they hit" | Counting the first? | "+10% for each nightmare beyond the first" (check) |
| lingering_splash | "Patch: 1 cell wide" | Fine. | — |
| wild_dew | "rolled between 60% and 160%" | Uniform? Fine. | — |
| glimmering_hunt | "30% chance" | Good. | — |
| hot_on_their_heels | "until the {rest}" | The next rest. | "until the next {rest}" |
| ember_count | "Every {reaction} this {block} makes {reactions} 1% stronger" | Fine. | — |
| walking_wood | "Both wait 2 s before attacking; you can swap again after 10 s" | Fine. | — |
| codex Toll | "Every 4th ring on a nightmare: the ring lands again at half damage." | Every 4th from any bell, or per bell? | (check) |
| codex Harmony strike | "(at most every 2 s per pair)" | Good. | — |
| icon_info `caught` | "near a Dreamcatcher" | "Near" is a keyword (2 cells), but Caught works in range. | "in a Dreamcatcher's range" |
| codex `caught` combo | "{asleep}, or at {full} {drowsy}, near a Dreamcatcher" | Same. | Same. |
| warden_header catcher line | "Only the strongest catcher in range counts." | Range of what, the catcher's? | "If several catchers reach a nightmare, only the strongest counts." |
| dream_screen | "Grows with %s: %s" | Fine. | — |
| icon_info `silenced` | "A Silence … keeps it 2 s longer" | Silence.tres uses a token; this one is hardcoded. | Token (check) |
| card_scene legend :206 | "Covered bends: 25% slower for 1 s; 3 s per-nightmare cooldown" | "Cooldown" is jargon, but readable. | "…at most once every 3 s per nightmare" (matches the card) |

The table has 87 rows. With the 10 above, 97 strings are flagged in all.

---

## 3. Conventions: one fixed phrasing each

These are based on what the text mostly does already.

1. **Damage bonus:** "deal N% more damage" (Warden side). "take N% more damage" (nightmare side). Add "from hits" when status, cloud and Reaction damage don't count, and "from everything" when they do. Never bare "more damage" on the nightmare side.
2. **Stacking with other cards:** every damage card ends its tip with either "Adds to your other Dream damage." or "Multiplies with your other Dream damage." A glossary entry gives the ×4 limit (see #1).
3. **Caps:** "up to +N%" for the card's own cap. Global caps (speed +150%, Exposure 40%, ×4, Wellspring interest) live in the glossary and are linked, never only in one card's tip.
4. **Duration:** "for N s". Restart behaviour is always stated: "Another X restarts the N s" or "It doesn't stack".
5. **Rate limits:** "Each nightmare once every N s" / "Each Warden once every N s" / "Once per attack". The subject comes first, as most cards already do.
6. **Counting:** "Every Nth hit, counted for each Warden; an area attack counts once" (Old Hand's wording, used everywhere).
7. **Chance:** "N% chance". Crit chance is always "+N% crit chance" (points), never "crits N% more often".
8. **Multipliers:** "×N" only with a stated base: "×12 the damage of the Warden that set it off". "Double / twice / half" only for true ×2 / ×0.5 (house rule).
9. **Distance:** "within N cells" (straight line, per the Cell glossary). Along the path: "N {steps}". Pulls and pushes always use {steps}.
10. **Who counts:** families by token ("a {family:sporeling} Warden" means any form). Base Wardens by {warden:} token. Walls and Sprouts: always state "Walls don't count" / "Sprouts count".
11. **Bosses:** "(bosses N)" right after the number, as Patient Roots and First Frost already do.
12. **Statuses counted:** "for each different status" / "{held} doesn't count".

---

## 4. What already reads clearly

- The tip pattern "Works for: …. Safe / A bet" plus the definitions in the tip ("Bend:", "Passed:", "Network:", "Called early:") sets the genre standard. It answers most Reddit questions before anyone asks them.
- Most rate limits are already explicit (Afterroot, Opening Fracture, Refrain, Knell, Witching Bend).
- First Light ("Status ticks count."), Millstone ("The splash is not an attack: on-hit cards skip it."), Shared Light ("It doesn't stack: another dispel refreshes the 3 s"), Sharpened Light (a worked example), and Starlit Aim's "Uses up 5 stacks, or 10 with Brimming" are model texts.
- Boss exceptions are given in place on most control cards (Patient Roots, Root Web, Rooted Nightmares).
- Whetstone ("below 30% health deal ×2.5 damage (×1.5 on bosses)") and Endless Rings (prices per rank) read like a wiki entry.
- The Omens are almost all a single clear clause with a number.
- The Codex definitions of Touching, Near, Cell and Step give the game a real distance vocabulary. The gaps above are the places that don't use it yet.
