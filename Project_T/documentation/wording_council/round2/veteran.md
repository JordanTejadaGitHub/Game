# Wording Council round 2 (2026-10-23): veteran seat

Scope: text new or changed since round 1 (corpus_resources.txt, the "+" lines of corpus_ui_diff.txt), checked against
dream_hit_cards.gd, dream_state.gd (reaction_pool, REACTION_POOL_CAP, CARD_PRODUCT_CAP / CARD_CAP_ON, Undiluted),
reactions.gd (_fire / _show / _pool_shown, Thunderclap), dream_reaction_cards.gd (reaction_parts) and tower.gd
(HIT_FORM_MULTIPLIER, _hit). The theorycrafter's question for each line: stacks how, capped where, counted per what?

Two things stand out. First, the two damage systems changed (Reaction card bonuses now add into one pool capped at +300%,
and per-hit card power is now capped at ×4 because CARD_CAP_ON is true). No player text explains either, and four older
tips now say the opposite. Second, Undiluted's headline ("No Reaction ever goes off") has no gate in the combat code.

## 1. Top 10 problems

**1. Undiluted: the text promises a rule the code doesn't run (check), and promises more than it gives.**
`resource/dream/undiluted.tres`
Now: "No {reaction} ever goes off. Each status's own effect grows instead: {spored} ticks and {static} bolts deal double
damage." / tip "Cards that only pay off through a {reaction} aren't offered while you hold it. Lightning Rod stays quiet; a
{static} bolt still fires."
Problems:
- The dream_state.gd comment (5788-5795) says Reactions and EnemyStatuses read `DreamState.undiluted_on` at their gates.
  Only keeping_time.gd:959 (Last Chord), the offer filter (dream_state.gd:3419) and the two ×2 multipliers read it. Nothing
  in reactions.gd (`_on_status`, `_check_pairs`, `strike_bolt`, `check_at_half`) or scripts/enemy/ reads it, so Reactions
  still seem to trigger with the card held. Route to Roguelite Code to confirm.
- "Each status's own effect grows" reads as all six statuses. Only Poisoned ticks (UNDILUTED_POISONED 2.0) and the Charged
  bolt (UNDILUTED_CHARGED 2.0) change. Soak, Drowsy, Exposed and Root are untouched.
- Reaction-only cards you already hold stay held and do nothing (the code says it's one-way). The tip doesn't say so.
- Banned words: "goes off", "pay off". "Stays quiet" is an idiom. "Lightning Rod" is a raw name, not a token.

Rewrite: "{reactions} never trigger. {spored} ticks and {static} bolts deal double damage."
Tip: "Other statuses don't change. While you hold it, cards that work only through {reactions} aren't offered; ones you
already hold do nothing. {static} bolts still strike, but Lightning Rod never forms."

**2. Four Reaction cards' tips now say the wrong stacking rule.**
`ember_count.tres`, `grand_design.tres`, `crown_of_leaves.tres`, `the_long_walk.tres` (the .tres are unchanged, but the
mechanic changed under them this round).
Now: "Multiplies with your other Dream damage."
Problem: since the pool change (dream_reaction_cards.gd `reaction_parts`, dream_state.gd `reaction_pool`), these cards ADD
into one pool: 1 + min(sum, 3.0). They don't multiply. A careful reader stacks Ember Count +60% and Grand Design +80% as
×2.88. The real value is +140%.
Rewrite (all four): "Adds to your other card bonuses on {reactions}; together they give at most +300%."

The same goes for the per-hit cards that now feed the pool on Reactions but still multiply on hits: `passing_thread.tres`,
`front_line.tres` (both say "Multiplies…"), plus Old Rain and Soaked Rot. Rewrite for those: "On hits it multiplies with
your other Dream damage; on {reactions} it adds to your other card bonuses (at most +300%)."

**3. Both caps are invisible to the player.**
No codex, glossary or lesson entry mentions the Reaction pool (REACTION_POOL_CAP 3.0) or the ×4 hit line
(CARD_PRODUCT_CAP 4.0, CARD_CAP_ON true since 2026-10-22). Without them, a theorycrafter can't evaluate any of the 10 new hit
cards (they all go through `_note`, so all of them count toward ×4) or any Reaction card.
Add a Codex glossary entry "Card bonuses":
"On a Warden's hits, Dream card bonuses multiply together, up to ×4 in all. On {reactions}, card bonuses add together, up
to +300% in all; Nightshade and a Crowned {reaction}'s own card multiply on top."
Then link "×4" and "+300%" to it from the callout and from the tips in item 2.

**4. The callout "+N%" shows the previous Reaction's pool, not this one (check).**
`reactions.gd` `_fire` -> `_show` -> `_pool_shown` reads `reaction_pool_last`, but the Reaction computes its own pool
later (for example `_ignite` calls `_fire` at line 1027 and `_rx_cards` at 1048). So:
- The first Reaction of each kind in a run shows no "+N%".
- Each later one shows the last one's number. The per-nightmare parts (The Long Walk, Soaked Rot, Seeping, Old Rain,
  Passing Thread) differ from nightmare to nightmare.
