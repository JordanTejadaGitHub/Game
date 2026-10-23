# Wording Council round 2 (2026-10-23): plain_english

Seat: second-language readers and future translators. Scope: text new or changed since round 1
(corpus_resources.txt, "+" lines of corpus_ui_diff.txt). Words checked against round 1's "words to avoid" list
(documentation/wording_council/plain_english.md §3) and the lead review's phrasing rules (wording_council_review.md §5).
Card names that are idioms are fine as names; only descriptions and tips are judged.

Flagged: **52 strings** (10 in the top list, 42 in the table). Localisation risks: 11 new code-assembled strings.

---

## 1. Top 10 problems

### 1. "Dewdrop", "Firefly", "Sporeling" now mean two things (calling_paths.gd, callings.gd; seeping_in, spore_ring)
- Now: `{warden:dewdrop}` was replaced by plain "Dewdrop(s)" across calling_paths.gd 141-208 and callings.gd 19-33,
  with a new definition "A Dewdrop is any Dewdrop form." The same for "Firefly" ("A Firefly is any Firefly Jar form")
  and "Sporeling". The base Wardens are still named Dewdrop and Sporeling, and the Dream cards Settling Spores ("after a
  Sporeling hits") and Spore Huddle ("each other Sporeling {touching} it") use the bare word.
- Problem: one word, two game meanings: the base Warden and every member of its family. A reader can't tell
  if "Dewdrops don't count" means the base form only or the whole family. Round 1's ruling 5 settled this: use the
  `{family:}` token. "Firefly" is also a third name for the Firefly Jar family.
- Rewrite: "{family:dewdrop} Wardens" wherever the family is meant, e.g. "The path {touching} your {family:dewdrop}
  Wardens is {water}. A {family:dewdrop} Warden's hit there {dew_splashes}: …"; "Glows up to 4 {steps} apart join.
  {family:firefly_jar} Wardens deal 5% more …". Settling Spores: "For 12 {steps} after a {family:sporeling} Warden
  hits a nightmare, …". Spore Huddle (check: base form only, or the family?): "A {warden:sporeling}'s hits add 1 more
  {stack} of {spored} for each other {warden:sporeling} {touching} it, up to 3 more." Drop the three "A X is any X
  form" sentences once the token is back.

### 2. Undiluted (NEW)
- Now: "No {reaction} ever goes off. Each status's own effect grows instead: {spored} ticks and {static} bolts deal
  double damage." Tip: "Cards that only pay off through a {reaction} aren't offered while you hold it. Lightning Rod
  stays quiet; a {static} bolt still fires."
- Problem: three words from the avoid list ("goes off", "grows" = change form, "pay off"), plus "fires". "Each
  status's own effect grows" promises a change for every status, but only two are named (check: do {damp}, {drowsy},
  {marked} change too?). "Stays quiet" is flavour standing in for a rule. Lightning Rod is a raw name, not a token.
- Rewrite: "{reactions} never trigger. Instead, {spored} ticks and {static} bolts deal double damage." Tip: "Cards that
  work only through {reactions} aren't offered while you have this card. {named_combo:lightning_rod} doesn't trigger
  either, but {static} bolts still strike."

### 3. Run Through (NEW)
- Now: "A {final_form} or {ascended} Warden's direct hit carries on to the next 2 nightmares behind its target, each
  taking half." Tip: "Only nightmares within 2 cells along the path; flyers don't count. The carried hits are damage
  only: no statuses, no other cards."
- Problem: "carries on" is a phrasal verb on the avoid list (it also means "continues doing"). "Behind" has no fixed
  direction for a learner (further back on the path? behind the Warden?). "Within 2 cells along the path" breaks rule 7
  (along the path = {steps}). "Carried hits" is a new invented noun.
- Rewrite: "A {final_form} or {ascended} Warden's direct hit also hits the next 2 nightmares behind its target on the
  path, for half damage each." Tip: "Only nightmares within 2 {steps} of the target; flyers don't count. These extra
  hits deal damage only: no statuses, no other cards."

### 4. Trophies (NEW)
- Now: "A Warden that lands 10 killing blows in one {drift} deals 4% more with its direct hits for the rest of the run,
  up to 40%." Tip: "{deeply_blighted} nightmares and bosses count 5. Once a {drift}. Kept when it grows, lost if sold.
  Hits only."
