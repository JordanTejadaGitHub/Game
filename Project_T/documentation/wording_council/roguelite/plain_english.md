# Plain English seat: Roguelite round (2026-10-24)

Seat: second-language readers and future translators. Corpus: corpus_cards.txt (NEW text only, RETIRED skipped) and
corpus_scripts_diff.txt ("+" lines). Judged as the player sees it (icon_info.gd names: {damp} = Soak, {static} = Charge,
{held} = Root, {spored} = Poison, {marked} = Exposure; statuses are nouns, "nightmares with {damp}", never
"{damp} nightmares"). House ruling kept: "Works for: … Safe." / "A bet:" tags are not flagged (R3.3 ruling).

## 1. Top 10 problems

| # | Where | Now | Problem | Rewrite |
|---|---|---|---|---|
| 1 | `calling_paths.gd:66` Clump tip | "Each step eats one {mushroom}. New ones join within 3 {steps}." | Round 3 avoid words are back: "eat" (invented verb) and plain "step" right next to the {steps} token (path cell). "join" what? | "Each time a nightmare walks onto a clump, 1 {mushroom} there is used up. A new {mushroom} within 3 {steps} of a clump joins it." |
| 2 | `dream_reaction_cards.gd:203` | "Reactions triggered: %d this run (you: %d)" | The first number is the *requirement*, but it reads as a count of what happened ("Reactions triggered: 5 this run"). "(you: 2)" is a fragment. Also a code-built sentence. | "Needs %d Reactions triggered this run (you have %d)" (one full string, both numbers as named placeholders for translators). |
| 3 | `conductive_soil.tres` | "A {family:firefly_jar} Warden's hit on a {damp} nightmare also {jumps} to up to 4 {damp} nightmares within 2 cells." | Breaks the status-noun rule twice: on screen "a Soak nightmare", "4 Soak nightmares". No amount for the jump (check: CONDUCTIVE_SHARE 0.5). | "A {family:firefly_jar} Warden's direct hit on a nightmare with {damp} also {jumps} for half its damage (check) to up to 4 other nightmares with {damp} within 2 cells. Each Warden once a second." |
| 4 | `calling_paths.gd:78` Toadstool Throne | "…the throne's last {mushroom} is never eaten, so its {free_hits} go on." / tip "…selling resets it. A throne still takes new {mushrooms}, up to 4." | "eaten", "go on", "takes" are all on the avoid list (round 3 additions); "resets it" (age? throne?). | Text: "…the throne's last {mushroom} is never used up, so its {free_hits} keep coming." Tip: "…Growing a Warden keeps its age; selling the Warden resets its age. A throne still gathers new {mushrooms}, up to 4." |
| 5 | `calling_paths.gd:187` Moth to Flame | "…saves a crit on that nightmare for your top gold-dispel Warden: +50% after 4 more direct hits." | "top gold-dispel Warden" is a noun stack learners can't unpack; "+50%" of what (check: crit damage?); "after 4 more direct hits" from anyone, on that nightmare? | "…saves a crit on that nightmare for the Warden with the most gold dispels. After 4 more direct hits on that nightmare (check), that Warden's next hit on it crits for +50% (check: crit damage)." |
| 6 | `calling_paths.gd:216` Lantern Wake, `:213` Show the Way | "A nightmare hit directly by a Warden lit by Lantern Wake stays {lit}…" / "in full from a Warden lit by Lantern Wake" | "lit" has two game meanings in one sentence: a *Warden* lit by the card (plain verb) and a *nightmare* that is {lit} (the token). | Use another verb for the Warden: "A nightmare hit directly by a Warden that Lantern Wake lights up stays {lit}…" or better a fixed noun: "a Warden in Lantern Wake's light" (check what the game shows). Same in Show the Way. |
| 7 | `eddy.tres` | "{family:whirligig} Wardens' hits copy half the target's statuses to the next nightmare ahead and behind." Tip "Never copies {held}, sleep or {caught}." | "half the target's statuses" reads as half of the *number* of statuses (2 of 4), not half of each status's {stacks}. "sleep" is an unlinked plain word next to the {asleep} status. | "{family:whirligig} Wardens' hits copy half of each of the target's statuses ({stacks}) to the nearest nightmare 1 {step} ahead and the nearest 1 {step} behind (check). Each Warden once a second." Tip: "Never copies {held}, {asleep} or {caught}." |
| 8 | `the_tallest_tree.tres` | "…up to 40 of its hits. Each of its attacks spends up to 6 of its own hits' worth." | "hits' worth" is an idiom; "its"/"its own" ×4; "up to 40 of its hits" reads as a count of hits, not an amount of damage. | "…add 20% of their damage to its stored damage. It can store up to 40 times its own hit damage. Each of its attacks uses stored damage up to 6 times its own hit damage." |
| 9 | `calling_paths.gd:314` Coda | "After a Symphony, each Warden in it has its next hit within 4 s, on any nightmare, repeat at half damage." | Causative "has X repeat" is hard for learners and translators; "in it" + "its" ×2. | "After a Symphony, the next hit from each Warden in it, within 4 s and on any nightmare, repeats at half damage." |
| 10 | `trophies.tres` | "…its direct hits deal 4% more damage for the rest of the run, up to +40%." | "the rest" is on the avoid list (Rest is a game term). | "…its direct hits deal 4% more damage until the run ends, up to +40%." |