- `reaction_pool` updates `reaction_pool_last` only when parts exist (line 484). A Reaction with no parts keeps showing the
  old "+N%".

Rest report: `reaction_pool_last` is never cleared, so "Reactions your build boosts:" lists Reactions from earlier blocks
with whatever number they last had.
Fix in code (Roguelite Code): read the pool before `_show`, or pass it in, and clear `reaction_pool_last` at each rest.

**5. "Ignite +180% from 4 cards" counts the wrong thing.**
`dream_state.gd` `reaction_build_text`: `cards = row[2]` is `parts.size()`, which counts pool parts, not cards:
- All role cards together are one unnamed part.
- Each per-hit factor is its own part, so one card can be both a feeder and a batch factor and count twice.
- Two copies of Soaked Rot are one part.

The number also leaves out the true multipliers (Nightshade, a Crowned card, Brimming), which are cards too.
Rewrite: "Ignite: +180% from cards" (+ " (capped at +300%)"). Drop the count, or count distinct card ids.
Rest-report header: "Reactions your build boosts:" -> "Card bonus on {reactions} (last one this block):".

**6. Nowhere to Run: the tiers are wrong in the text, and so is the clock.**
`nowhere_to_run.tres`
Now: "A {branch} or {final_form} Warden's direct hits deal 5% more for each second the nightmare has been in its range, up
to 40%." / tip "Leaving its range starts the count again. Area Wardens too. Hits only."
Problems:
- The code gates on `tier >= 2`, so Ascended Wardens qualify too. The text leaves them out.
- The clock isn't "time in range". It is the time since this Warden's first hit on that nightmare, and it restarts after any
  pause longer than max(1.5 s, 1.5 attacks) in its hits. Switching targets resets it even while the nightmare stays in range.
- The text has no "+" sign.

Rewrite: "{branch}, {final_form} and {ascended} Wardens' direct hits deal 5% more for each second they keep hitting the
same nightmare, up to +40%."
Tip: "A pause longer than 1.5 s (or 1.5 of its attacks) starts the count again. Area attacks count. Sprouts and walls don't.
Hits only."

**7. Bearing Down: "4% more" reads as a flat bonus. It ramps, and unranked Wardens get nothing.**
`bearing_down.tres`
Now: "Each attack in a row on the same nightmare deals 4% more, up to 10% for each {rank} the Warden holds."
Code: the streak starts at 0, so the 1st attack gets +0%, the 2nd +4%, the 3rd +8%, and so on. The cap is min(4% × streak,
10% × rank). Rank starts at 0 (tower.gd:470), so an un-Nurtured Warden's cap is 0.
Rewrite: "Each attack in a row on the same nightmare deals 4% more than the last, up to +10% for each {rank} the Warden has."
Tip: "The first attack on a target gets nothing; a new target starts again. A Warden without a {rank} gets nothing.
Single-target attacks only: not area attacks or beams. Sprouts and walls don't count. Hits only."

**8. The Tallest Tree: "add the store on top" reads as the whole store at once.**
`the_tallest_tree.tres`
Now: "Choose one Warden. Every other Warden's direct hits also store a fifth of their damage in it, and its direct hits add
the store on top." / tip "...One attack adds at most 6 times its own hit, never more than a {dispel} needs; the store holds
40 of its hits..."
Code:
- The tree can only be an attacking Warden (`is_court`).
- Sprouts and walls never feed the store.
- It spends once per attack (an area tree spends on one nightmare), at most 6× its bare hit.
- The cap is 40× the tree's hit without Dream cards (`get_bare_damage`).
- "Its own hit" / "its hits" don't say which damage counts.