- Problem: "killing blows" is a new name for {dispel} (Hard-Won Rings says "the one whose hit brings a nightmare to 0
  health"); "for the rest of the run" is on the avoid list (rest is a game term). "Count 5" is missing "as". "Once a
  {drift}": once what?
- Rewrite: "A Warden that {dispels} 10 nightmares with its own hits in one {drift} deals 4% more with its direct hits
  until the run ends, up to +40%." Tip: "{deeply_blighted} nightmares and bosses count as 5. At most +4% each {drift}.
  Kept when it grows; lost if sold. Hits only."

### 5. The Tallest Tree (NEW)
- Now: "Choose one Warden. Every other Warden's direct hits also store a fifth of their damage in it, and its direct
  hits add the store on top." Tip: "… One attack adds at most 6 times its own hit, never more than a {dispel} needs;
  the store holds 40 of its hits. Sold: choose again."
- Problem: "on top" is an idiom; "the store" (noun) reads as a shop to many learners; "it / its / their" point at three
  different things in one sentence (rule 13). "Sold: choose again" is a fragment with no subject.
- Rewrite: "Choose one Warden. A fifth of the damage of every other Warden's direct hits is saved in the chosen Warden.
  Its direct hits add the saved damage." Tip: "Choose it on its panel: at any time the first time, after that only at
  a {rest} (moving it empties the saved damage). One attack adds at most 6 times its own hit, and never more than the
  nightmare has left; it saves at most 40 times its own hit. If it is sold, choose another Warden."

### 6. Clean Strike (NEW)
- Now: "Direct hits deal 25% more to nightmares carrying no other family's status, or 50% more from a {final_form} or
  {ascended} form." Tip: "Your own family's statuses don't count, and neither do walls or Sprouts."
- Problem: "other" than whose family? The tip says "your own family", but the player has several families: the code
  means the hitting Warden's family. "Neither do walls or Sprouts" is a double negative after a negative.
- Rewrite: "Direct hits deal 25% more to a nightmare with no status from another family than the hitting Warden's
  (50% from a {final_form} or {ascended} Warden)." Tip: "Statuses from the Warden's own family, from walls and from
  Sprouts don't count against it. Hits only."

### 7. Measured Blow (NEW)
- Now: "From {rank} III, a Warden's first direct hit on each nightmare also deals 1% of its maximum health for each
  {rank}." Tip: "At most 10% of a nightmare's health from this card in all. Not bosses."
- Problem: "its maximum health": the Warden's or the nightmare's? (rule 13). "In all" is on the avoid list.
- Rewrite: "From {rank} III, a Warden's first direct hit on each nightmare also deals 1% of that nightmare's maximum
  health for each {rank}." Tip: "At most 10% of a nightmare's maximum health in total from this card. Not bosses."

### 8. "set off" / "go off" came back in new and changed text
- Now: icon_info.gd:20 Drowsy "can fall {asleep} and set off {reactions}"; lesson_card.gd:222 Poison "it can set off
  {reactions}"; codex_data.gd:280 Night Chimes "threads set off {static} at 12 stacks"; warden_panel.gd:289
  "Reactions: set off %d · fed %d"; Gone to Seed "sets off a {reaction}"; Reprise "goes off again"; Mountain's Fall
  cost "can go off only half as often"; Never Quite Dry "set off by a status landing"; Nod Off "don't set it off".
- Problem: ruling 4 / rule 10 says "trigger" in rules text. lesson_card.gd:216 already uses "trigger"; the line below it
  does not.
- Rewrite: "trigger" in each: "… can fall {asleep} and trigger {reactions}"; "Reactions: triggered %d · helped %d";
  "triggers a {reaction}"; "triggers again 1 s later"; "{named_combo:avalanche} triggers only half as often";
  "don't trigger it".

### 9. "{static} stops 1 short of a bolt" (9 places)
- Now: Ebb, Gone to Seed, Mixed Company, Mycelium, Overnight, Second Verse tips; calling_paths.gd:169; and the same
  shape "{drowsy} stops 1 short of {full}" (calling_paths.gd:199).
- Problem: "one short of" is an idiom on the avoid list; a learner reads "short" as length.
- Rewrite: "{static} stops 1 below the count that triggers a bolt." / "{drowsy} stops 1 below {full}."

### 10. Heartwood Sapling (Warden)
- Now: "A seedling of the Heartwood, 2×2 and rooted for good. … Each {leaf} lost withers the yield 5% until the next
  {rest}."
- Problem: "rooted" (Root is a status) and "for good" (idiom) are both on the avoid list; "withers the yield" uses two
  rare words for "lowers what it gives".
- Rewrite: "A seedling of the Heartwood, 2×2; it can't be moved. … Each {leaf} lost lowers what it gives by 5% until
  the next {rest}."

---

## 2. Other flagged strings

| Where | Now | Problem | Rewrite |
|---|---|---|---|
| bearing_down desc | "…deals 4% more, up to 10% for each {rank} the Warden holds." | "holds" for rank is odd; cap reads as "10% per hit" | "…deals 4% more than the last, up to 10% for each {rank} the Warden has." |
| bearing_down tip | "Wardens that aim at one nightmare; not area attacks or beams. A new target starts again." | fragment; "starts again": what starts? | "Only Wardens that attack one nightmare at a time; not area attacks or beams. A new target resets the bonus. Hits only." |
| finishing_blow tip | "Best on the Wardens near the Heartwood." | strategy advice (no-hand-holding rule); "near" unlinked | cut the sentence |
| open_road desc | "walking a straight of 4 or more path cells" | "straight" as a noun (avoid list) | "walking a straight stretch of path at least 4 cells long" |
| standing_tall tip | "its court can be any family" | "court" is an invented, undefined noun | "the Wardens touching it can be any family" |
| nowhere_to_run desc | "for each second the nightmare has been in its range" | fine; "its" could be the nightmare's | "…in that Warden's range" |
| clean_night (Hard-Won Rings) tip | "The {rank} waits until you Nurture." | personification hides the rule | "You get the {rank} the next time you Nurture this Warden." (check) |
| towering tip | "ties go to the higher form" | idiom | "on a tie, the higher form counts" |
| dream_thorncoil desc | "thorns for nightmares with {held}: each second, every nightmare…" | two colons; fragment | "…into {warden:thorncoil}s ({dew:…}): every nightmare with {held} in its range takes thorn damage each second." |
| thorncoil (Warden) desc | "while one with {held} is in its range, it takes thorn damage" | "it" = Warden or nightmare? | "each nightmare with {held} in its range takes thorn damage every second." |
| flashover desc | "half {jumps} to the nearest one it missed" | "half" of what; "it" = attack or Warden | "half of the damage {jumps} to the nearest nightmare the attack missed." |
| hammerfall desc | "half {jumps} to the nearest other nightmare" | half of what | "half of the hit {jumps} …" |
| gathering_storm tip | "A bet: pays when several {jump} cards hit one pack." | "pays" (avoid list) | "Risky: needs several {jump} cards hitting one pack." |
| headlong desc | "pays all its {dew} at once" | "pays" | "gives all its {dew} at once" |
| headlong tip | "a leak costs {leaves} only"; "a board that takes a whole drift at once" | "leak" undefined; "takes" (avoid list) | "a nightmare reaching the Heartwood costs only {leaves}"; "Risky: needs Wardens that can handle a whole {drift} at once" |
| heavy_going desc | "nightmares walking slowed" | odd grammar | "slowed nightmares that are still walking" |
| heavy_going tip | "A slowed nightmare drips while it counts." | flavour that reads as a rule | cut, or "(a slowed nightmare shows drops of water)" (check) |
| never_quite_dry desc | "leaves the statuses it spent at half their {stacks}" | "leaves" verb (leaves = lives) | "keeps the statuses it used, at half their {stacks}" |
| nod_off desc | "keeps one sleeper at a time" | invented noun | "can keep only one nightmare {asleep} at a time" |
| nod_off tip | "every Warden gains from the stop" | advice; vague | cut |
| nothing_wasted tip | "a crust that blocks part of each hit" | "blocks" (block = 5 drifts); differs from Wash Away | "a crust that absorbs part of each hit until it breaks" |
| wash_away desc | "wear its {dread_shell} down twice as fast" | phrasal verb | "break its {dread_shell} twice as fast" |
| wash_away tip | "a crust that takes part of each hit" | "takes" (avoid list); differs from Nothing Wasted | "a crust that absorbs part of each hit until it breaks" |
| old_rain desc | "if it spends a status a card made last longer" | stacked relative clauses | "if one of the statuses it uses was made to last longer by a card" |
| parting_puff tip | "A puff that dispels doesn't puff again." | invented verb "puff" | "Damage from this card that dispels a nightmare doesn't trigger it again." |
| reprise desc | "goes off again 1 s later" | "go off" | "triggers again 1 s later" |
| struck_twice tip | "One waiting hit per nightmare; it fades after 2 s." | invented "waiting hit" | "Each nightmare holds one bonus at a time; it ends after 2 s if unused." |
| steeped tip | "At most 4 s past the last landing" | "landing" as noun | "At most 4 s past the moment the status was last added" |
| lightning_rod desc | "It draws lightning: {static} bolts … strike it instead" | "it" = the nightmare? never named | "The nightmare draws lightning: {static} bolts from nightmares within 3 cells strike it instead, for ×2 damage." |
| thunderclap desc | "hits it hard and arcs to nightmares" | "it" unnamed; "hard" vague; "arcs" clashes with the Codex term Arc (Jarlink) | "A Thunderclap hits the nightmare and {jumps} to nightmares with {damp} in range." (check: are these {jumps}?) |
| great_bell desc | "it peals across a huge range"; "is struck by its bolt" | "peals" (avoid list); "its bolt" = the Bell's or the nightmare's own? | "it pulses across a huge range: …, and every nightmare with … {static} triggers its own bolt for half damage" (check) |
| boulderback (Warden + card) | "it always crits on those with {drowsy}" | "crits" is gamer slang | "its hits are always critical hits on nightmares with {drowsy}" |
| calling_paths.gd:39 | "A clump gives a {dose} for each {mushroom} in it." | who gets it, and when? ("stepping on" was removed) | "A nightmare stepping on a clump gets a {dose} for each {mushroom} in it." (check) |
| calling_paths.gd:62 | "Any nightmare dispelled … leaves a new {mushroom}" | "leaves" verb | "… makes a new {mushroom} grow there" or "drops a new {mushroom}" |
| calling_paths.gd:72 | "Glows up to 4 {steps} apart join up." | phrasal verb | "Glows up to 4 {steps} apart join." |
| calling_paths.gd:141 | "{damp} calls up to 2 Dewdrops {near} it"; "Starting rings don't count" | "calls" clashes with Calling / call a drift; "ring" (avoid list) | "{damp} makes up to 2 {family:dewdrop} Wardens {near} it make a {free_hit}"; "The first pulses don't count" (check) |
| calling_paths.gd:169 | "A thread shows each carry." | invented noun "carry" | "A thread shows each status that moves." (check) |
| callings.gd:31 | "so it is weak against flyers" | advice | cut ("Flyers pass over them." is enough) |
| dream_keywords.gd:59 | "{damp}: water hits deal 20% more damage to the nightmare." | "water hits" undefined; Soaked Rot says "{family:dewdrop} hits" | "{damp}: hits from {family:dewdrop} Wardens deal 20% more damage to the nightmare." |
| codex_data.gd:14 Dreamlight | "from some Wardens' shards" | "shards" undefined | name the Wardens or link the term (check) |
| codex_data.gd:23 Perfect block | "Its rest pays {dew:+20}." | "pays" | "Its rest gives {dew:+20}." |
| codex_data.gd:52 Harvest | "catches Dew … and pays it at the rest" | "catch", "pays" | "collects Dew … and gives it to you at the rest" |
| codex_data.gd:90 Arc | "catches Phantoms gliding through" | "catches"; "Phantoms" (round 1: = flyers) | "also hits flyers crossing it" (check) |
| codex_data.gd:182 Crowned | "its neighbours catch {spored} + {drowsy}" | "catch" (Caught is a status); "+" as a word; "neighbours" undefined distance | "nightmares {near} it gain {spored} and {drowsy}" (check distance) |
| codex_data.gd:280 Old Growth | "neighbours attack 10% faster" | undefined distance | "Wardens {touching} it attack 10% faster" (check) |
| codex_data.gd:576 Asleep | "a big hit wakes it" | vague | give the threshold, or "a hit wakes it" (check) |
| lesson_card.gd:222 Poison | "The whole pile wears off 5 s after the last stack" | "pile" new word for stacks; "wears off" | "All its stacks end 5 s after the last one was added" |
| family_pick_screen.gd:35 / :149 | "One of yours could have grown another way." / "Choose a family to deepen" | flavour hides the mechanic; "deepen" is an invented verb | "Choose a family you have: one of its Wardens gets another way to grow." (check) |
| run_through, trophies, measured_blow, the_tallest_tree tips | "Hits only." / "Not bosses." | fine; listed only to note it is the right shape | none |

(The last row is not counted.)

---

## 3. Patterns and rules

- **Token replaced by a bare family word.** {warden:dewdrop} → "Dewdrop" made one word mean two things. Fix: {family:x}
  Warden for the family, {warden:x} for one form (ruling 5).
- **"set off / go off / fire" are back** in 9 new or changed strings. Fix: "trigger".
- **"stops 1 short of"** in 9 tips. Fix: "stops 1 below".
- **Money words for effects** ("pays", "pay off"): Gathering Storm, Headlong, Undiluted, Codex. Fix: "gives", "works".
- **New nouns for mechanics nobody defined:** killing blow, court, store, carried hits, waiting hit, sleeper, pile,
  carry, shards. Fix: reuse the game term ({dispel}, Wardens touching it) or say it in full.
- **"it / its" with two candidates** (Measured Blow, Tallest Tree, Thorncoil, Lightning Rod, Thunderclap, Flashover).
  Fix: rule 13, name the nightmare or the Warden again.
- **"half" with no noun** ("half {jumps}"). Fix: "half of the hit / damage".
- **Two phrasings for the dread shell** ("blocks" / "takes" part of each hit). Fix: "absorbs" in both.
- **Strategy advice in tips** ("Best on …", "gains from the stop", "so it is weak against flyers"). Fix: cut.
- **"Safe." / "A bet:" tags** remain on every changed card. They are idioms for learners (round 1 §3); not ruled in
  round 1. Owner call: keep, or "Works on its own." / "Risky: needs …".

### Words to avoid: new additions from this round
| Avoid | Use instead |
|---|---|
| killing blow | dispels (a nightmare) |
| carry on / carried hit | also hits / extra hit |
| store (noun), on top | saved damage, adds |
| court | Wardens touching it |
| crits | critical hits |
| pile (of stacks) | all its stacks |
| one short of | 1 below |
| arc (verb, outside Jarlink) | {jumps} |
| deepen (family pick) | say what the pick gives |

---

## 4. Localisation risks (new code-assembled strings in the diff)

| File:line | String | Risk |
|---|---|---|
| run/dream_state.gd:3142 | `"Reroll · " + _left_this_run(rerolls_left)` | concatenation; word order fixed |
| run/dream_state.gd:3148 | `"Banish · " + _left_this_run(banishes_left)` | same |
| run/dream_state.gd:3151 | `"… this run has %d left. …"` | number plural ("1 left" vs plural agreement in other languages) |
| run/dream_state.gd:3159 | `"Banishes left: %d"` | plural noun before a number |
| run/dream_state.gd:546 | `"%s +%d%% from %d card%s%s"` with `"" if cards == 1 else "s"` and `" (capped)"` | English-only plural by adding "s"; three pieces glued |
| ui/warden_panel.gd:289 | `"Reactions: set off %d · fed %d"` | plurals; also "set off" (see top 8) |
| ui/warden_panel.gd:1389 | `"The Tallest Tree: … this one." + ("" if … else " Moving it empties the store.")` | sentence added by `+`; keep as two whole strings |
| ui/warden_header_view.gd:534 | `"Sprites walk %d cells up the path."` | "1 cells"; plural |
| run/dream_hit_cards.gd:402 | `"The Tallest Tree: %d stored"` | fragment; plural |
| run/dream_reaction_cards.gd:229, 253 | `"Grand Design +%d%%"` | number format (+N% order differs by language) |
| run/run_history.gd:875 | `"Reaction factors: " + String(line)` | concatenation (likely a debug report: check if players see it) |

family_pick_screen.gd:149 (`"Choose a family to deepen" if … else "Choose a family to wake"`) uses two whole strings:
safe.

---

## 5. What already works

- Finishing Blow, Open Road, Nowhere to Run: one effect, one number, one condition; "Hits only: never statuses or
  {reaction} damage" is clear and repeated the same way.
- lesson_card.gd:216 now says "they trigger a {reaction}" and explains "enough stacks": the model for the other lines.
- Codex "Asleep" and "falls {asleep}" lines now use the token (Drowsy/Asleep split is clean in the diff).
- "Reroll" and "Banish" labels: short, one name each, no idiom left ("Dream again", "Let go" are gone).
- UK spelling ("neighbours") applied in the changed Codex lines.
- Root Wardens open with "It damages every nightmare in range.": plain and the same on all ten.
