# Wording Council round 2 (2026-10-23): Scan Reader (mid-fight, on a phone)

Scope: only text that is new or changed since round 1 (`corpus_resources.txt`, `corpus_ui_diff.txt`). I judged it
against the round 1 phrasing rules (wording_council_review.md section 5) and my round 1 templates (scan_reader.md
section 3). Counting rule: a `{token}`, nested ones included, counts as one word, and so does `%d`. Every rewrite keeps
the card's numbers and tokens. "(check)" means the owner should confirm the mechanic first.

## Headline

1. **The ten new hit cards use six different sentence shapes,** so they don't compare side by side. Seven open on
   "direct hits", but the gate (rank, form or none) sits in four different places. Bearing Down's subject is "Each
   attack", Trophies puts "direct hits" at word 15, and Measured Blow opens with its rank gate. Towering (changed,
   14 words) already has the right shape: **"[Gate] Wardens' direct hits deal N% more [when], up to +cap."** All ten
   rewrites below use it (T7, section 3).
2. **Caps lost their plus sign.** The new cards say "up to 10% / 40% / 45% / 40%". Every older scaling card says
   "up to +30%" (Fruiting, High Tide, Sodden, Hot on Their Heels). Without the "+", "up to 40%" can read as the total
   rather than the bonus.
