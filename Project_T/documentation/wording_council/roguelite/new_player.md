# New player seat: Roguelite round 2026-10-24

Seat: I've played a few mobile games and never a tower defence or roguelite. I judge one read, about 5 seconds: what
happens, to what, when, how much? Tokens are read as shown on screen ({damp} = Soak, {static} = Charge, {held} = Root,
{spored} = Poison), with a glossary tap. "Works for: … Safe / A bet" lines are house convention and not flagged.

## 1. Top 10 problems, ranked

| # | Where | Now | Problem | Rewrite |
|---|---|---|---|---|
| 1 | calling_paths.gd:190 / :194 (Pyre, Banked Fire) | "a Warden with 50+ gold dispels crits on every 2nd direct hit." | Garden path. "gold dispels crits" reads as subject + verb ("the gold dispels the crits"). I read it twice and still wasn't sure who crits. | "There, every 2nd direct hit crits if its Warden has 50+ dispels on gold path." / Banked Fire: "…there, every 3rd direct hit crits if its Warden has 50+ dispels on gold path." |
| 2 | eddy.tres tip | "Never copies {held}, sleep or {caught}." | Plain "sleep" in rules text goes against the Drowsy ruling: is it {drowsy} or {asleep}? (check: the code note only says "never Rooted") | "Never copies {held}, {drowsy} or {caught}." (or {asleep}, whichever the code skips) |
| 3 | starlit_aim.tres | desc "Heavy Wardens get +25% crit chance on nightmares with a {full} status." tip "Heavy: the Warden header's Heavy tag. Not {static} or {held}. Direct hits only." | "Heavy" is new jargon, and the tip sends me to a part of the screen instead of saying what it is. "Not Charge or Root" has no verb: no crit bonus on them, or no spending? | desc same. tip: "Heavy Wardens have the Heavy tag on their panel. A full {static} or {held} doesn't count. Direct hits only." (check that the full-Drowsy exclusion in spend_half shouldn't be listed too) |
| 4 | chain_bloom.tres | "An Area Warden's splash on a nightmare with 2 or more statuses spreads half again as wide." | "Area Warden" is capitalised as if it were a name and isn't explained. "half again as wide" is an idiom: I can't tell if it's x1.5 or +1.5 cells (code says "CHAIN_BLOOM_RADIUS 1.5 wider", check). | "Splashes that hit a nightmare with 2 or more statuses are 50% wider." (or "1.5 cells wider", whichever the code does). If Area has to stay: "area Wardens' splashes…" |
| 5 | eddy.tres desc | "{family:whirligig} Wardens' hits copy half the target's statuses to the next nightmare ahead and behind. Each Warden once a second." | "half the target's statuses" reads as half of the list (1 of 2 statuses), but it's half the stacks of each one. "Each Warden once a second" has no verb. | "{family:whirligig} Wardens' hits copy half of each status's {stacks} to the nearest nightmare ahead and the nearest behind, 1 {step} away. At most once a second per Warden." |
| 6 | spore Calling, Shared Caps (calling_paths.gd:102) | "Shared Caps' Warden at each {mushroom} wears a cap: +15% {potency}. Without a damaging status, its direct hits on {spored} nightmares deal 15% more damage." | "Shared Caps' Warden" is a card name used as a possessive owner. Who is the Warden? How is it picked? | "At each {mushroom}, one Warden wears a cap: +15% {potency}. If its status deals no damage, it gets this instead: its direct hits on {spored} nightmares deal 15% more damage." (check which Warden is picked; say so in the tip) |
| 7 | charged_feathers / pollen_beaks / resonance desc + tip | desc "Each hit from a {family:nestling} Warden adds 1 {stack} of {static}." tip "Once a second per nightmare for each Warden." | The description says every hit; only the tip says at most once a second. A new player trusts the big line. The tip stacks up three qualifiers. | desc: "{family:nestling} Wardens' hits add 1 {stack} of {static}, at most once a second on each nightmare." Same shape for Pollen Beaks ({spored}) and Resonance ({family:bellflower}). Then drop the cap from the tip. |
| 8 | unfettered.tres tip | "Each Calling hit still comes only as often as its row allows. Bosses still take less." | "row" is undefined (row of what? the Calling screen?). "take less": how much less? | "Each Calling hit still comes only as often as its Calling path allows. Bosses still take their reduced share." (check: name the number if one exists, e.g. "Bosses still take half.") |
| 9 | Firefly Calling, gold crit (calling_paths.gd:187) | "A Firefly's direct hit on gold path saves a crit on that nightmare for your top gold-dispel Warden: +50% after 4 more direct hits." | Three new ideas in one line: saving a crit, "top gold-dispel Warden", and a delay. "+50% after 4 more direct hits" doesn't say whose hit gets the crit. | "A Firefly's direct hit on gold path saves a +50% crit on that nightmare. After 4 more direct hits on it, your Warden with the most gold-path dispels gets it on its next hit." (check the order: whose hit is the 5th) |
| 10 | callings.gd:30 (Firefly details) | "A crit this Calling saves or forces counts as a crit for nothing else." | "counts as a crit for nothing else" is a puzzle sentence. | "Crits this Calling saves or forces don't count as crits for other cards." |

## 2. Other flagged strings

| Where | Now | Problem | Rewrite |
|---|---|---|---|
| loose_stones.tres desc | "Every 3rd hit from a {family:pebbling} Warden breaks into 3 stones, each hitting a nearby cell for 35% of the hit." | A hit can't break; the stone does. "35% of the hit" is vague. | "Every 3rd hit from a {family:pebbling} Warden breaks into 3 stones. Each hits a nearby cell for 35% of its damage." |
| loose_stones.tres tip | "Direct hits only: the stones never break again. Nearby: within 1 cell, corners too." | The colon joins two separate facts, so it reads as if one causes the other. | "Direct hits only. The small stones never break again. Nearby: within 1 cell, corners too." |
| the_tallest_tree.tres | "…Each of its attacks spends up to 6 of its own hits' worth." | Better than OLD, but "6 of its own hits' worth" of what? The noun is missing. | "…Each of its attacks adds up to 6 of its own hits' worth of stored damage." (check) |
| resonance.tres tip | "Direct hits only: never repeats or ticks." | "repeats" and "ticks" are jargon to me. | "Direct hits only, not repeated hits or damage over time." |
| conductive_soil.tres cost | "Every nightmare it {jumps} to loses its {damp}." | "it" = the hit, which takes a moment to work out. Fine otherwise. | "Each nightmare the {jump} reaches loses its {damp}." |
| grandfather_stump.tres desc | "{family:acorn} Wardens' speed auras grow 4% for each Warden {touching} them, up to 45%." | "grow 4%": 4% stronger or +4% attack speed? | "{family:acorn} Wardens' speed auras get 4% stronger for each Warden {touching} them, up to 45%." (check which one the code does) |
| patient_aim.tres tip | "Works for: Wardens that attack slowly. Safe." | "slowly" is vague. Unfettered already says "less than once a second". | "Works for: Wardens that attack less than once a second. Safe." (check the threshold) |
| gathering_storm.tres tip | "…Bosses take half. …" | OLD "half of each {jump}" said half of what. NEW lost the noun. | "Bosses take half of each {jump}." |
| Clump tip (calling_paths.gd:66) | "Each step eats one {mushroom}. New ones join within 3 {steps}." | Lost "on a clump": whose step, where? Worse than OLD. | "Each step a nightmare takes on a clump eats one {mushroom}. A new {mushroom} joins a clump within 3 {steps}." |
| Lantern tip (calling_paths.gd:148) | "First half: of the path it walks (flyers: of their flight)." | A fragment with a parenthesis inside. | "First half: the first half of the path it walks, or of a flyer's flight." |
| Flyer tips (calling_paths.gd:34, :41, :257) | "Flyers over the path count; the Phantom never." | Elliptical ("never" what?), and I don't know the Phantom yet. | "Flyers over the path count too, but never the Phantom." |
| Steady Beat (calling_paths.gd:282) | "A nightmare … makes a {toll} every 3rd {ring}…" / tip "…first {ring} on one makes a {toll}." | Last Bell / Halfway Bell say a nightmare "takes" a toll. Here it "makes" one. Two verbs for the same event. | "…takes a {toll} every 3rd {ring}…" / "…first {ring} on one gives it a {toll}." |
| Rings tip (calling_paths.gd:295) | "Two {rings} on one nightmare within half a second count as one {ring}, doubled or not." | "doubled or not" is unexplained. | "Two {rings} on one nightmare within half a second count as one {ring}, even if one of them is doubled." (check) |
| River Mouth line (calling_paths.gd:440) | "…on another family's Warden's first direct hit on each nightmare." | Stacked possessives. | "The last 3 {steps} of each stretch of {water} also get River Mouth's bonus: the first direct hit on each nightmare there from another family's Warden." |
| Firefly streak (calling_paths.gd:156) | "…takes a {flare}: 25% of the Firefly's damage per streak glow, up to 150%." | "streak glow" means nothing until the tip. | "…takes a {flare}: 25% of the Firefly's damage for each glow in its streak, up to 150%." |
| dream_reaction_cards.gd:203 | "Reactions triggered: %d this run (you: %d)" | "(you: N)" next to "this run" is confusing: is the first number the goal? | "Needs %d Reactions triggered this run (so far: %d)" (check the meaning) |
| Coda (calling_paths.gd:314) | "…each Warden in it has its next hit within 4 s, on any nightmare, repeat at half damage." | Grammatical but heavy. | "After a Symphony, each Warden in it repeats its next hit at half damage, if that hit lands within 4 s (any nightmare)." |
| Accompaniment (calling_paths.gd:303) | "Wardens {touching} a bell join its song, bells too." | "join its song" is flavour. The tip saves it, but the card alone doesn't say what joining does. | "Wardens {touching} a bell, bells too, join it: their hits ring nightmares for it." |

## 3. Patterns

- **Caps hide in the tip.** "Each hit adds 1" in the description, "once a second" in the tip. Put the limit in the same sentence as the effect.
- **New category words with no gloss:** Heavy, Area Warden, row, gold-dispel Warden, streak glow. Gloss each one inline the first time, or use plain words.
- **Possessive chains** ("Shared Caps' Warden", "another family's Warden's first direct hit"). Rewrite with "from" or "of".
- **Elliptical fragments** ("Each Warden once a second.", "the Phantom never", "First half: of…"). Give each one a verb.
- **Nouns dropped in trims** ("Bosses take half.", "6 of its own hits' worth"). When shortening, keep the noun the number applies to.
- **Idioms for numbers** ("half again as wide"). Use % or cells.

## 4. What works, and OLD vs NEW per card

NEW better: Afterroot, Bearing Down, Carried on the Wind, Charged Feathers (tip especially), Clean Strike, Conductive
Soil (limit and range now stated), Deep Frost (the OLD "Frozen" label was misleading), Finishing Blow, Grandfather
Stump, Guiding Light I/II, Hairpin Winds, Needle Point, Nowhere to Run, Open Road, Pollen Beaks, Resonance, Spinning
Corners, Standing Tall, Struck Twice ("group" not "pack"), Trophies, The Tallest Tree, Eddy (clearer target, but see #2
and #5), Gathering Storm (except "Bosses take half").
Mixed: Starlit Aim (wider rule, but "Heavy" is jargon), Loose Stones (simpler, but "a hit breaks"), Chain Bloom (any
family now, but "Area" and "half again").
NEW worse: Unfettered tip ("row"), the Clump tip ("Each step eats one").
Scripts better: Last Bell, Halfway Bell, star (pale path), Borrowed Light / Lantern Wake ("lit by"), stretch-of-water
lines, "The Tallest Tree: N stored damage", the "Direct hits only." wording everywhere.

Flagged: 10 top + 18 table = 28.