## 2. Every other flagged string

| Where | Now | Problem | Rewrite |
|---|---|---|---|
| `charged_feathers.tres`, `pollen_beaks.tres` | "Each hit from a {family:nestling} Warden adds 1 {stack} of …" + tip "Once a second per nightmare for each Warden." | "Each hit" claims too much: the tip limits it to once a second and direct hits. Tip breaks rule 3 (subject first). | "A {family:nestling} Warden's direct hit adds 1 {stack} of {static}." Tip: "Each Warden once a second on each nightmare. …" (same for {spored}). |
| `resonance.tres` | "{family:bellflower} Wardens' hits add 1 {stack} of {static}." Tip "Direct hits only: never repeats or ticks." | "never repeats" reads as "the card never repeats"; "ticks" is jargon. Tip rate line as above. | Tip: "Each Warden once a second on each nightmare. Direct hits only: not repeated hits or status damage." |
| `chain_bloom.tres` | "An Area Warden's splash … spreads half again as wide." | "half again as wide" is an idiom most learners don't know; "Area Warden" unlinked. | "…on a nightmare with 2 or more statuses is 50% wider." (check: ×1.5 vs +1.5 cells, CHAIN_BLOOM_RADIUS) |
| `loose_stones.tres` | "Every 3rd hit from a {family:pebbling} Warden breaks into 3 stones, each hitting a nearby cell for 35% of the hit." Tip "Nearby: within 1 cell, corners too." | A *hit* can't break into stones; "nearby" is unlinked (avoid list: near/around) and needs its own tip to define. | "Every 3rd direct hit from a {family:pebbling} Warden breaks its stone into 3 pieces. Each piece hits a random cell within 1 cell, corners too, for 35% of the hit's damage." Tip: "Pieces never break again. Safe." |
| `needle_point.tres` | "Every 3rd hit from a {family:nestling} Warden ignores the {dread_shell}." | Commit: direct hits only (FAMILY_EVERY counts original direct hits). | "Every 3rd direct hit from a {family:nestling} Warden ignores the {dread_shell}." |
| `grandfather_stump.tres` | "…speed auras grow 4% for each Warden {touching} them…" | "grow" = change form (avoid list). | "…speed auras get 4% stronger for each Warden {touching} them, up to 45%." |
| `starlit_aim.tres` | "Heavy Wardens get…" Tip "Heavy: the Warden header's Heavy tag. Not {static} or {held}." | The {heavy} token exists but isn't used, so the tip has to explain it awkwardly. "Not {static} or {held}" has no verb: not counted? not halved? (commit says the halving never touches Root or Drowsy: check). | "{heavy} Wardens get +25% crit chance on nightmares with a {full} status." Tip: "{static} and {held} don't count as a {full} status here (check). Direct hits only." |
| `starlit_aim.tres` cost | "A crit uses up half of that status's {stacks}." | "that status" if two are {full}? (check) | "A crit uses up half the {stacks} of one {full} status (check which)." |
| `guiding_light(_ii).tres` | "…also {jumps} for half to every nightmare within 1 cell." | "for half" is compressed: half of what? | "…also {jumps} to every nightmare within 1 cell for half the hit's damage." |
| `unfettered.tres` tip | "Each Calling hit still comes only as often as its row allows. Bosses still take less." | "row" is UI jargon and also in "in a row" (Bearing Down); "comes" vague; "less" with no number. | "Each Calling hit still has its own limit (once every N s, shown on its Calling choice) (check). Bosses still take a smaller share (check number)." |
| `bearing_down.tres` | "…for each attack in a row on one nightmare…" | "in a row" idiom, and "row" means a Calling row elsewhere. | "…for each attack on the same nightmare without changing target, up to +10% per {rank}." |
| `clean_strike.tres` tip (carried over from round 3, not fixed) | "A family that puts no status never gets it." | Double negative + unclear "it". | "A family whose Wardens put no status can't get this bonus." |
| `standing_tall.tres` | "…per attacking Warden below a {final_form} {touching} them…" | "below" reads as a position on the map. | "…per attacking Warden {touching} them that is not yet a {final_form}…" |
| `open_road.tres` tip vs Calling tips | "Flyers don't count." vs new "Flyers over the path count; the Phantom never." | Two rules for flyers in one round; learners will assume one is wrong. | (check) If Open Road should follow the new route-flyer rule, use the same sentence. |
| `calling_paths.gd:34, :41, :257` | "Flyers over the path count; the Phantom never." | Elliptical "never" with no verb. | "Flyers over the path count; Phantoms never do." |
| `calling_paths.gd:34` (unchanged half) | "A nightmare that starts its route again starts counting again." | "route" (round 3 avoid: = path); "starts … starts". | "The count starts again when a nightmare goes back to the start of the path." |
| `calling_paths.gd:102` Host Trees | "Shared Caps' Warden at each {mushroom}… Without a damaging status, its direct hits on {spored} nightmares deal 15% more damage." | "{spored} nightmares" breaks the noun rule ("Poison nightmares"); "Without a damaging status" (whose?). | "…+15% {potency}. If that Warden's status deals no damage, its direct hits on nightmares with {spored} deal 15% more damage instead." |
| `calling_paths.gd:148` Early Lamps tip | "First half: of the path it walks (flyers: of their flight)." | Still elliptical; "it" has no noun. | "First half: the first half of the nightmare's path (for flyers, of their flight). The lantern relights…" |
| `calling_paths.gd:156` Flare text | "A nightmare entering a glow within 4 {steps} of its last takes a {flare}: 25% of the Firefly's damage per streak glow…" | "its last" (last what?); "streak glow" noun stack. | "A nightmare that enters a glow within 4 {steps} of the last glow it entered takes a {flare}: 25% of the Firefly's damage for each glow in its streak, up to 150%." |
| `calling_paths.gd:187` Moth tip | "Until someone has one, last block's holder keeps it." | "someone" for a Warden; "it" = the role. | "Until a Warden has one this block, the Warden that held it last block keeps it." |
| `calling_paths.gd:207` Borrowed Light tip | "Before your second family, Firefly hits count too. … Never the same nightmare as another card's {jump}." | "Before your second family" (before you pick it); last sentence has no subject. | "Until you pick a second family, Firefly hits count too. … This {jump} never goes to the same nightmare as another card's {jump} from that hit." |
| `calling_paths.gd:222` Constellation | "…a star lights over it: its next 3 hits {jump} in full." Tip "{Jumps} go to the healthiest. … Another family's {jump}…" | "its next 3 hits" reads as the nightmare's hits; "the healthiest" what; "Another family's {jump}" compressed. | "…a star lights over it: the next 3 hits on it {jump} in full." Tip: "These {jumps} go to the healthiest nightmare. … A {jump} from another family's Warden deals at most 3 s of the glowing Firefly's damage." |
| `calling_paths.gd:282` Lone bell | "…makes a {toll} every 3rd {ring}…" / tip "…on one makes a {toll}." | The nightmare doesn't *make* a {toll}; it gets one. | "…gets a {toll} every 3rd {ring}, in full, not every 4th at half." Tip: "…so a lone bell's first {ring} on a nightmare gives it a {toll}." |
| `calling_paths.gd:278` middle bell | "Its {rings} still count for the last bell." | "Its" after a sentence about the bell = the bell's rings? | "The nightmare's {rings} still count for the last bell." |
| `calling_paths.gd:295` | "Two {rings} on one nightmare within half a second count as one {ring}, doubled or not." | "half a second" (rule: N s); "doubled or not" unclear (check). | "Two {rings} on one nightmare within 0.5 s count as one {ring}, even if one of them is doubled (check)." |
| `calling_paths.gd:303` Accompaniment | "…join its song, bells too. At a {toll}, the last joined Warden to ring it…" Tip "A joined Warden's hit rings the nightmare…" | "bells too" now hangs after "song"; plain verb "ring/rings" next to the {ring} token (round 3 pattern). Low: R4 asked for "join its song". | "Wardens {touching} a bell, other bells included, join its song. At a {toll}, the joined Warden that gave the nightmare its last {ring} repeats its hit at half damage." Tip: "A joined Warden's hit gives the nightmare a {ring}, once a second, Sprouts too…" |
| `calling_paths.gd:424` Still Water | "…stop wearing off ({lingering}) for up to 4 s." | "wear off" (round 3 avoid). | "…don't run down ({lingering}) for up to 4 s." |
| `calling_paths.gd:440` River Mouth | "…on another family's Warden's first direct hit on each nightmare." | Double possessive. | "The last 3 {steps} of each stretch of {water} also get River Mouth's bonus: the first direct hit on each nightmare there from another family's Warden gets it." |
| `callings.gd:30` firefly DETAILS | "A crit this Calling saves or forces counts as a crit for nothing else." | Inverted negative ("for nothing else") is hard to parse. | "Crits this Calling saves or forces don't count as crits for other cards." |
| `gathering_storm.tres` tip | "A bet: pays when several {jump} cards hit one group." | Tag is kept by ruling, but "pays" is a separate avoid word (money idiom). | "A bet: works when several {jump} cards hit one group." |
| `patient_aim.tres` tip | "Works for: Wardens that attack slowly." | Vague; Unfettered now uses the exact form "less than once a second". | "Works for: Wardens that attack less than once a second (check). Safe." |