Rewrite: "Choose one attacking Warden. Every other Warden's direct hits store a fifth of their damage in it, and each of its
attacks spends the store as extra damage."
Tip: "Each attack spends at most 6× its own hit (without Dream cards), never more than the nightmare has left. The store
holds at most 40× that hit. Sprouts and walls don't add to it. Choose it on its panel: the first time at any moment, later
only at a {rest}; moving it empties the store. Sold: the store is lost; choose again."

**9. Run Through: unstated area and flyer rules, an unstated "half of what", and the wrong distance word.**
`run_through.tres`
Now: "...direct hit carries on to the next 2 nightmares behind its target, each taking half." / tip "Only nightmares within
2 cells along the path; flyers don't count..."
Code:
- `not is_area`, so area attacks never carry.
- A hit on a flyer doesn't carry either.
- "Half" is half of the hit before the hit cards (`before = amount / _ctx[3]`).
- "Along the path" should use {steps} (rule 7).

Rewrite: "A {final_form} or {ascended} Warden's single-target direct hit also hits the next 2 nightmares behind its target,
each for half."
Tip: "Behind: within 2 {steps} further back along the path. Half of the hit before other Dream cards. Area attacks don't
carry; flyers neither carry nor take it. Damage only: no statuses, no other cards."

**10. The Codex Family pick entry calls the drift 60 pick a new family. It isn't.**
`codex_data.gd:26` "+" line
Now: "After drifts 1, 10, 35 and 60: choose a new Warden family for this run."
Code: `drift_director.gd` `family_pick_kind` returns &"deepen" at drift 60. That pick gives no new family; one of yours
calls back one more branch (DreamState.deepen).
Rewrite: "After drifts 1, 10 and 35: choose a new Warden family for this run. After drift 60: choose one of your families to
call back one more branch. With no family left to wake, the Heartwood gives Dreamlight instead." (check the last sentence
against the deepen pick's "nothing to deepen" path.)

## 2. Other flagged strings

