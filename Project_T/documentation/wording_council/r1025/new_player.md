# Wording Council 2026-10-25: new_player seat

Seat: I have played a few mobile games, never a tower defence or a roguelite. One read (about 5 s): do I know what
happens, to what, when, and how much? Tokens read as their on-screen names: {damp} Soak, {held} Root, {marked}
Exposure, {static} Charge, {spored} Poison, {dread_shell} dread shell, {frozen} Frozen.
Read: corpus_resources.txt (NEW lines), corpus_ui_diff.txt ("+" lines), frost_draft.md 1 and 4-5,
frost_review_player.md 6, live `scripts/ui/icon_info.gd` (it already has {frost}, {frostburst}, {cold_snap}) and
`codex_data.gd:130`. "Works for / Safe / A bet" lines kept as the house convention.

## 0. Frost in one paragraph (my verdict)

Every game I have played taught me that frost and ice slow things down or stop them. Here Frost does neither: it
counts up and pops. So **the first Frost text a player reads has to say "it doesn't slow" out loud**, or every
player will believe it slows and wonder why it doesn't. Nothing in the draft or in the player review says that;
both only leave the slow out. Worse, the game still ships the word **Frozen** ("Frost stops it for a moment",
`icon_info.gd:27`) and Still Target II / Still Target / Frozen Ground, so the old meaning stays on screen next to the
new one. Fix order: (a) retire "Frozen" from every live text when Frostfern / Hoarfrost / Tidecaller stop Holding;
(b) one sentence in the Frost glossary: "It doesn't slow."; (c) say the number (10) instead of "{full}" wherever
Frost bursts, because "full" makes me open a second tooltip to learn the count.

