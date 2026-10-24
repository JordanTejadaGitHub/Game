# Scan Reader, round 3 (2026-10-24)

Seat: mid-fight, on a phone. Is the effect in the first words? Does the condition read naturally? Is it too long? Can I
find the numbers? Inputs: corpus_resources.txt, corpus_ui_diff.txt ("+" lines judged against their "-" lines) and
calling_rows_now.txt (84 live rows; stage 3 = Finale). Rules: wording_council_review.md section 5, rules 1-17, templates
T1-T7. Word counts treat a token as one word.

## Length stats

| Measure | Result |
|---|---|
| Calling evolution texts (84 live) | **0 over 30**. 1 over 25 (Lantern Alley 26). 11 at exactly 25 (Windblown, Pile-On, Feeding Ground, Host Trees, Moth to Flame, Show the Way, Sightline, Constellation, Last Bell, Curfew, Halfway Bell). Average 21.5. A big gain over round 2c. |
| Evolution tips over 40 | **6**: Clump 49, Borrowed Light 47, Constellation 47, Moth to Flame 46, Lantern Alley 45, Pyre 44. Lantern Parade is at exactly 40. Next longest: Sprout Beds 35, Bonfire 35. |
| "Slower Wardens deal less." | Ends 18 live tips. That is 18 × 4 words of repeated filler (see Patterns). |
| Dream card tips over 40 | 2: Struck Twice 45, Gathering Storm 44. Heavy Going 36, Sunlit Rest 31. |
| Grove nodes over 25 | **12 of 27**: the 8 Ascensions (43-57: Dewdrop 57, Pebbling 53, Bellflower 52, Whirligig 51, Acorn / Rootling / Sporeling 49, Firefly 44, Nestling 43), the 3 Memory Wardens (42-43) and Samara (27). Wider Roots, Nestling and Rootling branches sit at exactly 25. |
| Crowned Reactions over 25 | 9 of 10 (no change from the gap round). Wide Awake is 25. Still Pool and Tempest are 44, Avalanche 41. |
| Buttons over 4 words | 0 fixed strings. **1 built at runtime**: `warden_panel.gd:368` "Grow into %s" with the raw `display_name` gives "Grow into The Great Bell" (5 words, capital "The" mid-button). "Grow into The Whirlwind" is 4 words but has the same capital. The boss button "Hunt %s" goes through `the_name()`, so its longest is "Hunt the Mourning Mother" (4). |
| Ascension nodes effect-first? | **Partly.** The route now sits last as a fixed line, and the glued "s" is gone (G1 done there). But every Ascension still opens with a 9-10 word name clause ("Unlocks {warden:X}, the strongest form of the {family:X} {family}."), so the effect starts at about word 11. "Unlock" also means two things in one node (the node unlocks it; in a run you "unlock it for 3 {dreamlight}"). See #10. |

## 1. Top 10 problems

**1. Lantern Alley (`lf_lantern_alley`): the text is garbled.**
Now: "A glow entered within 4 {steps} of the last {flares} the nightmare: 25% of its Firefly's damage for each glow in the streak, up to 150%."
Problem: "of the last {flares}" reads as a noun phrase ("the last flares"). The verb is only found on a second read, and
"its Firefly" has no clear owner. It is also the only live text over 25 words.
Rewrite: "Each glow a nightmare enters within 4 {steps} of its last one {flares} it: 25% of that Firefly's damage per glow in the streak, up to 150%." (25)

**2. Toadstool Throne (`sp_throne`): the age goes to the wrong noun.**
Now: "A Warden at a clump planted 10+ {drifts} ago makes it a throne: its last {mushroom} is never eaten, so its {free_hits} go on."
Problem: "a clump planted 10+ drifts ago" says the clump is old. The tip ("your oldest Warden's", "Growing it keeps its age")
shows the Warden is what counts. There are also three "it/its" in one sentence.
Rewrite: "A Warden planted 10+ {drifts} ago makes its clump a throne: the throne's last {mushroom} is never eaten, so its {free_hits} go on." (23)