| Where | Now | Problem | Rewrite |
|---|---|---|---|
| measured_blow.tres desc | "…first direct hit on each nightmare also deals 1% of its maximum health for each {rank}." | "its" is ambiguous (rule 13). The per-Warden memory isn't stated. Area hits count (no is_area check). | "From {rank} III, each Warden's first direct hit on a nightmare also deals 1% of the nightmare's maximum health for each {rank} the Warden has." |
| measured_blow.tres tip | "At most 10% of a nightmare's health from this card in all. Not bosses." | "Health" vs "maximum health". Sprouts and walls aren't covered. | "All Wardens together add at most 10% of a nightmare's maximum health. Area attacks count. Not bosses; Sprouts and walls don't count." |
| clean_strike.tres desc | "…no other family's status, or 50% more from a {final_form} or {ascended} form." | "Or 50% more from…" reads as a second condition. | "Direct hits deal 25% more to nightmares carrying no other family's status (+50% from a {final_form} or {ascended} Warden)." |
| clean_strike.tres tip | "Your own family's statuses don't count, and neither do walls or Sprouts. Hits only." | "Don't count" goes either way: do walls' statuses spoil it, or do walls get no bonus? Code: statuses from your own family, walls, Sprouts and non-Warden sources don't spoil it, and walls and Sprouts never get the bonus. No status at all also counts. | "Statuses from its own family, walls, Sprouts and cards don't spoil it; a nightmare with no status counts. Area attacks count. Sprouts and walls get no bonus. Hits only." |
| finishing_blow.tres tip | "Hits only: never statuses or {reaction} damage. Best on the Wardens near the Heartwood." | "Best on…" is strategy advice (no-hand-holding rule). Area and boss rules aren't stated. | "Hits only: never statuses or {reaction} damage. Area attacks and bosses count. Sprouts and walls don't." |
| open_road.tres desc | "…nightmares walking a straight of 4 or more path cells." | "A straight" as a noun is jargon. Code: `floori` of the distance between the end-point centres ≥ 4, which may mean 5 cells on screen (check). | "Direct hits deal 25% more to nightmares on a straight stretch of path at least 4 cells long." Tip: add "Area attacks count. Sprouts and walls don't." |
| standing_tall.tres desc | "…for each attacking base or {branch} Warden {touching} it, up to 45%." | "Base" isn't a defined term (the glossary names Branch and Final form only). Missing "+". | "…for each attacking first-form or {branch} Warden {touching} it, up to 3 (+45%)." |
| standing_tall.tres tip | "Sprouts and walls don't count; its court can be any family. Hits only." | "Court" is new jargon. | "Sprouts and walls don't count; the Wardens around it can be any family. Hits only." |
| trophies.tres desc | "A Warden that lands 10 killing blows in one {drift} deals 4% more…, up to 40%." | "Killing blows" isn't the house term ({dispel}). It reads as one-time, but it repeats each drift. Missing "+". | "Each {drift} in which a Warden {dispels} 10 nightmares with direct hits, its direct hits deal 4% more for the rest of the run, up to +40%." |
| trophies.tres tip | "{deeply_blighted} nightmares and bosses count 5. Once a {drift}. Kept when it grows, lost if sold. Hits only." | "Once a {drift}" is redundant after the rewrite. Sprouts and walls aren't covered. | "{deeply_blighted} nightmares and bosses count as 5. Kept when it grows, lost if sold. Sprouts and walls don't count." |
| towering.tres / all hit cards | — | Final forms already deal ×1.4 on direct hits and Ascended ×1.25 (Tower.HIT_FORM_MULTIPLIER), but no player text says so. Clean Strike's +50% and Towering stack on top of a hidden number. | Add to the Final form glossary entry: "Final forms that attack directly deal 40% more with direct hits." Ascended: "25% more" (check the intent: ×1.25 replaces ×1.4, it doesn't stack). |
| damp_rot.tres (Soaked Rot) | "…{spored} ticks and {reaction} damage that uses {spored} are 50% higher." | Ticks multiply; the Reaction part adds into the pool. Add a tip. | Tip: "On ticks it multiplies with your other Dream damage; on {reactions} it adds to your other card bonuses (at most +300%)." |
| thunderclap.tres | "…arcs to nightmares with {damp} in range… ×12 damage, ×6 per arc, and each arc adds 1 {static}." | Code needs {stacks:need_damp}+ {damp} on the arc target, within 2.5 cells, at most the 8 nearest. "×12" has no base (rule 5); the base is the triggering Warden's damage. | "It deals 12× the damage of the Warden that triggered it. Up to 8 nightmares within 2.5 cells with {stacks:need_damp}+ {damp} take 6× and gain 1 {static}. Needs …" |
| lightning_rod.tres | "It draws lightning: {static} bolts from nightmares within 3 cells strike it instead, for ×2 damage." | Unclear subject. "×2" breaks rule 5. | "The nightmare draws lightning: {static} bolts from nightmares within 3 cells strike it instead, for double damage." |
| warden_panel.gd:289 | "Reactions: set off %d · fed %d" | "Set off" is banned (rule 10). "Fed" is unexplained. | "Reactions: triggered %d · helped %d" |
| warden_panel.gd:1389 | "The Tallest Tree: every other Warden's direct hits store damage in this one." | No amount. Sprouts aren't covered. | "The Tallest Tree: every other Warden's direct hits store a fifth of their damage in this one." |
| dream_hit_cards.gd panel_line | "The Tallest Tree: %d stored" | Stored what? | "The Tallest Tree: %d damage stored" |
| waystone.gd PANEL_LINE | "Old Waystone: +1 Dew per dispel" | Per whose dispel? (Only this Warden's.) The "1" is hard-coded instead of DEW_PER_DISPEL. | "Old Waystone: +1 {dew} for each nightmare it dispels" (format from DEW_PER_DISPEL) |
| calling_paths.gd:39 | "A clump gives a {dose} for each {mushroom} in it." | The trigger is gone: when does it give one? The old text said "Stepping on". | "A nightmare stepping on a clump gets a {dose} for each {mushroom} in it." |
| calling_paths.gd:174 | "…nightmares within 2 {steps} of it in that {water} get {damp} too." | How many stacks? (check) | "…get N {damp} too." (from code) |
| calling_paths.gd:177 | "…in the longest {water} with nightmares in it…" | Awkward; "it" is ambiguous. | "…in the longest {water} that has nightmares in it…" |
| codex_data.gd:279 night_chimes | "…Dreamcatcher's threads set off {static} at 12 stacks." | "Set off" is banned. 12 is hard-coded. | "…Dreamcatcher's threads trigger the {static} bolt at {field:…} stacks." |
| family_pick_screen.gd:918+ | "Not in this dream" | The glossary term is "Not in this run" (codex_data.gd:70). | "Not in this run" |
| family_pick_screen.gd:149 | "Choose a family to deepen" | "Deepen" is undefined. | "Choose a family to call back one more branch" |
| warden_header_view.gd:534 | "Sprites walk %d cells up the path." | Along the path, so {steps} (rule 7). | "Sprites walk %d {steps} up the path." |
| lesson_card.gd:222 | "The whole pile wears off 5 s after the last stack…" | "Pile" is a new word for stacks. | "All its stacks wear off 5 s after the last one lands, so keep hitting it." |
| struck_twice.tres tip | "Multiplies with your other Dream damage." | True, but it's now capped at ×4. | "…Multiplies with your other Dream damage (at most ×4 in all)." |
| run_history.gd:873/875 | "Past the x4 card line:", "Reaction factors:" | For developers only. Confirm the player never sees them. | (none if dev-only) |

## 3. Patterns / rules

- **The 10 hit cards don't share a template.** Each says or skips area, Sprouts/walls, bosses and flyers at random. Fix:
  every hit-card tip ends with the same three answers: "Area attacks count/don't. Sprouts and walls don't count. Hits
  only."
- **Tier lists are incomplete.** "{branch} or {final_form}" while the code gates at tier ≥ 2 includes Ascended. Fix: list
  every tier the code accepts.
- **The "+" goes missing on caps.** The new cards say "up to 40%"; the house style is "up to +30%". Fix: always "up to +N%".
- **"Multiplies with your other Dream damage" is now half-true for anything that also touches Reactions.** Fix: use the two
  stacking sentences below.
- **"Its" is ambiguous when both a Warden and a nightmare are in the sentence** (Measured Blow, The Tallest Tree). Fix:
  rule 13.
- **Per-Warden memory isn't stated** (Measured Blow, Nowhere to Run, Bearing Down, Trophies all remember per Warden,
  keyed by cell). Fix: "Each Warden counts its own."