## 3. Patterns

- **Status tokens as adjectives are back** ("a {damp} nightmare", "{spored} nightmares"): always "nightmares with {damp}".
- **Mushroom verbs** ("eats", "eaten") and phrasal "go on" / "wear off" returned in rewritten rows: use the round 3 table.
- **Same word, two meanings in one sentence:** "lit" (Warden) vs {lit} (nightmare); "step" vs {step}; "row" (Calling) vs
  "in a row". Pick another verb for the non-token meaning.
- **Rate-limit tips** ("Once a second per nightmare for each Warden"): subject first, "Each Warden once a second on each
  nightmare" (rule 3), and the card line should then say "direct hit", not "each hit".
- **Ellipsis to save words** ("the Phantom never", "Not {static} or {held}", "for half", "First half: of the path"):
  every rule sentence needs its verb and its noun.
- **Token nouns as verbs mostly fixed** ({toll}, {water}), but "makes a {toll}" replaced one bad verb with another: "gets a {toll}".
- **Possessive chains** ("another family's Warden's", "Shared Caps' Warden", "top gold-dispel Warden"): use "from"/"with".

### Words to avoid (additions this round)

| Avoid | Use instead |
|---|---|
| half again as wide | 50% wider |
| hits' worth | times its hit damage |
| in a row (repeated attacks) | without changing target |
| makes a {toll} | gets a {toll} |
| lit (verb, for Wardens) | lights up / in its light (check) |
| for nothing else | doesn't count for other cards |
| "sleep" (plain) | {asleep} |

## 4. Localisation risks (code-built strings in this diff)

| File:line | String | Risk |
|---|---|---|
| `dream_reaction_cards.gd:200, :203` | `"Reactions triggered: %d this run (you: %d)" % [...]` | Two unnamed %d in fixed order; translators can't reorder; meaning of each number is unclear. Use named placeholders. |
| `dream_hit_cards.gd:445` | `"The Tallest Tree: %d stored damage"` appended to `parts` | Card name hard-coded in English instead of from the card data; number-noun order; parts are joined by code. |
| `puddles.gd` (diff +2947) | `name = "Wading"` | Player-visible label (check) set in code, outside the text pipeline. |

## 5. What already works

- R3 fixed: no {toll}/{tolls} as a verb in Last Bell, middle bell, Allegro; "stretch of {water}" used everywhere.
- "pack" is gone from Gathering Storm / Struck Twice; no "Stream" or bare "Finale" in this corpus.
- Hit cards now all say "deal N% more damage" and "Direct hits only."
- Unfettered's "less than once a second" is exact and plain; Retinue's "At most 2 other Wardens" is clear.
- Constellation and Host Trees now put the condition first.

Flagged: 10 top + 31 table rows = 41 strings, plus 3 localisation risks.