**3. Host Trees (`sp_host_trees`): a garden-path sentence.**
Now: "At each {mushroom}, the Warden Shared Caps picks wears a cap: +15% {potency}, or, if its status deals no damage, +15% damage on {spored} nightmares."
Problem: "the Warden Shared Caps picks wears" reads as a Warden named "Shared Caps", and the main verb shows up late. The
second payoff "+15% damage on" has no subject (rule 1).
Rewrite: "At each {mushroom}, Shared Caps' Warden wears a cap: +15% {potency}. If its status deals no damage, it deals 15% more damage to {spored} nightmares instead." (25; "its hits" if only direct hits count, check)

**4. Moth to Flame (`lf_moth_to_flame`): the payoff lost its condition (worse than the "-" line).**
Now: "…saves a crit for the Warden with most gold dispels this block: +50% once 4 other hits land." The tip is 46 words.
Problem: "+50% once 4 other hits land" no longer says where the hits land (the old line said "on that nightmare") or that
they must be direct. "most gold dispels" also needs "the".
Rewrite: "A Firefly's direct hit on gold path saves a crit on that nightmare for your Warden with the most gold dispels this block. It deals 50% more after 4 other direct hits on it." (32: over 30, but the condition is back; check "direct")
Tip (31): "Gold dispels: nightmares dispelled on gold path. Until someone has one this block, last block's holder keeps it. Ties: the higher form. Bonfire's crit still works. Area attacks count once. Sprouts and walls don't count."
(This drops "Other cards don't count it as a crit." Move that line to the Calling's DETAILS once, see Patterns.)

**5. Short relative clauses made three Firefly rows worse than their "-" lines.**
- Constellation now: "A star lights over a nightmare 3 different Wardens hit on pale path within 2 s: …". Old: "When 3 different Wardens hit one nightmare on pale path within 2 s, a star lights over it: …". **Keep the old shape** (T3, rule 12 allows a "When" trigger to go first): "When 3 different Wardens hit a nightmare on pale path within 2 s, a star lights over it: its next 3 hits {jump} in full."
- Show the Way: "in full when it came from a Warden Lantern Wake lit" → "in full from a Warden lit by Lantern Wake."
- Full Glow: "hit directly by a Warden Lantern Wake lit" → "A nightmare hit directly by a Warden lit by Lantern Wake stays {lit} for 3 s wherever it walks."

**6. Pyre and Banked Fire (`lf_pyre`, `lf_banked_fire`): "on gold path crits" stumbles.**
Now: "There, every 2nd direct hit from a Warden with 50 dispels on gold path crits."
Problem: "on gold path crits" reads as a noun phrase, and the threshold sits in the middle of the sentence. "Gold dispels" is
already defined in Moth to Flame's tip, so use it here.
Rewrite Pyre: "Path inside 3+ Fireflies' glows burns white. There, a Warden with 50+ gold dispels crits on every 2nd direct hit." ("50+" if 50 is a minimum, check)
Banked Fire: "Pyre works on gold path too: there, a Warden with 50+ gold dispels crits on every 3rd direct hit."

**7. The Heartwood's Crown (`meta/grove/heartwoods_crown.tres`): the node still says "every other".**
Now: "Grows when every other {node} is at its top level. Adds a sixth {perk} slot: carry 6 {perks} into a run."
Problem: the Grove chip was fixed ("All other nodes at their top level"), but the node text still says "every other",
which rule 4 bans because it reads as "every 2nd". It also puts the condition first (rule 12).
Rewrite: "Adds a sixth {perk} slot: carry 6 {perks} into a run. Grows once all other {nodes} are at their top level."

**8. Six evolution tips are over 40 words.**
Clump (49), Borrowed Light (47), Constellation (47), Moth to Flame (46, rewrite in #4), Lantern Alley (45), Pyre (44).
Each one stacks 6-9 short rulings. Fix it the same way in all six: drop "Slower Wardens deal less" (the {free_hit} /
Calling hit glossary already says it), and move "Other cards don't count it as a crit" to DETAILS.
- Clump (32): "At most 3 attacking Wardens {touching} it, the strongest first, each once a second. Each step eats 1 {mushroom}. New {mushrooms} join a clump within 3 {steps}. Bosses take half. Damage only: no status. The {dose} still lands."
- Borrowed Light (38): "Until you pick a second family, Firefly hits count too. Not Sprouts or walls. Each Warden once a second. A {jump} deals at most 3 s of the lighting Firefly's damage. Bosses take half. Never the same nightmare as another card's {jump}."
- Constellation (31): "Not Sprouts or walls. On pale path, {jumps} go to the healthiest. Each nightmare once every 4 s; each Warden once a second. The 3 s cap still applies. Bosses take half."
- Lantern Alley (34): "A streak: glows at most 4 {steps} apart. Its 2nd glow is 50%. Each glow joins one streak per nightmare. Each Firefly once a second. Bosses take half. Damage only: no status."
- Pyre (33): "Gold dispels count while the Warden stands (white path is gold too); growing keeps them, selling loses them. Bosses: every 3rd hit. A saved crit is used first, with its bonus. Not Sprouts or walls."

**9. Dream tips still give advice ("Works for: … Safe.", "A bet: pays when…").**
Gathering Storm, Heavy Going, On the Beat and Struck Twice. This is the owner's no-hand-holding rule, and it is also why
Gathering Storm (44) and Struck Twice (45) are over 40. ("Pays" is also on the words-to-avoid list.)
Rewrites, rules kept:
- Gathering Storm: "Resets after 2 s without a {jump}. Any card or Warden's {jump} counts, except a Calling evolution's. Bosses take half of each {jump}." (21)
- Struck Twice: "Any card or Warden's {jump} counts, except a Calling evolution's. Direct hits only. One waiting hit per nightmare; it fades after 2 s. Multiplies with your other Dream damage." (27)
- Heavy Going: "Any slow counts except {drowsy}'s and the Calling's own. {held} and {asleep} nightmares stand still, so they don't count. Direct hits only." (21; "A slowed nightmare drips while it counts" is flavour, so cut it or check what it shows)
- On the Beat: "Damage only: no status, and it triggers no other card or bell. Other {family:bellflower} Wardens join too." (17)
(Check whether the owner kept a "Works for" rating line on purpose. If not, all four lose it.)

**10. The Ascension nodes are 43-57 words and still open with the name clause.**
Now (Dewdrop, 57): "Unlocks {warden:tidecaller}, the strongest form of the {family:dewdrop} {family}. Every 6 s a wave gives … In a run: from {drift} 51, unlock it for 3 {dreamlight}, then grow a {final_form} into it for 600 {dew}."
Problem: the effect starts at word 11, and "unlock" means two different things. The route is now a fixed last line, which is good.
Template (same words, effect first, one meaning of unlock):
"{warden:tidecaller}: every 6 s a wave gives everything in range {damp} and drags it back 1 cell along the path; at 8 {damp} it is {frozen} for 1 s. The strongest {family:dewdrop} form. In a run, from {drift} 51: 3 {dreamlight} to wake it, then 600 {dew} to grow a {final_form} into it."
A better fix: show the name and "Strongest {family:dewdrop} form" as a header row, and the route as a footer chip, so the
body is only the effect (11-30 words). The verb "wake" is only a suggestion. Use whatever the Remember screen's button says.

## 2. Every other flagged string

| Where | Now | Problem | Rewrite |
|---|---|---|---|
| Early Lamps tip | "It relights to full in every glow. Halfway along the path it walks; flyers, their flight. The lantern stays all its walk." | The middle sentence is a fragment, and it is the definition of "first half". | "First half: of the path it walks (flyers: of their flight). The lantern relights to full in every glow and stays all its walk." |
| Deathcap (`sp_deathcap_field`) | "The first 3 {mushrooms} each nightmare steps on burst: each deals 2 s worth…" | "steps on burst" is a garden path. | "Each nightmare's first 3 {mushrooms} burst under it: each deals 2 s of its {spored} damage at once." |
| Heavy Air | "…A {mushroom} doses each nightmare once." Tip: "A {mushroom} it leaves plants no new one." | "doses" is the noun token used as a verb. "it leaves" could mean leaves behind or leaves standing. | "…Each {mushroom} gives each nightmare 1 {dose} at most." Tip: "A {mushroom} left standing this way plants no new one." |
| Pile-On | "Within 2 {steps} of a clump, each direct hit by a {rank} III+ Warden there calls a {free_hit} from each other {rank} III+ Warden there." | "there" twice, with two different places. | "When a {rank} III+ Warden at a clump lands a direct hit within 2 {steps} of it, each other {rank} III+ Warden at that clump gives a {free_hit}." (check: who receives it) |
| Shared Caps tip | "Sprouts count as another family's Warden; for a Sprout, the {spored} the {dose} just put on." | The second half needs two reads. | "Sprouts count: for a Sprout, the 2 {stacks} go on the {spored} the {dose} just gave." |
| Steady Beat | "…since its last {toll} {tolls} every 3rd {ring}…" | Two tokens side by side ("Toll Tolls"). | "While only one bell has rung a nightmare since its last {toll}, it {tolls} every 3rd {ring} in full, not every 4th at half." |
| Ensemble | "their repeats repeat once more 1 s later" | "repeats repeat" stumbles. | "…their repeats land once more 1 s later, at half damage." |
| Deep Tone tip | "{Rings} on one nightmare closer than half a second still count as one." | Worse than the "-" line. "still" reads like a new limit again (round 2b #6), and "doubled or not" is gone. | Keep the 2b line: "Two {rings} on one nightmare within half a second count as one {ring}, doubled or not." |
| Accompaniment | "At its {toll}, the joined Warden that rang last…" | "its" could be the bell or the nightmare. | "At a nightmare's {toll}, the joined Warden that rang it last repeats its hit at half damage." |
| Counterpoint | "Each kind of joined Warden…" / "One note per kind of Warden." | "Kind" is never defined (form? line? family?). | Say the unit once: "Each joined Warden form that rings…" (check which one) |
| Curfew | "the bell keeps its count: the next nightmare it hits takes a second {toll}" | "its count" (which count?) and "a second {toll}" (2nd one, or another at half?). | "…the bell keeps that nightmare's {rings}: the next nightmare it hits takes a Last Bell {toll} with them, at half damage." (check) |
| Last Bell | "Nightmares remember their {rings}. Your last bell … {tolls} each once…" | A 4-word set-up comes before the effect, and "each" needs a re-read. | "Your last bell before the Heartwood {tolls} each nightmare once: its own damage, +7% per {ring} the nightmare took on the way, up to +210%." |
| Carried Lights | "Strung Lights gives 8% for each glow, up to +40%…" | No unit (rule 1). | "…Strung Lights gives 8% more damage per glow, up to +40%, inside glows and out." |
| Fathoms | "deals 10% more damage for each second (bosses 20%) a nightmare has waded" | The boss number is cut off from its number (rule 9). | "The pond's Warden deals 10% more damage (bosses 20%) per second a nightmare has waded the pond, up to +50%." |
| Delta | "each first direct hit on a nightmare from another family's Warden gets…" | "each first" is awkward, and the condition comes first. | "Each other-family Warden's first direct hit on a nightmare within 6 {steps} of leaving {water} gets River Mouth's bonus." |
| Rapids | "another family's first direct hit on each nightmare there gets it" | A family doesn't hit; a Warden does. "gets it" sits at the end. | "River Mouth's bonus also works in a {water}'s last 3 {steps}, on each other-family Warden's first direct hit there." |
| Black Pond | "spill onto up to 4 others for 25% of the hit" | "others" has no noun after it. | "…spill 25% of the hit onto up to 4 other nightmares there." |
| Floodgate | "the water surges" | A raw "water" in a row that also uses {water}. | "…the {water} surges: …" |
| Halfway Bell | "…at half Last Bell's bonus; the nightmare keeps its {rings} for the last bell." | A semicolon. Acceptable, but split it. | "…at half Last Bell's bonus. Its {rings} still count for the last bell." |
| Clean Strike | "Direct hits deal 25% more to nightmares…" Tip: "…Hits only." | No "damage" (rules 1 / 15). "Hits only" just repeats the text. | "Direct hits deal 25% more damage to nightmares…" Tip: cut "Hits only." |
| Heavy Going | "deal 25% more to nightmares walking slowed" | No "damage". | "…deal 25% more damage to slowed nightmares." |
| Struck Twice tip | "Hits only, not {jumps} or bolts." | Rule 14 form. | "Direct hits only." |
| Unfettered (new) | "Bonus hits from your Calling deal full damage, even from slow Wardens." Tip: "Still once per its own clock. Bosses still take their share." | "Bonus hits" is a third name for the glossary's "Calling hit". "its own clock" and "their share" are vague. | "Calling hits deal the Warden's full damage, even from slow Wardens." Tip: "Each keeps its own once-a-second limit. Bosses still take half." (check: the clocks differ per row) |
| Venom (Grove) | "…{card:venom_bloom}: Wardens have 40% more Potency: status and {reaction} damage +40%. Its cost: …" | Two colons. A raw "Potency" where a token exists. The number appears twice. | "Adds the {dream} card {card:venom_bloom}: Wardens get +40% {potency} (status and {reaction} damage), but their direct hits deal 40% less damage." |
| Wider Roots (Grove) | "The cost: calling back one of its {branches} costs 4 {dreamlight} instead of 3." | "cost … costs". | "…instead of 2. Calling back one of them then costs 4 {dreamlight}, not 3." |
| Memory Wardens (3 nodes, 42-43) | "…Grows the first time you dispel the Mire Hag. After that, it can be offered as a reward when you dispel that boss." | Effect-first now (good). The 20-word route could be one line. | "Grows when you first dispel the Mire Hag; after that, a reward that boss can offer." |
| White Stag node | "Wardens in it crit more often" | The only Grove effect with no number. | Give the number: "+N% crit chance" (check) |
| Samara branch (27) | "…Also adds its {dream} cards (listed below)." | Parentheses. Over 25. | "…Also adds the {dream} cards below." |
| Prismstorm | "each nightmare they hit that has {stacks:crown_static} {static} triggers its bolt … Triggered by a {combo:shatter} on a nightmare with {stacks:crown_static} {static}." | The same threshold is said twice in one card, and the sentence needs a re-read. | "Ice shards from the {combo:shatter} trigger the bolt of each nightmare they hit with {stacks:crown_static} {static}. Triggered by a {combo:shatter} on a nightmare with {stacks:crown_static} {static}." |
| Crowned Reactions (9 of 10 > 25) | e.g. Still Pool 44, Tempest 44 | Unchanged since the gap round. The boss rules are now on the card (good). | Split each into T6: effect line / "Bosses: …" / "Triggered by …" as three rows on the card. |
| Calling Whirligig (`callings.gd:25`) | "Shots hit a second nightmare within 2 cells for 60%." | "60%" of what? | "…for 60% of the hit's damage." |
| Calling Rootling (`callings.gd:24`) | "…turns to face a nightmare with {held}, and its hits on it add twice as much status." | "its hits on it" (rule 13). | "…and its hits on that nightmare add twice as much status." |
| Calling Acorn (`callings.gd:21`) | "Every 5th attack of a {family:acorn} aura Warden, the Wardens in its aura attack its target at once." | Rule 3 / T4: start with the subject. "its" twice. | "Every 5th attack of a {family:acorn} aura Warden, the Wardens in that aura also attack its target." |
| Firefly DETAILS (`callings.gd:30`) | "A {reaction}'s dispel doesn't count." | The line saying what dispels count *for* was cut, so this negative line now floats. | "Any dispel counts for its evolutions, except a {reaction}'s." |
| Bellflower DETAILS | "count as one ring … the rings go back to 0" | A raw "ring", now that a {ring} token exists. | Use {ring} / {rings}. |
| Codex "Calling hit" | "Deals the Warden's damage, scaled; a Warden slower than the hit's clock deals a share." | "hit's clock" is jargon. This is the entry 18 tips rely on. | "Deals part of the Warden's damage. A Warden that attacks slower than the hit's limit (often once a second) deals less." |
| Sunlit Rest preview (`dream_state.gd` sunlit_line) | "Next rest: your %s" | With "by the Heartwood" removed, the line no longer says what happens. | "Next rest: free Nurture for your %s" (check) |
| Grow button (`warden_panel.gd:368`) | "Grow into %s" with the raw display_name | "Grow into The Great Bell": 5 words and a capital "The". | Use `IconInfo.name_in_sentence()`: "Grow into the Great Bell". |
| Phone pending label (`drift_panel.gd:349`) | "Omen" | A bare noun where the PC line is an action. | "Pick Omen" (2 words) |
| Toadstool Throne tip | "One throne at a time: your oldest Warden's. Growing it keeps its age; selling it starts again." | Fine, but "it" is used for three things. | "One throne at a time: your oldest Warden's. Growing a Warden keeps its age; selling resets it." |

## 3. Patterns and rules

- **Rewrites are now shorter and use more short relative clauses.** "a Warden Lantern Wake lit", "a nightmare 3 Wardens hit", "the Warden Shared Caps picks". Rule: never put a card name or a counted subject inside a relative clause with no "that". Use "lit by X" / "When … , …".
- **Calling-hit tips end with the same 3-4 sentences.** Fix the order once: "[limit]. Bosses take half. Damage only: no status." Drop "Slower Wardens deal less." on the 18 tips that have it: the {free_hit} / Calling hit glossary covers it. That saves about 70 words in total.
- **"Other cards don't count it as a crit."** is on 3 Bonfire rows. Say it once in the Firefly DETAILS.
- **Thresholds go in front of the unit:** "50+ gold dispels", "3+ Wardens", "{rank} III+". This round got most of them right ("15+", "4+", "6+"). Pyre and Banked Fire are the exception ("with 50 dispels").
- **"(bosses N)" goes right after its number** (rule 9). Stream, Mudflats and Floodgate are models. Fathoms is the break.
- **Two tokens side by side** ("{toll} {tolls}", "{family:x} {family}") read as a stutter. Put a word between them or reorder.
- **A noun token used as a verb** ({flares}, "doses", "{tolls}"). Fine when it is the main verb of a short clause. Garbled when it follows "the last".
- **T8, the Calling-hit row (new template):** "[Trigger], [who] [hits / repeats / {flares}] [target]: [N% / at half damage]." Models: Trampled Ground, Change Ringing, Coda, Breaking Wave.
- **Advice lines** ("Works for:", "Safe.", "A bet") are back in 4 Dream tips. Strip them on sight (owner rule).

Templates T1-T7 still hold. The best current models:
- T1: River Mouth, Spreading Caps.
- T2: Undertow ("…10% more damage for each missing one, up to +40%").
- T3: Floodgate, Spreading Flame.
- T5 / Omen: Giants' Walk.
- T7: Strung Lights ("Direct hits on a {lit} nightmare deal 4% more damage for each glow it has entered, up to +20%.").

## 4. What already works

- **No evolution text is over 30 words.** Round 2c's long rows (Steady Beat at 30, Pile-On at 34, Retinue) are now 21-25 words.
- **Most "+" lines scan better than their "-" lines.** Of about 55 changed live rows, I count 5 worse: Constellation, Show the Way, Full Glow, the Deep Tone tip and Moth to Flame. The rest are better or new.
- **Tokens:** {ring}, {flare} and {lingering} are now tokens, and "pips" is gone. "Drifting Spores" reads cleanly. Allegro now explains its limit inside its own sentence.
- **Boss numbers on the card face:** Stream (bosses 7.5%), Mudflats, Floodgate, Spate, Silt.
- **"Sprouts and walls don't count."** is now one fixed form across the Firefly and Dewdrop rows.
- **Buttons:** every fixed button is now 1-4 words (Close / Continue / Start run / Carry perk / Auto-drift / Title screen / Use this map / Plant N). "Hunt %s" names the boss.
- **Grove:** the Memory Wardens now lead with their effect. Banish / Monoculture / Hunt's Rush II carry their card names. The sell tag "Can't be sold" scans in one glance.