Which Frost texts are better: the **player review's (section 6)** in 8 of 10 cases. It names the number, says the
burst nightmare is hit too, and says "Every other spin". The draft wins only on Cold Snap ("stop wearing off" vs the
review's identical OK) and on Hoar Fog length. My versions below take the review's and fix what is still unclear.

## 1. Top 10 problems

| # | Where | Now | Problem | Rewrite |
|---|---|---|---|---|
| 1 | `icon_info.gd:27` {frozen}; `still_target.tres` tip; `still_target_ii.tres`; `dewdrop_hidden.tres`; `dewdrop_ascension.tres`; `dream_frostfern / dream_hoarfrost / dream_tidecaller` | "Frozen: Frost stops it for a moment." / "{frozen} nightmares count: frost adds 1 {held}." / "it freezes nightmares that have {damp}" | Once Frost exists, "Frozen" and "freezes" tell me Frost stops things. It is the exact belief the new rule breaks. Two meanings of one word on one screen. | Retire {frozen} with the Hold. Still Target tip: delete. Still Target II: "+40% crit chance against nightmares with {drowsy} or {held}." Grove Frostfern: "The {warden:dewdrop} can grow into the {warden:frostfern}, then the {warden:hoarfrost}: their hits build {frost} until it bursts. Also adds the {card:deep_frost} card." (check: Deep Frost requirement) |
| 2 | Frost glossary, `icon_info.gd:29` (live) / draft 4 / review 6 | Live: "Builds up on a nightmare. At {full} it bursts in a {frostburst}: damage around it, 1 Frost to the nightmares beside it, and a {cold_snap}." Review: "At 10 Frost a nightmare bursts, hurting it and up to 4 beside it. They gain 1 Frost; its statuses pause 2 s." | Live: "at {full}" hides the 10; "damage around it" hides that it is hit too; "a {cold_snap}" is a third word to look up. Neither says it doesn't slow. Review: "They" / "its" in one line point at two different nightmares. | "Builds up on a nightmare. It doesn't slow. At 10 (bosses 15) it bursts: a {frostburst} hurts it and up to 4 nightmares beside it, and gives them 1 Frost each." (Cold Snap in its own entry, linked) |
| 3 | Brittle (draft 4 / review 6) | Draft: "...spends it: for 4 s it resists nothing (bosses 2 s)." Review: "A Frostburst spends 10 {marked}: for 4 s the nightmare has no resistances or blight coat (bosses 2 s)." | "Resists nothing" doesn't tell me what changed. "Blight coat" is not a name I ever see: the screen calls it the dread shell (owner: say "shell"). Review drops "on a nightmare with". | "A {frostburst} on a nightmare with 10 {marked} spends it: for 4 s it has no resistances and its {dread_shell} blocks nothing (bosses 2 s)." (check: elites 3 s not shown; add "elites 3 s" if room) |
| 4 | Third Reaction, Rime (draft) / Blizzard (review) | "A Frostburst on a nightmare with 8 {damp} spends it: the burst reaches 2 cells and gives 2 {frost}." | "Rime" is a word I don't know and hear as "rhyme". The owner may use **Flash Freeze**: clear to me ("big sudden cold"), but "Freeze" again suggests a stop; it needs the "doesn't slow" glossary line from #2 to be safe. Blizzard reads "bigger, wider", which is what it does. Draft drops "hits up to 6". | Name: Flash Freeze if the owner wants it, else Blizzard. "A {frostburst} on a nightmare with 8 {damp} spends it: that burst reaches 2 cells, hits up to 6 and gives them 2 {frost} each." |
| 5 | Cold Snap, `codex_data.gd:130` vs draft 1 / 4 | Codex: "...stop wearing off for 1.5 s (bosses 0.5 s)." Draft: 2 s (bosses 1 s). Review Frost line: "statuses pause 2 s" | Two numbers for one rule (check which is live). "Pause" (review) vs "stop wearing off" (Codex) are two phrasings; I'd think "pause" means the statuses stop working. | Keep one phrasing: "After a {frostburst}, the nightmare's other statuses don't run down for 2 s (bosses 1 s). They keep working." (matches the River/Wading "don't run down" wording in the ui diff; number per Balancing) |
| 6 | Frostfern (draft / review) | Draft: "Its hits give 2 {frost}. At full {frost} a nightmare bursts, hurting those beside it." Review: "...At 10 {frost} a nightmare bursts, hurting it and those beside it." | Draft: "full" = which number; burst nightmare not hit. Review fixes both. Old live text "Pair it with Wardens that Soak." is advice (no-hand-holding) and goes with the rewrite. A Frostfern player who used it to stop nightmares needs the change named once. | Review's version: "Its hits give 2 {frost}. At 10 {frost} a nightmare bursts, hurting it and those beside it." |
| 7 | First Grip (`first_frost.tres`, renamed live) | "The first 5 nightmares of each {drift} to enter an attacking Warden's range gain 1 {held}: they can't move for 1.5 s." | Rename works: "Grip" says "held", no cold word left. Text is clear. Only rule 11 short form missing; fine at 22 words. Draft's "First Chill" would have kept a cold word on a Root card, so First Grip is better. | Optional: "The first 5 nightmares of each {drift} to enter an attacking Warden's range gain 1 {held} for 1.5 s." |
| 8 | Deep Frost (live vs draft 5) | Live: "{family:dewdrop} Wardens' hits deal 45% more damage to nightmares with {held}." Draft: "Frostbursts deal 50% more and Cold Snap lasts 1 s longer." Review: "Frostbursts deal 50% more damage, and statuses pause 1 s longer after one." | Live: a card called Deep **Frost** that is about Root: name and effect disagree (the same trap as First Frost). Review's "after one" is a puzzle (one what?). | If the Root card stays: rename it like First Grip. Frost version: "{frostburst}s deal 50% more damage, and their {cold_snap} lasts 1 s longer." |
| 9 | Undiluted (live, `undiluted.tres`); also NEW corpus line | "No {reactions}. {spored}, {static} and {frostburst} deal double. {damp}: all hits +25%. Full {drowsy}: {asleep} 2 s. {marked} from 5 stacks. {held} ending: 50% again." | Six rules in telegraph style. I can't read "{held} ending: 50% again" or "{marked} from 5 stacks" without the tip. "Full {drowsy}" breaks the noun rule ("at full"). 29+ tokens/words. | "No {reactions}. Instead: {spored}, {static} and {frostburst}s deal double; {damp} gives all hits +25%; full {drowsy} puts it {asleep} for 2 s; {marked} works from 5 stacks; when {held} ends, half the damage it took lands again." (long, but each rule is a sentence; check owner on length) |
| 10 | Tidecaller (draft / review vs live) | Live: "...The ones with 8 {damp} are {frozen}: each gains 1 {held}..." Review: "Every 6 s a great wave gives {damp}, drags nightmares back 1 cell and gives 2 {frost} to those with {frost}." | Review: "gives {damp}" to whom? (live said "everything in range"). "to those with {frost}" is clear. "along the path" dropped: "back 1 cell" could be any direction. | "Every 6 s a great wave gives everything in range {damp}, drags it back 1 cell along the path, and gives 2 {frost} to those that have {frost}." |

## 2. Other flagged strings

| Where | Now | Problem | Rewrite |
|---|---|---|---|
| Hoarfrost (draft) | "Splashing frost. Its hits give 3 {frost}, and it crits more on nightmares with 5 {frost} or more." | Fragment; "crits more": how much? Review fixed both. | Review: "Its hits splash and give 3 {frost}. +20% crit chance against nightmares with 5 {frost} or more." Add (section 37) "only the nightmare hit gains {frost}" if the splash rule stays. |
| Windmill (draft) | "Every second spin gives 1 {frost}." | Reads "every second" = once a second (rule 4). | Review: "Every 2nd spin gives 1 {frost} to each nightmare on its 8 cells." (rule 4 says "2nd", not "other") |
| Windmill old line | "35% more damage per extra path cell around it" | "extra" than what? | (check) "35% more damage for each path cell {touching} it past the first N." |
| Hoar Fog (review) | "...up to 9." | Good that the cap shows; but "why 9 and not 10?" is the next question. | "The fog gives 1 {frost} a second to nightmares inside. Fog alone never makes them burst." |
| Frostbite (draft / review) | "...spends half of it and deals 3% of its max health (bosses 1%)." | Clear, the best of the three. "Max health": of the nightmare, yes since only one is named. Elites 2% missing. | "A {frostburst} on a nightmare with 12 {spored} spends half of it and deals 3% of its max health (elites 2%, bosses 1%)." |
| Long Winter (review) | "Frostbursts can set off one more burst in a row." | "set off" is on the avoid list; "in a row" vague. | "A {frostburst}'s chain can reach one burst further." (or keep the draft without the Rooted clause, as the review asks) |
| Frost tips on Afterglow, Ebb, Gone to Seed, Graft, Never Quite Dry, Overnight, Seeping In, Snare Line, Spent Light (live) | "Never {held} or {frost}." | Fine; reads as "these don't copy Frost". Consistent. | none |
| Copied Frost (draft 1, no text yet) | Gust / Zephyr copies stop at 9 | Invisible; a player sees "stuck at 9". | Whirligig copy cards' tips: "{frost} copies stop 1 short of a burst." (same shape as "{static} stops 1 short of a bolt", already on 4 tips) |
| Frozen Ground (omen) | name only | With Frost meaning "pops", "Frozen" in an Omen name about building rules is a third meaning. Low priority. | (owner call) "Hard Ground" or keep. |
| Afterglow / Spent Light cost | "The {stacks} it gives can't set off a {reaction} for 2 s." | "set off" (avoid list, rule 10). | "The {stacks} it gives can't trigger a {reaction} for 2 s." |
| Brimming (live) | "{reactions} triggered with twice the usual {stacks} hit 2.2 times as hard." | Clear enough; "2.2 times" vs house "×2.2". | "...hit ×2.2 as hard." |
| Clean Strike tip | "A status counts if a form of the family open this run can give it." | "open this run" = unlocked? Lost me. | "A status counts if any form of that family you can grow this run gives it." (check) |
| Conductive Soil | "...also {jumps} for half to up to 4 nightmares with {damp} within 2 cells." | Good. "for half" = half damage? | "...also {jumps} for half its damage to up to 4..." |
| Conductive Soil tip | "These {jumps} don't count for other {jump} cards." | Fine. | none |
| Eddy | "copy half of each of the target's statuses' {stacks} to the nearest other nightmare" | "each of the target's statuses' stacks": three possessives. | "Hits copy half the {stacks} of each status on the target to the nearest other nightmare." |
| Forest Floor tip | "Clearing one of yours gives no Seeds or Dew." | Clear. | none |
| Grandfather Stump tip | "Not damage auras." | Clipped; I'd read "these aren't damage auras". | "Damage auras don't count." |
| Growth Rings | "Plant nothing for a whole {block}: at its {rest}, your top-damage Warden below {rank} III gains a {rank}." | Good. Tip "passes it to the next": next what? | Tip: "...one already at {rank} III passes it to the next-highest damage Warden." |
| Guiding Light I/II | "with {static} nearly {full}" | "nearly full" is defined in the tip; ok. | none |
| Hailfall | "They count as Area, not single target." | "They" = the hits? "single target" never defined. | "These splashes count as area attacks." (check) |
| Hailfall tip | "Its own hit keeps its strength against nightmares that resist Area." | Hard; "its" = the Warden's. | "The Warden's direct hit still deals full damage to nightmares that resist Area." |
| Headlong | "Before any {drift} but a boss {drift}, you may Rush it..." | "any X but a boss X" is a slow parse. | "Rush any {drift} except a boss {drift}: it arrives in a third of its time and pays all its {dew} as it starts." |
| Rush toggle tooltip | "Headlong: the next drift arrives in a third of its time and pays all its Dew as it starts. Not boss drifts." | Good. | none |
| Heartwood's Reach | "Opens clearing, and your next 5 clears are free." | "Opens clearing" = lets you clear? | "You can clear obstacles, and your next 5 clears are free..." (the old start was clearer) |
| Heartwood's Reach tip | "...leave the cell for the next Warden." | Clear enough. | none |
| Loose Stones | "Every 3rd direct hit ... throws 3 stones, each dealing 35% of its damage to a nearby cell." | "its" = the hit's or the Warden's? | "...each dealing 35% of that hit's damage to a nearby cell." |
| Needle Point | "ignores the {dread_shell}" | Clear. | none |
| One Bough | Clear. | none | none |
| Patient Aim tip | "Works for: Wardens that attack less than once a second. Safe." | Fine. | none |
| Resonance tip | "Never repeats or ticks." | Meaningless to me. | (check) "Echoes and status ticks don't add it." |
| Slow Burn | "{spored} ticks deal 30% more on a nightmare that has carried {spored} for 4 s, and {static} bolts once its {static} is 1.5 s old." | Second half needs the first half's verb ("deal 30% more") carried over. | "{spored} ticks deal 30% more damage once a nightmare has had {spored} for 4 s; {static} bolts too, once its {static} is 1.5 s old." |
| Spattered | "Every splash gives its Warden's status to the nightmares it reaches." | Good. Tip long but optional. | none |
| Starlit Aim | "{Heavy} Wardens get +25% crit chance on nightmares with a status nearly {full}." | Clear. | none |
| Sweet Harmony | "(both kin hit one nightmare within 1 s)" | "kin" is new jargon. | "{harmonies} (both Wardens of a Kinship hit one nightmare within 1 s)..." |
| Tangled Lightning | "spending 3 of that nightmare's {static}" | Clear. | none |
| The Tallest Tree | "Wardens {touching} it stop attacking; each gives it one more attack every time it attacks." | First read: "it stops attacking"? The "it/each/it/it" chain is hard. | "Choose a Warden as your Tallest Tree. Wardens {touching} it stop attacking; for each one, the Tallest Tree attacks once more every time it attacks." |
| Unfettered tip | "Without it, a Warden slower than a Calling hit's clock (1, 3 or 4 s) deals only a share." | "clock" + "share" = two undefined words. | "Without it, a Warden slower than its Calling hits (every 1, 3 or 4 s) deals only part of its damage." |
| Wide Petals | "Pulses and clouds are 0.75 cells wider." | Good. | none |
| Gloamwing | "3 stacks of {damp} and {drowsy} together bring it down to walk." | "3 of each" or "3 in all"? (check) | "With 3 {damp} and 3 {drowsy} at once it lands and walks." |
| Puffball | "Its puffs burst over a tile." | "tile" (avoid list: cells). | "Its puffs burst over 1 cell." |
| Rain Lily | "The nightmare it hits takes 4 {damp}, which lasts longer." | "lasts longer" than what? | "...takes N {damp}, which lasts longer than a {warden:dewdrop}'s." |
| Codex "Nearly full" | "Starlit Aim, Called Shot and Guiding Light use it." | Called Shot is RETIRED in this corpus (check). | "Starlit Aim and Guiding Light use it." |
| Codex Harmony strike | "...it takes a bonus hit, the weaker one's damage" | "the weaker one's" = Warden's. | "...it takes a bonus hit equal to the weaker Warden's damage." |
| Codex Splash | Good: "Only the nightmare hit gets the Warden's status." | none | none |
| Splash + status tip | "hits one nightmare and splashes the ones beside it, giving them its status too (Spattered)." | Good. | none |
| Calling tips | "but never the {nightmare:dandelion_seed}" | Fine. | none |
| Clump tip | "Slower Wardens deal less." | Fine. | none |
| Gold path | "4 more hits: +50%." | Telegraph style; "4 more hits" by whom? | "After 4 more hits on it: +50%." |
| Drift strip | "Packs: 4 packs of 7", "Steady: 30 nightmares" | Now readable. | none |
| Price tag (phone) | "Price ↑ 3/5" | Good on phones; desktop "↑ 3/5" still bare. | Desktop too: "Price ↑ 3/5". |
| Tallest Tree button | "...Moves the Tallest Tree here." | Clear. | none |

## 3. Patterns

- **Cold words must mean one thing.** Frost / Frostburst / Cold Snap = the build-and-pop status. Never "Frozen",
  "freeze", "chill", "frost" on Root cards (First Grip did it right; Deep Frost, Frozen, Still Target don't yet).
- **Name the number, not "{full}",** where a burst depends on it (Frost 10, bosses 15). "Full" makes me open a link.
- **Say the surprise.** When a word breaks a genre habit (frost doesn't slow), state it once in its glossary entry.
- **Use the on-screen name**: "{dread_shell}", never "blight coat"; "cells", never "tiles"; "trigger", never "set off".
- **One phrasing for "doesn't expire"**: "don't run down" (River, Wading, Cold Snap), not "pause" / "stop wearing off".
- **Telegraph lists ("X: Y. Z from 5.") fail on a first read** (Undiluted, gold path); write each rule as a sentence.
- **"it / its / they" with two subjects** (Tallest Tree, Loose Stones, Hailfall, review's Frost line): name one again.
- **Invisible caps need a tip**: copied Frost stops 1 short of a burst, same shape as "{static} stops 1 short of a bolt".

## 4. What already works

- The splash rework: "Only the nightmare hit gets the Warden's status" is the clearest rule this round.
- First Grip: rename and text both read at once.
- Frostbite: best of the three Reactions; % of the nightmare's own health is a new, easy idea.
- Drift strip with nouns ("4 packs of 7", "Steady: 30 nightmares") and "Rush" / "Rush on".
- Frost status tips on the copy cards ("Never {held} or {frost}") are short and uniform.
- The player review's rewrites: numbers named, burst nightmare included, "every other spin" spotted.
