# Wording Council round 2026-10-25: plain_english seat
Read: briefs/_common.md, seats.md (plain_english), corpus_resources.txt (NEW lines only), corpus_ui_diff.txt ("+"
lines), frost_draft.md §1 + §4-5, frost_review_player.md §6, scripts/ui/icon_info.gd (STATUSES, TERMS), codex_data.gd
(Frost / Dread shell / Splash / Full rows). Avoid-list: documentation/wording_council/plain_english.md §3 + round2,
round3, gap, roguelite additions. Read-only.

Flagged: **71 strings** (10 top, 61 in the table) + **14 Frost items** (names and texts). Localisation risks: 13.

---

## 1. Top 10 problems

### 1. "the one hit" (new splash rule, 5 places + Codex)
- Where: dream_dewdrop, dream_old_mountain, dream_puffball ("only the one hit gains {damp}", "the one hit gains 1
  {held}"), Codex "Splash" (codex_data.gd:136 "near the one hit"); dream_hoarfrost / dream_rain_lily use "the nightmare
  hit gains".
- Problem: a second-language reader parses "the one hit" as "the single hit" (noun "hit") and "the nightmare hit" as a
  compound noun ("a nightmare-hit"). The sentence that teaches the new splash rule is the one most likely misread.
- Rewrite (one phrasing everywhere): "**the nightmare it hits** gains …". Dewdrop: "Its splash hurts nightmares near the
  nightmare it hits; only that nightmare gains {damp}." Codex Splash: "A splash hurts the nightmares near the one a
  Warden hits. Only the nightmare it hits gets the Warden's status."

### 2. Brittle (Frost): the on-screen word is "dread shell", not "shell" or "blight coat"
- Draft: "for 4 s it resists nothing (bosses 2 s)"; player seat: "no resistances or blight coat".
- Problem: "blight coat" is a code comment word only (enemy.gd:209, puddles.gd:2396); the player sees {dread_shell}
  ("Dread shell" in icon_info.gd:244, Codex codex_data.gd:110). Bare "shell" is ambiguous (Shellbound nightmare, any
  shell) and "the shell is gone" reads as permanent, which collides with the Codex "until it cracks for good".
  "Resists nothing" is vague: the game never shows a "resistance" stat, only resisted damage types.
- Rewrite: "A {frostburst} on a nightmare with 10 {marked} uses it all up: for 4 s (bosses 2 s) no damage type is
  resisted and its {dread_shell} absorbs nothing." (24 words; "attack shapes" too if the owner wants it said: check)

### 3. Frost names a second-language reader will misread
- **Rime**: rare word, sounds exactly like "rhyme" in a game with a Song family (Bellflower, Refrain, Vespers). Use
  **Blizzard** (known worldwide from games and weather; "bigger, wider cold" = the effect). Not "Flash Freeze": "freeze"
  promises a stop, and Frost stops nothing.
- **Hoarfrost / Hoar Fog**: "hoar" is archaic and is a homophone of an English slur; learners and streamers will
  stumble on it. Owner call (both names already ship): "Rimefrost" is no better; options: Hoarfrost -> "Frostspire"
  (check with Tower Discussion), Hoar Fog -> **"Freezing Fog"** (a real weather term, plain).
- **Cold Snap**: weather idiom ("snap" = break / bite / photo / quick). Keep it as a Codex term only (player seat
  agrees); card and Warden texts say "its other statuses stop running down for 2 s". Don't rename to "Chill" /
  "Chilled": in other games that means slowed.
- **Frostbite**: keep: common word, and its real meaning (cold hurts the body) matches "% of max health".
- **Brittle**: keep (an adjective state, B2 but transparent once linked); note it echoes the Omen "Brittle Night"
  (more leaves lost), a different meaning of "brittle". Fine if Brittle is always the {brittle} link.
- **First Frost -> First Chill vs First Grip**: choose **First Grip**. The card gives Root ({held}); "grip" says hold,
  "chill" keeps a cold word on a non-Frost card (the thing the rename is for) and is slang for "relax".
- **Frostburst**: fine as a compound, but only if it is always the {frostburst} token. "burst" is already plain text on
  ~10 cards (Puffball, Fairy Ring, Last Breath, Mother Spider, Seed Storm, Starburst): see pattern P2.

### 4. Frozen ({frozen}) now contradicts Frost
- Where: icon_info.gd:27 `&"frozen": ["Frozen", "Frost stops it for a moment."]`; Codex codex_data.gd:127 ("Frost's
  {held}"), :306 Hoar Fog; still_target(_ii), dewdrop_ascension, dream_keywords.gd.
- Problem: the new rule is "Frost stops nothing", but the glossary says "Frost stops it". Two cold words (Frost,
  Frozen) for two unrelated mechanics.
- Rewrite: retire {frozen} with the Frost build; where Old Mountain / World Root / First Grip hold a nightmare, say
  {held}. Until then: "Frozen: a Dewdrop Warden's {held}: the nightmare can't move while it lasts. Not {frost}."

### 5. Frost texts: "beside", "pause", "around", and "10" vs {full}
- Where: icon_info.gd:29 (already coded): "At {full} it bursts in a {frostburst}: damage around it, 1 Frost to the
  nightmares beside it, and a {cold_snap}."; draft Codex "its statuses pause 2 s"; player seat "up to 4 beside it",
  "At 10 {frost}".
- Problems: "beside" / "around" are unlinked distance words (avoid-list: use the number or {touching}); "pause" is the
  game's Pause button; a verbless noun list hides that the bursting nightmare is hurt too; "10" is wrong under
  Brimming (cap 20), so {full} is right and the number wrong (check: Brimming doubles Frost's cap per draft §1).
- Rewrite (Frost glossary): "Builds up on a nightmare. At {full}, a {frostburst}: the nightmare takes damage, up to 4
  others within 1 cell take less and gain 1 {frost}, then a {cold_snap}."

### 6. Headlong + Rush tooltip
- Where: headlong.tres; drift_panel.gd:106 tooltip; drift_panel.gd:535 "Rush on".
- Now: "Before any {drift} but a boss {drift}, you may Rush it: it arrives in a third of its time and pays all its
  {dew} as it starts." Tip: "… a {rest}'s Start use it too. A leak loses no {dew}. … Works for: every family; area hits
  and {jumps} gain most."
- Problems: "any X but Y" (= except) reads as a contrast; "pays" (money idiom, avoid-list) – who pays whom?; "leak"
  (avoid-list); "a {rest}'s Start" possessive on a button; "gain most" is strategy advice (no hand-holding). "Rush on"
  on the button reads as the phrasal verb "rush on" (= hurry onward).
- Rewrite: "Before any {drift} except a boss {drift}, you may Rush it: it arrives 3 times sooner and gives all its
  {dew} when it starts." Tip: "Rush is on the {drift} bar, one {drift} per press. Auto-drift and the Start button at a
  {rest} use it too. A nightmare reaching the Heartwood loses you no {dew}. The next {drift} has its normal time."
  Button: "Rush: on" / "Rush: off". Tooltip: "Headlong: the next drift arrives 3 times sooner and gives all its Dew when
  it starts. Not boss drifts." ("3 times sooner" = a third of its time: check the owner prefers it.)

### 7. Heartwood's Reach: "Opens clearing"
- Now: "Opens clearing, and your next 5 clears are free." Tip: "… pay full price and leave the cell for the next Warden."
- Problem: "clearing" as a noun is a forest glade, so "Opens clearing" reads as "opens a glade". "leave" (verb) is on
  the avoid-list (leaves = lives).
- Rewrite: "You can now clear obstacles, and your next 5 clears are free. The first Warden planted on each cleared cell
  costs half and arrives at {rank} I." Tip: "… pay full price, and the cell keeps its bonus for the next Warden."

### 8. Hailfall: three unclear pronouns
- Now: "Every attacking Warden's hits splash 40% of their damage onto nightmares within 1 cell. They count as Area, not
  single target." Tip: "Up to the 3 nearest. A Warden with its own splash keeps it, at least 40% within 1 cell, with no
  limit. Its own hit keeps its strength against nightmares that resist Area."
- Problem: "They" = hits, nightmares or Wardens; "Its own hit keeps its strength" has two "its"; the tip's second
  sentence has no verb for its middle part.
- Rewrite: "Every attacking Warden's hits splash 40% of their damage onto up to 3 nightmares within 1 cell. These splash
  hits count as Area, not single target." Tip: "A Warden with its own splash keeps that splash, with no limit on
  nightmares, and it is at least 40% within 1 cell. Against nightmares that resist Area, the first hit still deals full
  damage." (check)

### 9. Undiluted is still telegraphic
- Now: "No {reactions}. {spored} and {static} deal double. {damp}: all hits +25%. Full {drowsy}: {asleep} 2 s. {marked}
  from 5 stacks. {held} ending: 50% again."
- Problem: five rules with no verbs; "Full" is plain text, not {full}; "50% again" is an idiom. A translator can't
  rebuild these fragments.
- Rewrite: "No {reactions}. {spored} and {static} deal double damage. Nightmares with {damp} take 25% more from all
  hits. At {full} {drowsy}, a nightmare falls {asleep} for 2 s. {marked} works from 5 stacks. When {held} ends, half the
  damage taken while {held} hits again." (tip's "50% again:" line then goes.)

### 10. "set off" and "the rest" came back
- Where: afterglow, spent_light cost ("can't set off a {reaction} for 2 s"), spattered tip ("Their {stacks} set off a
  {reaction} …"), trophies ("for the rest of this run"); draft Long Winter ("set off one more burst in a row").
- Rewrite: "The {stacks} it gives can't trigger a {reaction} for 2 s after they land." Spattered: "… These {stacks} can
  trigger a {reaction} on a nightmare at most once every 2 s." Trophies: "… until this run ends, up to +40%."

---

## 2. Every other flagged string

| Where | Now | Problem | Rewrite |
|---|---|---|---|
| afterroot tip | "… Works for: Wardens that add {held}, with a second Warden. Safe." | "Safe." tag idiom (round 1-3, owner call open) | "… Works on its own." or cut |
| chain_bloom | "Splashes on a nightmare with 2 or more statuses are ×1.5 as wide." | "×1.5 as wide" (avoid "half again as wide") | "… are 50% wider." |
| charged_feathers / pollen_beaks / resonance | "Each Warden once a second per nightmare." | no verb (roguelite rule) | "Each Warden can do this once a second on each nightmare." |
| charged_feathers / pollen_beaks tips | "Works for: X Wardens with Y Wardens. Safe." | tag idiom | cut "Safe." |
| clean_strike | "Hits deal 25% more to nightmares whose statuses all come from …" | "more" with no noun | "Hits deal 25% more damage to …" |
| clean_strike tip | "Needs at least one status. A status counts if a form of the family open this run can give it." | no subject; "open this run" garden path | "The nightmare needs at least one status. A status counts if any form of that family you can plant this run gives it." (check) |
| conductive_soil | "… also {jumps} for half to up to 4 nightmares …" | "for half" ellipsis | "… also {jumps}, at half damage, to up to 4 nightmares with {damp} within 2 cells." |
| conductive_soil tip | "Each Warden once a second." | no verb | "Each Warden can do this once a second." |
| dream_hoarfrost | "… at N {stacks} it is {frozen} … More crits on nightmares with {held}." | {frozen} vs Frost (top 4); "crits" (round 2: critical hits) | rewrite with the Frost build |
| dream_old_mountain | "drops a boulder that hurts nearby nightmares; the one hit gains 1 {held}" | "the one hit" (top 1); "boulder" now also the Mossy Boulder you place (Forest Floor) | "drops a great stone that hurts nearby nightmares; the nightmare it hits gains 1 {held} …" (check name) |
| dream_puffball | "its puff bursts over N cells, hurting every nightmare there; the one hit gains …" | "the one hit"; plain "bursts" next to {frostburst} | "its puff lands and spreads over N cells, hurting every nightmare there; the nightmare it hits gains …" |
| dream_rain_lily | "a bigger splash; the nightmare hit gains N {damp}" | compound-noun misread | "… the nightmare it hits gains N {damp}." |
| eddy | "… copy half of each of the target's statuses' {stacks} to the nearest other nightmare." | possessive chain "target's statuses' stacks" | "Each hit from a {family:whirligig} Warden copies half the {stacks} of each status on its target to the nearest other nightmare. Each Warden can do this once a second." |
| forest_floor tip | "Withered Trees and Mossy Boulders count, yours too. Clearing one of yours gives no Seeds or Dew." | "yours too" ellipsis | "… count, also the ones you place. Clearing a boulder you placed gives no Seeds or Dew." |
| grandfather_stump | "… 4% stronger for each Warden in them, up to +45% faster in all." | "in all" (avoid); stronger/faster mixed | "… give 4% more attack speed for each Warden inside them, up to +45% in total." |
| grandfather_stump tip | "Not damage auras. Safe." | no verb + tag | "Damage auras don't get this." |
| growth_rings tip | "one already at {rank} III passes it to the next … The {rank} waits until you Nurture." | "passes" (pass on); rank personified | "If it is already at {rank} III, the next Warden gets it. You get the {rank} the next time you Nurture." (check) |
| guiding_light / _ii | "… nearly {full} also {jumps} for half to every nightmare within 1 cell." | "for half" | "… also {jumps}, at half damage, to every nightmare within 1 cell." |
| guiding_light / starlit_aim tips; Codex "Nearly full" (codex_data.gd:142) | "at least 3/4 of its usual most" | "most" as a noun | "at least 3/4 of its usual maximum" |
| Codex "Full" (codex_data.gd:141) | "A status at its most stacks: each status has its own most …" | "its most stacks" ungrammatical for learners | "A status at its maximum stacks: each status has its own maximum, and Brimming doubles it." |
| hairpin_winds tip | "… A bet: needs the path folded around them." | "A bet:" tag; "around" | "Risky: needs the path folded close to them." or cut |
| loose_stones | "… throws 3 stones, each dealing 35% of its damage to a nearby cell." | "its" = hit or Warden | "… each dealing 35% of that hit's damage to a nearby cell." |
| slow_burn | "{spored} ticks deal 30% more on a nightmare that has carried {spored} for 4 s, and {static} bolts once its {static} is 1.5 s old." | "carried" (new verb); second clause has no verb | "{spored} ticks deal 30% more damage once a nightmare has had {spored} for 4 s without a gap. {static} bolts deal 30% more once its {static} is 1.5 s old." |
| slow_burn tip | "Carried: on with no gap. A new batch that lands before the last one ends keeps the count." | fragment; "batch" undefined on screen | "New stacks that land before the old ones run out keep the count going." |
| spattered tip | "Splashes from Dream cards: each nightmare at most once a second per Warden, never from echoes …" | fragment | "A Dream card's splash gives the status to each nightmare at most once a second per Warden, and never from echoes or {reactions}." |
| sweet_harmony | "{harmonies} (both kin hit one nightmare within 1 s) deal 50% more and can come every 1.5 s, not 2 s." | "kin" undefined; "more" no noun; "come" | "{harmonies} (both Wardens of a {kinship} hit one nightmare within 1 s) deal 50% more damage and can happen every 1.5 s, not 2 s." |
| tangled_lightning | "… to 1 nightmare carrying {static}, spending 3 of that nightmare's {static}." | "carrying"; "spending" vs "uses up" elsewhere | "… to 1 nightmare with {static}, using up 3 of its {static}." |
| the_tallest_tree tip | "Sprouts and walls don't count; up to 8. Only Wardens that hit can be it." | "be it" (tag-game idiom); fragment | "Sprouts and walls don't count; at most 8 Wardens. Only a Warden that attacks can be the Tallest Tree." |
| rolling_thunder / _ii cost | "Nightmares its {arcs} strike lose their {damp}." | "its" (card? Warden?); strike/hit | "Nightmares hit by these {arcs} lose their {damp}." |
| resonance tip | "Never repeats or ticks." | no subject; what repeats? | "Repeat hits and ticks don't add it." (check) |
| unfettered tip | "… slower than a Calling hit's clock (1, 3 or 4 s) deals only a share … Bosses still take their share." | "clock", "share" (round 3 pattern); "take" | "Without it, a Warden that attacks less often than its Calling hits (every 1, 3 or 4 s) deals only part of its damage. … Bosses still take less." |
| gloamwing trait | "… together bring it down to walk." | phrasal "bring down" | "… together make it land and walk." |
| puffball (tower) | "Its puffs burst over a tile. The nightmare it hits takes N {spored}; the others nearby take its damage." | "tile" (M5: cells); "takes" a status; "its damage" | "Its puffs spread over 1 cell (check). The nightmare it hits gains N {spored}; other nightmares there take the hit's damage." |
| rain_lily (tower) | "The nightmare it hits takes N {damp}, which lasts longer." | "takes"; longer than what | "The nightmare it hits gains N {damp}, and that {damp} lasts longer than a Dewdrop's." (check) |
| calling_paths.gd:66 (clump tip) | "… each once a second. A nightmare walking onto a clump uses 1 {mushroom}. … No status." | fragments; "uses" = uses up | "… each Warden once a second. Each nightmare that walks onto a clump uses up 1 {mushroom}. … These hits give no status." |
| calling_paths.gd:78 | "… never used up, so its {free_hits} keep coming." | "its" = throne's or Warden's | "… so the Warden's {free_hits} there keep coming." |
| calling_paths.gd:102 | "Shared Caps' Warden at each {mushroom} wears a cap" | possessive chain (roguelite pattern, still here) | "With Shared Caps, the Warden at each {mushroom} wears a cap: …" |
| calling_paths.gd (Shared Caps tip) | "One Warden a {mushroom}. A cap lasts 8 s after it stops being picked. Doesn't add with Undiluted: the larger counts." | "a" = per; "picked"; no subject | "One Warden for each {mushroom}. A cap lasts 8 s after its Warden stops using that {mushroom} (check). With Undiluted, only the larger bonus counts." |
| calling_paths.gd:159 | "When a streak of 4+ glows ends, each of its Fireflies gives it a {flare}" | bare "Firefly" (round 2 rule 5); "it" = nightmare? | "When a streak of 4+ glows on a nightmare ends, each {family:firefly_jar} Warden in it gives that nightmare a {flare}: …" (check) |
| calling_paths.gd:187 | "A Firefly's hit on gold path saves a crit … 4 more hits: +50%." | "saves" (rescues/stores); no article; fragment | "When a {family:firefly_jar} Warden hits on the gold path, it stores a crit … After 4 more direct hits, the crit deals +50%." |
| calling_paths.gd:187 tip | "Until someone has one, last block's holder keeps it." | "one" / "it" unclear | "Until a Warden makes a gold dispel this block, last block's top Warden keeps the crit." |
| calling_paths.gd:190 | "Path inside 3+ Fireflies' glows burns white. There, every 2nd direct hit crits from a Warden that has made 50 gold dispels." | "burns" (Ignite?); word order | "Path inside the glows of 3+ {family:firefly_jar} Wardens turns white. There, every 2nd direct hit from a Warden with 50 gold dispels is a crit." |
| calling_paths.gd:190 tip | "… while it stands … A waiting crit is used first." | "stands" idiom; "waiting" vs "saves" | "… while it is planted … A stored crit is used first." |
| calling_paths.gd:194 | "there, every 3rd direct hit crits from a Warden that has made 50 gold dispels" | word order | "there, every 3rd direct hit from a Warden with 50 gold dispels is a crit." |
| calling_paths.gd:213 | "… at half damage; in full from a Warden given light by Lantern Wake." | "in full" ellipsis | "… at half damage, or full damage from a Warden lit by Lantern Wake." |
| calling_paths.gd (Wading tip) | "{static}: 2 s. Never {drowsy} or {held}." | fragments | "{static} stays for only 2 s. {drowsy} and {held} are never kept." |
| calling_paths.gd:441 | "Each nightmare once per stretch of {water}, on top of the mouth's." | "on top" (round 2 avoid) | "… in addition to River Mouth's bonus." |
| boulder_placement.gd:87 | "Forest Floor: click open ground to place %s (Esc to look round first)." | "click" on phones (touch rule); "look round" phrasal | "Forest Floor: choose open ground for %s (Esc: look at the map first)." (phones: no Esc line) |
| boulder_placement.gd:155 | "A boulder there would close the way to the Heartwood." | "close the way" idiom | "With a boulder there, nightmares could not reach the Heartwood." |
| dream_hit_cards.gd:487/489 | "The Tallest Tree: fed by %d" / "Feeding the Tallest Tree: doesn't attack" | "fed" metaphor (no card word) | "The Tallest Tree: %d Wardens give it attacks" / "Gives attacks to the Tallest Tree: doesn't attack" |
| codex_data.gd:22 (Drift shape) | "… a handful led by Deeply Blighted. Shapes are rolled with the map. A pack that gets through takes at most N leaves in all." | "handful", "rolled", "gets through", "takes leaves", "in all": 5 avoid-list words | "… a few nightmares led by Deeply Blighted. Each map picks its shapes when it is made. The nightmares of one pack that reach the Heartwood cost at most N leaves in total." |
| codex_data.gd:68 (Harmony strike) | "… it takes a bonus hit, the weaker one's damage (at most every 2 s per pair)." | "the weaker one's" | "… the nightmare takes a bonus hit equal to the weaker Warden's damage (at most once every 2 s for each pair)." |
| codex_data.gd:110 (Dread shell, old) | "… until it cracks for good." | "for good" (avoid) | "… until it breaks permanently." |
| codex_data.gd:130 (Cold Snap) | "… stop wearing off for 1.5 s (bosses 0.5 s)." | "wear off" (round 3 avoid); 1.5/0.5 vs draft 2/1 s (check) | "… stop running down for N s (bosses N s)." |
| codex_data.gd:129 (Frostburst) | "… up to 4 nightmares beside it take less and gain 1 {frost}." | "beside" | "… up to 4 nightmares within 1 cell take less and gain 1 {frost}." |
| drift_panel.gd:516 | "Closing drift (drift %d): clear it clean for a Rare Dream" | "clear it clean" idiom | "Closing drift (drift %d): lose no leaves for a Rare Dream" (check the condition) |
| warden_header_view.gd:530 | "Splash + status: hits one nightmare and splashes the ones beside it, giving them its status too (Spattered)." | "beside"; "the ones" | "Splash + status: hits one nightmare and splashes the nightmares near it; they get its status too (Spattered)." |
| ui_style.gd:103 | "Large (roomier)" | rare comparative | "Large (more space)" |
| drift_shapes.gd NAMES | "Single file" | round 3 asked "In a line"; idiom | "In a line" (owner kept? check) |

### Frost texts (draft §4-5, player seat §6)
| Text | Draft / seat | Problem | Rewrite |
|---|---|---|---|
| Codex Cold Snap | "… stop wearing off for 2 s (bosses 1 s)." | "wear off" | "After a {frostburst}, the nightmare's other statuses stop running down for 2 s (bosses 1 s)." |
| Frostfern | seat: "At 10 {frost} a nightmare bursts, hurting it and those beside it." | "10" wrong with Brimming; "beside" | "Its hits give 2 {frost}. At {full} {frost}, a {frostburst} hurts the nightmare and up to 4 others within 1 cell." |
| Hoarfrost | seat: "Its hits splash and give 3 {frost}. +20% crit chance against …" | fine; keep the seat's version | — |
| Tidecaller | "… and adds/gives 2 {frost} to those with {frost}." | "those" OK; fine | "… and gives 2 {frost} to nightmares that already have {frost}." |
| Windmill | draft "Every second spin"; seat "Every other spin" | both on the avoid-list (time / "all the others") | "Every 2nd spin gives 1 {frost} to each nightmare on the 8 cells {touching} it." (check: 8 cells) |
| Windmill (blades) | "35% more damage per extra path cell around it" | "around"; "extra" undefined | "35% more damage for each path cell {touching} it after the first N" (check) |
| Hoar Fog | "The fog gives 1 {frost} a second to nightmares inside, up to 9." | "inside" what; 9 wrong with Brimming | "The fog gives 1 {frost} a second to nightmares in it, up to 1 below {full}." |
| Frostbite | "spends half of it and deals 3% of its max health" | two "it"; "spends" | "A {frostburst} on a nightmare with 12 {spored} uses up half its {spored}; the nightmare takes 3% of its max health (bosses 1%)." |
| Rime -> Blizzard | "… spends it: the burst reaches 2 cells, hits up to 6, gives 2 {frost}." | "spends"; "reaches" | "A {frostburst} on a nightmare with 8 {damp} uses it all up: the burst spreads 2 cells, hits up to 6 and gives each 2 {frost}." |
| Deep Frost | seat: "… statuses pause 1 s longer after one." | "pause"; "one" | "{frostburst}s deal 50% more damage, and their {cold_snap} lasts 1 s longer." |
| Long Winter | seat: "Frostbursts can set off one more burst in a row." | "set off", "in a row" | "A chain of {frostburst}s can go 1 burst further (4 in total)." (Rooted clause: drop, as the seat says) |

---

## 3. Patterns and rules
- **P1 "the one hit" / "the nightmare hit".** Always "the nightmare it hits" (top 1).
- **P2 "burst" means 6 things.** Frost makes it a term: keep plain "burst(s)" out of new Frost text and say "spreads",
  "lands", "breaks into" on non-Frost cards when they are next touched; Frost text uses {frostburst}.
- **P3 Distance words.** beside / around / nearby / inside without a number: "within N cells" or {touching}.
- **P4 "pause"** belongs to the Pause menu. Statuses "stop running down".
- **P5 Fixed numbers for caps Brimming doubles.** "At 10", "up to 9": use {full} / "1 below {full}".
- **P6 Three verbs for one act**: spends / uses up / loses (stacks). Use "uses up" (Starlit Aim's) everywhere.
- **P7 Rate-limit fragments** ("Each Warden once a second per nightmare"): add "can do this".
- **P8 Possessive chains** still appear (Shared Caps', target's statuses', a {rest}'s Start): use "with" / "of".
- **P9 "for half", "in full", "50% again"**: say "at half damage", "at full damage".
- **P10 "Safe." / "A bet:" / "gain most"**: tags and advice; owner call still open, cut on the next touch.

### Words to avoid in rules text (additions this round)
| Avoid | Use instead |
|---|---|
| the one hit, the nightmare hit | the nightmare it hits |
| beside (Frost) | within 1 cell |
| pause (statuses) | stop running down |
| Rime | Blizzard |
| Hoar Fog | Freezing Fog (owner call) |
| blight coat, bare "shell" | {dread_shell} |
| Opens (a mechanic) | You can now … |
| any X but Y | any X except Y |
| be it (Tallest Tree) | be the Tallest Tree |
| ×1.5 as wide | 50% wider |
| most (noun) | maximum |
| fed / feeding (Tallest Tree) | gives it attacks |
| close the way, look round, clear it clean, roomier | nightmares could not reach, look at the map, lose no leaves, more space |
| Rush on (button state) | Rush: on |
| carried (a status) | had … without a gap |

---

## 4. Localisation risks (code-built strings in this diff)
1. boulder_placement.gd:87-88: "place %s" with an English-built "a Mossy Boulder" / "%d Mossy Boulders": plural and
   article chosen in code; give the translator two whole sentences.
2. shape_rows.gd:79: "Packs: %d packs of %d, %d s apart": plural "packs" fixed (1 pack); word order fixed.
3. shape_rows.gd:81: "Single file: %d nightmares, %.1f s apart": plural + decimal point (comma in most of Europe).
4. shape_rows.gd:83-84: "%d nightmares, %d Deeply Blighted", "%s: %d nightmares": plurals; the shape name glued in by %s.
5. dream_reaction_cards.gd:200: "Needs %d different Reactions, each triggered %d times (you have %d)": "1 times";
   three numbers in one fixed order.
6. dream_reaction_cards.gd:203: "Needs %d Reactions triggered this run": "1 Reactions".
7. dream_hit_cards.gd:487: "fed by %d": count with no noun; plural.
8. drift_panel.gd:265 + 365-367: phone_short() edits the built text with English substrings ("Start boss drift " ->
   "Boss drift ", "Call drift … early, ") – breaks silently once translated; keep separate phone strings.
9. drift_panel.gd:516: FINALE_TEXT "%d" inside a sentence: fine with a positional placeholder; note it.
10. warden_header_view.gd:129, 131: chips are filtered by their *display* label (`!= "Area"`, `== shape_word`): a
    translated label breaks the de-duplication; compare role ids, not words.
11. warden_header_view.gd:552 (diff line): "Splash" swapped in for the Area role tag by string: same as 10.
12. hud.gd:2029: "Price ↑ %d/%d" vs "↑ %d/%d": two formats for one meaning; the arrow carries the word on PC.
13. warden_panel.gd (Tallest Tree tooltip): two sentences joined with "+" and a conditional " Moves the Tallest Tree
    here.": OK as whole sentences; keep both in one translatable string per case.
(perf_overlay.gd "%.1f ms", "%d FPS": decimal separator only; developer-facing, low.)

---

## 5. What already works
- Forest Floor's "Now: place 2 Mossy Boulders on open ground." and the boulder rules (boulder_placement.gd:147): plain.
- {family:…} replaced bare Warden names on every reworked card (round 2 rule 5 applied).
- Clump / throne rows now use "used up" and "keep coming" (round 3 table applied); {water} is "stretch of {water}".
- "Nearly {full}" defined once with a number (3/4) and linked in Codex.
- Frostbite as a name; Frost as a plain noun; "Frost stops nothing" is one rule a learner can hold.
- Coming strip counts now carry nouns ("Steady: 30 nightmares").
