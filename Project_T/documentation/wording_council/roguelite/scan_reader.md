# Scan reader: Roguelite round (2026-10-24)

Seat: mid-fight, on a phone. Corpus: corpus_cards.txt (32 changed live cards, RETIRED skipped), corpus_scripts_diff.txt
(changed Calling / Dream strings). Word counts treat a token as one word. Limits: card face 25, tip 40, button 4.
"Works for: … Safe / A bet" lines are the kept convention (R3.3 ruling) and are not flagged. "(check)" = I am unsure of
the mechanic; the commit message (badd7cb5) is my only source.

## 1. Top 10 problems

**1. The Tallest Tree is 38 words (was 33), the only card face over 25.** R6's "of its own hits' worth" fixed the
meaning but added 5 words, and the face still holds three numbers and three clauses.
- Now: "Choose one Warden: the Tallest Tree. Other Wardens' direct hits add 20% of their damage to its stored damage, up to
  40 of its hits. Each of its attacks spends up to 6 of its own hits' worth."
- Rewrite (face 27, cap to tip): "Choose a Warden: the Tallest Tree. It stores 20% of other Wardens' direct-hit damage.
  Each of its attacks adds up to 6 of its hits' worth." Tip: "It stores at most 40 of its hits' worth."

**2. Charged Feathers / Pollen Beaks / Resonance: the face says "each hit", the tip takes it back.** The tip adds
"Direct hits only" and a once-a-second limit, so the face oversells. Resonance also uses another shape ("Wardens' hits
add") than its two siblings ("Each hit from a … Warden adds"). Limiters belong on the face as their own short sentence
(T3).
- Now: "Each hit from a {family:nestling} Warden adds 1 {stack} of {static}." / tip "Once a second per nightmare for each
  Warden. Direct hits only. Works for: …"
- Rewrite, one shape for all three (12 words): "{family:nestling} Wardens' direct hits add 1 {stack} of {static}. Each
  Warden once a second per nightmare." Pollen Beaks: same with {spored}. Resonance: "{family:bellflower} Wardens' direct
  hits add 1 {stack} of {static}. Each Warden once a second per nightmare." Tips keep only "Works for: … Safe."
  (Resonance keeps "Never repeats or ticks.")

**3. Conductive Soil's face has no damage number.** The jump deals half (CONDUCTIVE_SHARE 0.5), but the face only says
it {jumps}. Guiding Light, its sibling, says "{jumps} for half". Its cost line also has an unclear "it" (rule 13).
- Now: "A {family:firefly_jar} Warden's hit on a {damp} nightmare also {jumps} to up to 4 {damp} nightmares within 2
  cells. Once a second per Warden." / cost "Every nightmare it {jumps} to loses its {damp}."
- Rewrite (24): "A {family:firefly_jar} Warden's direct hit on a {damp} nightmare also {jumps} for half to up to 4 {damp}
  nightmares within 2 cells. Each Warden once a second." Cost: "Each nightmare a {jump} reaches loses its {damp}." (Half
  is a placeholder for Balancing; keep the face in step with the number.)

**4. Eddy: "half the target's statuses" reads as half of the statuses (a count), not half of each one's stacks.** Its
add-on Carried on the Wind says "all of a status's {stacks} instead of half", so the two cards don't line up. The tip
uses "sleep" as a raw word (no token). "ahead and behind": one nightmare each side, or one in all? (check: the commit
says "to 1 nightmare 1 step either side").
- Now: "{family:whirligig} Wardens' hits copy half the target's statuses to the next nightmare ahead and behind. Each
  Warden once a second." / tip "Never copies {held}, sleep or {caught}."
- Rewrite (21): "{family:whirligig} Wardens' direct hits copy half of each status's {stacks} to the nightmares 1 {step}
  ahead and behind. Each Warden once a second." Tip: "Never copies {held}, {asleep} or {caught}." (check: is "sleep"
  {asleep} or {drowsy}?)