## Conventions (fixed phrasings)

- Hit stacking: "Multiplies with your other Dream damage (at most ×4 in all)."
- Reaction stacking: "Adds to your other card bonuses on {reactions} (at most +300% in all)."
- Both: "On hits it multiplies with your other Dream damage; on {reactions} it adds to your other card bonuses."
- Direct hit: define it once in the glossary: "A Warden's own attack landing: not statuses, clouds, {jumps}, bolts, echoes
  or {reactions}." Then "direct hits" in descriptions and "Hits only" in tips.
- Rank scaling: "for each {rank} the Warden has". Say "A Warden without a {rank} gets nothing" whenever that is true.
- Ramps: "N% more than the last, up to +M%". Never a bare "N% more" for a ramp.
- Forms: "first-form / {branch} / {final_form} / {ascended} Wardens", listing every tier the code accepts.
- Reaction base: "N× the damage of the Warden that triggered it."
- Callout and report: "+N% from cards (capped)". No card count unless it counts distinct cards.

## 4. What already works

- The new cards lead with the effect and put limits in the tip. Finishing Blow, Open Road and Clean Strike are short and
  scannable.
- The numbers match the constants: 40% / a third / rank II; 4% / 10% per rank; 25% / 4 cells; 25% / 50%; 5% / +40%;
  15% / 3; 10 kills / 5 / 4% / +40%; half / 2 / 2 cells; 1% / III / 10%; a fifth / 6× / 40×; ×2 / ×2.
- Towering's tip gives worked numbers (rank V +30%, VII +50%), and they match TOWERING_PER_RANK. Copy that habit.
- "Doesn't add {held}" replacing "Never {held}" in calling_paths reads correctly now.
- The Codex Arc / Set Off / Rank entries now read live fields.

Flagged: 10 top problems + 27 table rows (37 strings), plus the Undiluted code gap and the stale-callout code bug for
Roguelite Code.