3. **"Direct hit" is a new term with no glossary entry,** and each of these cards also repeats it in its tip ("Hits
   only."). Now there are three phrasings: "Hits only.", "Hits only: never statuses or {reaction} damage.", and the
   older "Hits only, not status damage.". Fix: add a "Direct hit" glossary entry and drop "Hits only" from these tips.
4. **Two new cards are over 25 words:** Trophies (26) and The Tallest Tree (26). The Tallest Tree's tip (44) and its
   button (5 words) are also over the limits.
5. **Round 1 short forms were not applied to the Root Wardens' changed text.** Deeproot, Earthbind, Rootling,
   Snugroot, Tangleroot, Long Way Home and Rootcurl got "It damages every nightmare in range." (T8), but they still
   say "gains 1 {held} and can't move for X" and "the nightmare furthest along the path". Rule 11 calls for "1 {held}
   for X" and "the leader".
6. **The UI rewrites are mostly easier to scan** (19 of 24 judged easier). There are two regressions. The clump text
   lost its trigger ("Stepping on"). The Soak chip says "water hits", but {water} is now also the Puddles token, so
   "water" has two meanings.

**Flagged: 38 strings** (10 in the top 10, 28 in the table).

---

## Word counts: the 11 new cards

| Card | Words now | Number first appears at word | Over 25? | Rewrite words |
|---|---|---|---|---|
| Bearing Down | 21 | 11 | | 21 |
| Clean Strike | 21 | 4 | | 17 |
| Finishing Blow | 20 | 11 | | 16 |
| Measured Blow | 21 | 14 | | 21 (with "Not bosses.") |
| Nowhere to Run | 23 | 9 | | 21 |
| Open Road | 16 | 4 | | 15 |
| Run Through | 20 | 13 ("half" at 20) | | 18 |
| Standing Tall | 22 | 9 | | 20 |
| The Tallest Tree | **26** | 11 ("a fifth") | **yes** | 22 |
| Trophies | **26** | 5 (10 blows), 12 (4%) | **yes** | 22 |
| Undiluted | 19 | — (the effect is "double", word 18) | | 11 (check) |

Tips: The Tallest Tree **44** (over 40; rewrite 38). Undiluted 22, Bearing Down 18, Finishing Blow 15, Trophies 15,
Measured Blow 13, Nowhere to Run 12, Run Through 21, Standing Tall 11, Clean Strike 14, Open Road 9.
Button: "Make it the Tallest Tree" **5** (over 4).

---

## 1. Top 10

| # | Where | Now | Problem | Rewrite |
|---|---|---|---|---|
| 1 | **Trophies** `trophies.tres` (26) | "A Warden that lands 10 killing blows in one {drift} deals 4% more with its direct hits for the rest of the run, up to 40%." | Over 25. "Killing blows" is a third name for dispel. "With its direct hits" pushes the payoff to the middle. The cap has no "+". The face doesn't say it can happen only once per drift (that is in the tip). | "Each {drift} a Warden {dispels} 10 nightmares, its direct hits deal 4% more for the rest of the run, up to +40%." (22) The tip can then drop "Once a {drift}." |
| 2 | **The Tallest Tree** `the_tallest_tree.tres` (26) | "Choose one Warden. Every other Warden's direct hits also store a fifth of their damage in it, and its direct hits add the store on top." | Over 25. "A fifth" is hard to spot as a number. "Add the store on top" sounds like the whole store goes into one hit, but the tip caps it at 6 hits per attack. | "Choose one Warden. Every other Warden's direct hits store 20% of their damage in it. Its own direct hits spend the store." (22) |
| 3 | **The Tallest Tree** tip (44) | "Choose it on its panel: any time first, then only at a {rest} (moving it empties the store). One attack adds at most 6 times its own hit, never more than a {dispel} needs; the store holds 40 of its hits. Sold: choose again." | Over 40. "Any time first" makes you read it twice. A parenthesis, a semicolon, and the store limit comes after the spend limit. | "Choose it on its panel, first any time, then only at a {rest}. Moving it empties the store. Holds up to 40 of its hits; each attack spends at most 6, never past a {dispel}. Sold: choose again." (38) |
| 4 | **Bearing Down** (21) | "Each attack in a row on the same nightmare deals 4% more, up to 10% for each {rank} the Warden holds." | The subject is "attack", not a Warden, so it breaks the hit-card shape. You only learn who qualifies (single-target Wardens) from the tip. "Up to 10% for each {rank} the Warden holds" puts two numbers together and has to be read twice. | "Single-target Wardens' direct hits deal 4% more for each hit in a row on one nightmare, up to +10% per {rank}." (21) |
| 5 | **Measured Blow** (21) | "From {rank} III, a Warden's first direct hit on each nightmare also deals 1% of its maximum health for each {rank}." | The gate comes first, so the number is at word 14. "Its maximum health" breaks rule 13 (Warden or nightmare?). "Not bosses" is a hard exception but is only in the tip. | "{rank} III+ Wardens' first direct hit on each nightmare also deals 1% of the nightmare's maximum health per {rank}. Not bosses." (21) Tip: "At most 10% of a nightmare's health from this card, all Wardens together." (check: total, not per Warden) |
| 6 | **Finishing Blow** (20) + tip | "Direct hits from Wardens at {rank} II or higher deal 40% more to nightmares below a third of their health." Tip: "… Best on the Wardens near the Heartwood." | The gate splits subject and verb, so the number is at word 11. The tip's last sentence is strategy advice, which breaks the owner's no-hand-holding rule. | "{rank} II+ Wardens' direct hits deal 40% more to nightmares below a third of their health." (16) Tip: drop "Best on …". |
| 7 | **Undiluted** (19) + tip | "No {reaction} ever goes off. Each status's own effect grows instead: {spored} ticks and {static} bolts deal double damage." Tip: "… Lightning Rod stays quiet; a {static} bolt still fires." | "Goes off" breaks rule 10. "Each status's own effect grows" promises every status, but only two are listed (check: do {damp}, {drowsy} and {marked} change?). The tip has a raw "Lightning Rod", "stays quiet" and "pay off". | If only those two change: "{reactions} never trigger. {spored} ticks and {static} bolts deal double damage." (11) Tip: "While you hold it, cards that work only through {reactions} aren't offered. {named_combo:lightning_rod} never triggers; {static} bolts still strike." |
| 8 | **Clean Strike** (21) + tip | "Direct hits deal 25% more to nightmares carrying no other family's status, or 50% more from a {final_form} or {ascended} form." Tip: "Your own family's statuses don't count …" | "Other" than what? The tip's "your own family" sounds like the player, but the player owns several families. The second number is hidden behind "or". | "Direct hits deal 25% more to nightmares with no status from another family. {final_form} and {ascended} Wardens: 50%." (17) Tip: "The hitting Warden's own family's statuses don't count, …" (check) |
| 9 | **Nowhere to Run** (23) | "A {branch} or {final_form} Warden's direct hits deal 5% more for each second the nightmare has been in its range, up to 40%." | The cap has no "+". It leaves out {ascended}, which the code comment includes and the other form-gated cards list (check). "A … or … Warden's" is singular, but the cards with no gate say "Direct hits". | "{branch}, {final_form} and {ascended} Wardens' direct hits deal 5% more per second the nightmare has been in range, up to +40%." (21) |
| 10 | **Root Wardens' changed descriptions**: Deeproot, Earthbind, Rootling, Snugroot, Tangleroot, Long Way Home, Rootcurl | e.g. Tangleroot "… Every {f} the nightmare furthest along the path gains 1 {held} and can't move for {f}." | Rule 11's short forms were missing from the T8 edit. Each loses 4–9 words to "the nightmare furthest along the path" and "and can't move for". | Rootling "Every 4th hit gives the leader 1 {held} for {f:pulse_hold_time}." · Tangleroot "Every {f} the leader gains 1 {held} for {f}." · Snugroot "Every {f} up to {f} leaders gain 1 {held} for {f}." · Rootcurl "Every {f} it pulls the leader back {f} cell." · Long Way Home "Every {f} it drags the leader back {f} cells (bosses 1). Once per nightmare." · Deeproot "Each nightmare within {f} cells of the Heartwood gains 1 {held} for {f}, once." · Earthbind "… drags up to {f} flyers down to the path, each with 1 {held} for {f}." (Each one keeps "It damages every nightmare in range." first.) |

---

## 2. Every other flagged string

Each row marks the rewrite **easier** or **harder** than the "-" line, or **n/a** where the text is a new .tres.

| Where | Now | Problem | Rewrite |
|---|---|---|---|
| Open Road (16) | "… nightmares walking a straight of 4 or more path cells." | "A straight" is used as a noun with no glossary entry ("bend" has one). | "Direct hits deal 25% more to nightmares on a straight stretch of 4+ path cells." (15) |
| Run Through (20) | "… direct hit carries on to the next 2 nightmares behind its target, each taking half." | "Half" is the last word; "carries on" is a phrasal verb. | "{final_form} and {ascended} Wardens' direct hits also hit the next 2 nightmares behind the target for half damage." (18) |
| Standing Tall (22) | "A {final_form} or {ascended} Warden's direct hits deal 15% more for each attacking base or {branch} Warden {touching} it, up to 45%." | Cap has no "+". Singular form, unlike its siblings. | "{final_form} and {ascended} Wardens' direct hits deal 15% more per attacking base or {branch} Warden {touching} them, up to +45%." (20) |
| Hit-card tips (7 of 10) | "Hits only." / "Hits only: never statuses or {reaction} damage." | The face already says "direct hits", and there are three phrasings. | Add a glossary entry, "Direct hit: a Warden's own attack landing; not statuses, ticks, clouds, bolts, {jumps} or {reactions}.", and drop "Hits only" from these tips. |
| Bearing Down tip | "Wardens that aim at one nightmare; not area attacks or beams. A new target starts again. Hits only." | Opens with a fragment and a semicolon. | Once the face says "Single-target": "Not area attacks or beams. A new target starts the count again." |
| Trophies tip | "{deeply_blighted} nightmares and bosses count 5. Once a {drift}. Kept when it grows, lost if sold. Hits only." | "Once a {drift}" belongs on the face (see the rewrite). | "{deeply_blighted} nightmares and bosses count 5. Kept when it grows, lost if sold." |
| `warden_panel.gd` button (5) | "Make it the Tallest Tree" | Over 4 words. | "Make Tallest Tree" (3). The tooltip stays. |
| `warden_panel.gd` line | "Reactions: set off %d · fed %d" | "Set off" breaks rule 10, and "fed" is jargon. | "Reactions: triggered %d · fed %d", with a tooltip for "fed" (check). |
| Thunderclap `thunderclap.tres` (33) | "A Thunderclap hits it hard and arcs … Needs … ×12 damage, ×6 per arc, and each arc adds 1 {static}." | The numbers still come after the recipe (round 1, 2d), and "×12" has no base (rule 5). Changed (T9) but not reordered. | "Hits it for ×12 the triggering Warden's damage and arcs to nightmares with {damp} in range for ×6 each, adding 1 {static}. / Needs {stacks:need_damp} {damp} + {stacks:clap_static} {static} ({stacks:bossclap_static} on bosses)." (check the base) |
| Lightning Rod (25) | "… strike it instead, for ×2 damage." | Rule 5: use "double" for a true ×2. | "… strike it instead, for double damage." |
| Thorncoil Warden | "… and thorns bite nightmares with {held}: while one with {held} is in its range, it takes thorn damage each second." | Says the same thing twice, and the "it" is unclear. | "It damages every nightmare in range. Each nightmare with {held} in its range also takes thorn damage once a second." |
| dream_thorncoil | "[P]: thorns for nightmares with {held}: each second, every nightmare with {held} in its range takes thorn damage." | Second colon (breaks T5). | "[P]: each nightmare with {held} in its range takes thorn damage once a second." |
| Mossback, Boulderback (Warden + card), Exposed Blow (`codex_data.gd:168`) | "with full {marked}" | "Full" is raw text where the {full} token exists (Dreamcatcher and Pinned use the token). The T5 fix is only half done. | "with {full} {marked}" |
| Boulderback Warden (≈30) | "A crushing hit that splashes three quarters of its damage around; double damage on …, and it always crits on those with {drowsy}." | A semicolon joins three effects. | "A crushing hit; 75% splashes around it. Double damage on nightmares with {full} {marked}; always crits on {drowsy}." (or keep the field token for the share) |
| The Great Bell Warden | "… every nightmare falls {asleep}, and every nightmare with {f}+ … is struck by its bolt for half damage." | "Every nightmare" twice, and a passive verb. | "Every 8 s it peals across a huge range: all nightmares fall {asleep}; those with {f} or more {static} take its bolt at half damage." |
| Grandmother Oak | "Wardens within her range (3 cells) deal …" | Parenthesis. | "Wardens within 3 cells deal {pct} more damage and attack {pct} faster. After every {drift}: {dew:{f}}." |
| Heartwood Sapling (44) | "… 1 {dreamlight} every 10 drifts. … from rank III, Dreamlight every 8 drifts …" | Numbers fixed (T2), but round 1's #8 rewrite wasn't applied: raw "drifts", "rank" and "Dreamlight" sit next to their tokens. | "2×2, rooted for good. / After every {drift}: {dew:{f:dew_per_drift}}, +{dew:{f:dew_per_rank}} per Nurture {rank}. / 1 {dreamlight} every 10 {drifts}, every 8 from {rank} III. / Each {leaf} lost: yield −5% until the next {rest}." (≈33) |
| Soaked Rot (`damp_rot.tres`) | "On nightmares with {damp}, {spored} ticks and {reaction} damage that uses {spored} are 50% higher." | Condition first, and "are higher" instead of "deal more" (rule 1). | "{spored} ticks, and {reactions} that use {spored}, deal 50% more damage to nightmares with {damp}." |
| Settling Spores, Spore Huddle | "after a Sporeling hits", "each other Sporeling" | Raw family name; ruling 5 / R6 says use the {family:} token. | "after a {family:sporeling} Warden hits", "each other {family:sporeling} Warden" |
| Sparks Fly, Refrain | "… within 2 s …" in mid-sentence | Round 1 window-first shape (T3) still not applied. These files changed, so I'm noting it again in one line. | Round 1, 2b rewrites. |
| `calling_paths.gd:39` clump | **harder**: "A clump gives a {dose} for each {mushroom} in it." | The trigger ("Stepping on") is gone, so the reader can't tell when a dose happens. | "A nightmare stepping on a clump gets a {dose} per {mushroom} in it." (check) |
| `dream_keywords.gd:56` Soak chip | **easier but ambiguous**: "{damp}: water hits deal 20% more damage to the nightmare." | "Water" is now also the Puddles {water} path. | "{damp}: {family:dewdrop} hits deal 20% more damage to it." (check that "water hits" = Dewdrop family) |
| `calling_paths.gd:174` | **easier**: "When a Warden {touching} {water} hits a nightmare with {damp} there, nightmares within 2 {steps} of it in that {water} get {damp} too." | "Of it" could mean the Warden or the nightmare (rule 13). | "… within 2 {steps} of that nightmare, in the same {water}, get {damp} too." |
| `callings.gd` / `calling_paths.gd` "Dewdrops", "Fireflies" | **easier** than "{warden:dewdrop}s" / "Firefly Warden" (shorter, and the DETAILS line now defines them) | Ruling 5 asks for the {family:} token, which is one word on screen and tappable. | "{family:dewdrop}s" / "{family:firefly_jar}s", if the token can be plural (check); otherwise keep, since the DETAILS definitions cover it. |
| `icon_info.gd:20` Drowsy tooltip | **easier** (the name) | "… set off {reactions}" (rule 10) | "… and trigger {reactions}." |
| `lesson_card.gd:222` Poison | **easier and correct** | "it can set off {reactions}" (rule 10) | "it can trigger {reactions}." |
| `lesson_card.gd:216` STACK_TEXT (45) | **easier and correct** | The last sentence repeats "enough stacks". | "… When two statuses on one nightmare each reach enough stacks (blue corner brackets round the icon), they trigger a {reaction}." (≈37) |
| `codex_data.gd:279` Night Chimes | **easier** (12) | "set off {static}" (rule 10) | "… threads trigger {static} bolts at 12 stacks." |
| `codex_data.gd:90` Arc | **easier** (the field token) | "catches Phantoms gliding through": "Phantoms" is on the words-to-avoid list. | "… and catches flyers crossing it." |
| `family_pick_screen.gd` deepen | n/a (new): title "One of yours could have grown another way." / "Choose a family to deepen" | The flavour title hides what the screen is for, and "deepen" is jargon on first sight. | Keep the flavour, and make the subtitle the instruction: "Choose a family: one of its branches opens" (check what deepen gives). |

---

## 3. Patterns and rules

- **T7, the hit-card template (new; add it to the round 1 templates):** "[Gate] Wardens' direct hits deal N% more
  [condition], up to +cap." The gate is either nothing ("Direct hits deal …"), a rank ("{rank} II+ Wardens'") or a
  form ("{final_form} and {ascended} Wardens'"). Use plural "Wardens'", "per" and "+cap". Towering is the model. Put
  bosses and other hard exceptions on the face ("Not bosses."), not only in the tip.
- **Caps always carry "+":** "up to +40%". New text has dropped it on four cards.
- **One name for the kill:** {dispel}, never "killing blow" (Trophies). Hard-Won Rings uses a raw "dispels"; the
  token works there too.
- **Number words:** use "half" and "double" only for true ×0.5 and ×2 (rule 5). For other fractions ("a fifth", "a
  third") prefer digits on new cards, because digits are what the eye looks for.
- **Rule 10 is still leaking in changed lines:** "set off" appears in 5 of the changed UI strings, and "goes off" on
  Undiluted.
- **Rule 11 short forms didn't travel with the T8 edit:** when a Root Warden line is touched, apply "the leader" and
  "1 {held} for X" in the same pass.
- **Tokens over raw words:** "full", "Lightning Rod", "Sporeling", "Phantoms", "drifts" and "rank" all appear as raw
  text in changed lines, next to tokens that exist for them.

## 4. What already works

- **Towering** is the best new hit-shaped card: 14 words, number at word 8, and a tip that shows the arithmetic
  ("Rank V: +30%; rank VII: +50%").
- **Clean Strike, Open Road** put the number at word 4, and **Finishing Blow** is close.
- **Most UI rewrites read better:**
  - The Codex family-pick line now leads with the numbers ("After drifts 1, 10, 35 and 60").
  - The labels are shorter: Reroll, Banish, Drowsy, "cells".
  - "Doesn't add {held}" is clearer than "Never {held}".
  - "That Dewdrop's next hit" fixes an unclear referent.
- **Bellflower** uses "every 2nd pulse" (rule 4).
- **Captions now match their cards:** Briar Crown 60%, Crossroads +100%.
- **The waystone panel line** "Old Waystone: +1 Dew per dispel" is a model for short lines.