**5. Chain Bloom: "half again as wide" is an idiom, and it may be the wrong maths.** The commit says the splash is
CHAIN_BLOOM_RADIUS 1.5 wider; "half again as wide" means ×1.5 (check which). "An Area Warden's" is a raw capitalised
word, and the commit says "any splash".
- Now: "An Area Warden's splash on a nightmare with 2 or more statuses spreads half again as wide."
- Rewrite (14): "Splashes on a nightmare with 2 or more statuses reach 1.5 cells farther." (If it is ×1.5: "… are ×1.5 as
  wide.")

**6. Starlit Aim: "Heavy" is raw text explained in the tip, but a {heavy} token exists** (Hammerfall, Heavy Heart use
it). The tip "Not {static} or {held}" doesn't say whether those never count as full or are never spent. The commit says
the spend skips Root and Drowsy, not Charge (check).
- Now: "Heavy Wardens get +25% crit chance on nightmares with a {full} status." / tip "Heavy: the Warden header's Heavy
  tag. Not {static} or {held}. Direct hits only."
- Rewrite: "{heavy} Wardens get +25% crit chance on nightmares with a {full} status." Tip: "{static} and {held} don't
  count. Direct hits only."

**7. Grandfather Stump: "up to 45%" lost both its "+" and its unit.** Is 45% the bonus cap or the total speed? The old
card said "up to 45% faster in all". "grow 4%" is also vaguer than "4% stronger". The tip repeats the face.
- Now: "{family:acorn} Wardens' speed auras grow 4% for each Warden {touching} them, up to 45%." / tip "Only auras
  that make Wardens attack faster, not damage auras. Safe."
- Rewrite (13): "{family:acorn} Wardens' speed auras are 4% stronger per Warden {touching} them, up to +45%." (check
  "+45%" vs "up to 45% faster in all"). Tip: "Not damage auras. Safe."

**8. Loose Stones: "35% of the hit" has no noun, and "a hit breaks into stones" is a metaphor.** Its sibling Needle
Point (also "every 3rd hit", direct hits only per the commit) has no "Direct hits only" tip, so the two tips don't match.
- Now: "Every 3rd hit from a {family:pebbling} Warden breaks into 3 stones, each hitting a nearby cell for 35% of the hit."
- Rewrite (21): "Every 3rd direct hit from a {family:pebbling} Warden throws 3 stones, each dealing 35% of its damage to a
  random nearby cell." Needle Point: "Every 3rd direct hit from a {family:nestling} Warden ignores the {dread_shell}."

**9. Clump tip: "Each step eats one {mushroom}" dropped "on a clump",** so it reads as every step anywhere. It is 40
words, right at the cap.
- Now: "… Each step eats one {mushroom}. New ones join within 3 {steps}. …"
- Rewrite: "… Each step on a clump eats one {mushroom}. New ones join within 3 {steps}. …" (+3 words; to stay at 40,
  cut "Damage only: no status." to "No status.")

**10. "Flyers over the path count; the Phantom never." (3 tips) ends on a clipped "never",** and gives the Phantom by raw
name. "Phantoms" is on the avoid list as a word for flyers, so the raw name reads like the old mix-up. Use the nightmare
token.
- Now (calling_paths.gd :34, :41, :257): "Flyers over the path count; the Phantom never."
- Rewrite: "Flyers over the path count, but never the {nightmare:dandelion_seed}."

## 2. Other flagged strings

| Where | Now | Problem | Rewrite |
|---|---|---|---|
| Unfettered tip | "Each Calling hit still comes only as often as its row allows. Bosses still take less." | "less" has no number; other rows say "Bosses take half". | "Each Calling hit still comes only as often as its row allows. Bosses take half." (check) |
| Patient Aim tip | "Works for: Wardens that attack slowly. Safe." | "attack slowly" is the undefined speed word from R3.3 #8; Unfettered now says "attack less than once a second". | "Works for: Wardens that attack less than once a second. Safe." (check the card's own threshold) |
| Deep Frost | "{family:dewdrop} Wardens' hits deal 45% more damage to nightmares with {held}." | Every other hit card now says "direct hits" (T7); "hits" alone is ambiguous. | "{family:dewdrop} Wardens' direct hits deal 45% more damage to nightmares with {held}." (check direct-only) |
| Towering (unchanged, sibling) | "…deal 10% more for each {rank} above II." / tip "… Hits only." | The only hit card left without "damage" and with the old "Hits only."; the R6 sweep missed it. | "…deal 10% more damage per {rank} above II." / "… Direct hits only." |
| Standing Tall | "…per attacking Warden below a {final_form} {touching} them…" | "below a Final Form" means "not yet a Final Form", but can read as a place. | "…per attacking Warden {touching} them that isn't yet a {final_form}, up to +45%." |
| Hairpin Winds vs Spinning Corners | "A {family:whirligig} Warden with 6 or more…" / "{family:whirligig} Wardens {touching} a bend…" | Siblings: one singular, one plural. | "{family:whirligig} Wardens with 6 or more path cells {touching} them attack 30% faster." |
| Shared Caps (calling_paths :102) | "Shared Caps' Warden at each {mushroom} wears a cap: +15% {potency}. Without a damaging status, its direct hits…" | Still reads as a Warden owned by "Shared Caps"; 25 words. | "At each {mushroom}, one Warden wears a cap: +15% {potency}. If its status deals no damage, its direct hits on {spored} nightmares deal 15% more damage instead." (27; check which Warden) |
| Lantern tip (:148) | "First half: of the path it walks (flyers: of their flight). The lantern relights…" | Colon inside a colon, plus parentheses. | "It lights the first half of its walk (for flyers, their flight). It relights to full in every glow and stays all its walk." |
| Lantern Alley (:156) | "…takes a {flare}: 25% of the Firefly's damage per streak glow, up to 150%." | "per streak glow" is a noun stack; 25 words. | "…takes a {flare}: 25% of the Firefly's damage per glow in the streak, up to 150%." (26: cut "A nightmare" to "Nightmares entering…take") |
| Moth to Flame (:187) | "…saves a crit on that nightmare for your top gold-dispel Warden…" | "top gold-dispel Warden" is a 3-noun stack. | "…saves a crit on that nightmare for the Warden with the most gold dispels: +50% after 4 more direct hits." |
| Constellation (:222) | "…a star lights over it: its next 3 hits {jump} in full." | "its" = the nightmare's own hits? (rule 13) | "…a star lights over it: the next 3 hits on it {jump} in full." |
| Constellation tip | "{Jumps} go to the healthiest. Each nightmare once every 4 s; each Warden once a second." | "healthiest" what; semicolon. | "{Jumps} go to the healthiest nightmares. Each nightmare once every 4 s. Each Warden once a second." |
| Coda (:314) | "…each Warden in it has its next hit within 4 s, on any nightmare, repeat at half damage." | "has … repeat" is a hard causative; two commas break it up. | "After a Symphony, each Warden in it repeats its next hit within 4 s at half damage, on any nightmare." |
| River Mouth II (:440) | "…on another family's Warden's first direct hit on each nightmare." | Double possessive; the payoff (bonus) is mid-sentence. | "River Mouth's bonus also works in the last 3 {steps} of each stretch of {water}: on each nightmare's first direct hit from another family." |
| Callings small print (callings.gd :30) | "A crit this Calling saves or forces counts as a crit for nothing else." | "for nothing else" is a backwards negative. | "Crits this Calling saves or forces don't count as crits for other cards." |
| dream_reaction_cards.gd :203 | "Reactions triggered: %d this run (you: %d)" | Reads as "N were triggered" when N is what you need; "you:" is a stub. | "Needs %d Reactions this run (now %d)" |
| Rate limits, 4 forms this round | "Once a second per Warden." (Conductive Soil) · "Each Warden once a second." (Eddy) · "Once a second per nightmare for each Warden." (×3) | Rule 3: subject first. | "Each Warden once a second." / "Each Warden once a second per nightmare." |

## 3. Patterns

- **Limiters only in the tip.** Three stack cards hide "once a second" and "direct hits only" in the tip while the face
  says "each hit". Fix: the limiter goes on the face as its own last sentence (T3); the tip keeps "Works for".
- **Rate-limit wording drifted** (4 forms in 6 cards). Fix: rule 3 forms only.
- **"+cap" and the unit are dropping again** (Grandfather Stump "up to 45%"). Fix: "up to +N%" every time (T2).
- **Missing payload numbers when a card is reworked:** Conductive Soil lost "for half". Fix: every {jump} card names
  its share ("for half" / "in full").
- **Raw tag words where a token exists:** Heavy, Area, sleep, Phantom. Fix: {heavy}, {asleep},
  {nightmare:dandelion_seed}; Area: say "splashes".
- **Family rewrite done well, but the who-phrase now comes in 3 shapes:** "{family:X} Wardens' hits…", "Each hit from
  a {family:X} Warden…", "A {family:X} Warden's hit…". Fix: "{family:X} Wardens' direct hits …" for all cards that
  modify hits (T7 gate form); "Every 3rd direct hit from a {family:X} Warden …" for T4.
- **"stretch of {water}" pushes water rows to 25** (5 rows at exactly 25). Fine now; next edit to any of them has to
  cut a word elsewhere.

## 4. Length stats

- Card faces over 25: **1** (The Tallest Tree 38). Longest 10 faces: Tallest Tree 38, Conductive Soil 24, Struck Twice
  23, Trophies 23, Bearing Down 22, Nowhere to Run 22, Guiding Light 21, Guiding Light II 21, Standing Tall 21, Loose
  Stones 21.
- OLD → NEW, notable: Tallest Tree 33 → 38, Conductive Soil 12 → 24, Eddy 16 → 20, Chain Bloom 12 → 17, Unfettered
  12 → 17, Loose Stones 25 → 21, Resonance 12 → 8; the hit-card "damage" pass adds +1 to each (Bearing Down, Clean
  Strike, Finishing Blow, Nowhere to Run, Open Road, Standing Tall, Trophies, Struck Twice). Tips: Struck Twice
  45 → 40, Gathering Storm 44 → 39, Charged Feathers 8 → 19, Resonance 6 → 23.
- Tips over 40: **0** (Struck Twice, Clump and the Firefly F4 tip are exactly 40). Calling tips that were over 40 (Clump
  49, Lantern Alley 45, Moth to Flame 46, Pyre 44, F4 47, Constellation 47) are all now 36-40.
- Calling rows over 25: 0; at exactly 25: 9.

## 5. Templates (round 4 additions; T1-T8 still hold)

- **T9, the family-stack card:** "{family:X} Wardens' direct hits add N {stack} of {status}. Each Warden once a second
  per nightmare." (Charged Feathers, Pollen Beaks, Resonance once fixed.)
- **T4 models now:** Needle Point "Every 3rd hit from a {family:nestling} Warden ignores the {dread_shell}." (add
  "direct").
- **T1 models now:** Spinning Corners "{family:whirligig} Wardens {touching} a bend in the path attack 35% faster.";
  Hairpin Winds.
- **T7 models now:** Open Road, Finishing Blow, Trophies (all "N% more damage", tip "Direct hits only.").
- **Upgrade (II) pair:** Guiding Light / Guiding Light II differ only in "1 cell" / "2 cells". Good.

## 6. What already works

- R6 is done on 8 of 9 hit cards: "N% more damage" and one tip wording, "Direct hits only." (Towering is the one left).
- The Phantom/flyer, {toll}-as-verb, "a {water}", "set off", "a pack" and "bonus hits / slow Wardens" fixes all landed.
  Last Bell, Halfway Bell and Steady Beat now read cleanly.
- The family-token rewrite makes the who-phrase short and findable: Carried on the Wind went from 12 to 11 words, with
  the family name first.
- Every Calling tip that was over 40 words is back under the cap.
- Deep Frost dropped the {frozen} redefinition: the effect and number now sit in the first 8 words.
