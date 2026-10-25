# Veteran seat (Wording Council, round 2026-10-25)

Read: _common.md, seats.md, corpus_resources.txt, corpus_ui_diff.txt, dream_council_review.md 36-37, frost_draft.md,
frost_review_player.md; checked against resource/*.tres, scripts/tower/tower.gd, scripts/run/*, scripts/combat/*,
scripts/enemy/enemy_statuses.gd, scripts/ui/icon_info.gd / codex_data.gd. Read-only.

**Heads-up first:** Frost is NOT "nothing built". The working tree (uncommitted, another chat) already has it:
enemy_statuses.gd:14-66 (FROST cap 15 / bosses 22, FROST_BURST 3.0 / boss 1.5, decay 1 s a stack, quiet Frost stops
2 short = 13, COLD_SNAP 1.5 s / bosses 0.5 s, at most once per 6 s / bosses 10 s), frostfern.tres (1 a hit), hoarfrost.tres
(2 a hit, crit_bonus_vs_frost 0.2), tidecaller.tres frost_if_frosted 2, windmill.tres, icon_info.gd:29 / 246-247,
codex_data.gd:128-130, first_frost.tres display "First Grip", deep_frost.tres retired = true. So there are FOUR number
sets: the draft (cap 10, 5x / 2.5x, Cold Snap 2 s, copies stop at 9), the council (cap 10, 3x / 1.5x, Cold Snap 1.5 s),
the owner's latest ruling (cap 15, 4.5x / 2.25x, chain / copied stop at 13; section 37 last bullet) and the code (cap 15,
3x / 1.5x). **Every Frost text must use tokens ({stacks:cap_frost}, {field:...}), never typed numbers.** The texts in
Job 2 use the draft's numbers as asked, with the token to put in place of each.

---

## Job 1: text changed since 53ca7192, checked against code

### 1. Top 10 problems (ranked)

1. **Eddy** (resource/dream/eddy.tres:9). Now: "...copy half of each of the target's statuses' {stacks} to the nearest
   other nightmare." Code (tower.gd:5597-5630, `_eddy_targets`): candidates are only nightmares on the route cells
   **1 {step} either side** of the target; the nearest of those. No candidate there = no copy (and no cooldown spent).
   "Half" is rounded up, at least 1 (tower.gd:5614). Two readers: one expects a copy to any nightmare across the map.
   Rewrite: "{family:whirligig} Wardens' hits copy half of each of the target's statuses' {stacks} to the nearest
   nightmare 1 {step} either side of it. Each Warden once a second." Tip add: "Half rounds up."
2. **Spattered** (spattered.tres:10). Tip says the once-a-second limit is for "Splashes from Dream cards", implying a
   Warden's own splash has no limit. Code `spatter()` (tower.gd:3771-3790): SPATTERED_WAIT 1 s applies to **every**
   splash, per Warden per nightmare. Also the card never says how many {stacks} a form's own splash gives
   (splash_status_stacks, else status_stacks: Puffball 1, Rain Lily 1, Dewdrop its full stacks). Rewrite desc: "Every
   splash gives its Warden's status to every nightmare it reaches: 1 {stack} from Dream-card splashes. Each nightmare
   once a second per Warden." Tip: "A Warden's own splash gives its form's splash {stacks}. Never from echoes or
   {reactions}. Dream-card {stacks} set off a {reaction} on a nightmare at most once every 2 s." (check own-splash stacks
   wording with Tower Code.)
3. **Tangled Lightning** (tangled_lightning.tres:9, no tip). Now: "{family:firefly_jar} attacks also {jump} to 1
   nightmare carrying {static}...". Code (dream_role_cards.gd:447-470, tower.gd:5562-5576): only an **original direct
   hit**, to the **nearest** Charged nightmare **within 2 cells**, for a **full hit** (TANGLED_SHARE 1.0), never jumps on.
   Range and damage are both missing; "attacks" disagrees with Conductive Soil's "direct hit". Rewrite: "A
   {family:firefly_jar} Warden's direct hit also {jumps} in full to the nearest other nightmare with {static} within 2
   cells, spending 3 of its {static}." Tip: "These {jumps} never {jump} on."
4. **Hailfall** (hailfall.tres:9). "Every attacking Warden's hits splash 40%..." Code (tower.gd:3570-3572): only a
   Warden **without its own splash**, on its **direct hit on its main target** (unique_direct, captured_primary, no combo),
   for 40% of the damage before hit cards. Pulses, clouds, beams, jumps and repeats don't splash (check). "They count as
   Area" - "they" = the Wardens (role tag) or the splashes? Rewrite: "Every Warden's direct hit splashes 40% of its
   damage onto the 3 nearest nightmares within 1 cell. These Wardens count as Area." Tip: "A Warden with its own splash
   keeps it: at least 40%, at least 1 cell, no 3-nearest limit. Pulses, clouds and beams gain nothing. The direct hit
   keeps its strength against nightmares that resist Area." (check the pulse clause.)
5. **Dewdrop Warden** (resource/tower/dewdrop.tres:31). "A small splash that hits a few nightmares and gives them
   {damp}." Section 37 made Dewdrop's splash status-free for the others; the Dream card (dream_dewdrop) was fixed, the
   Warden text was not. The two now contradict. Rewrite: "A small splash. The nightmare it hits gains {damp}; those near
   it take damage. Nightmares with {damp} take 20% more damage from water hits."
6. **Old Mountain Warden** (resource/tower/old_mountain.tres:14). "what it hits gains 1 {held}" vs dream_old_mountain:
   "the one hit gains 1 {held}" (section 37: freeze/hold counts as a status, only the one hit). File is modified in the
   working tree; make sure it lands as: "Every 3 s it drops a boulder that hurts nearby nightmares; the one hit gains 1
   {held} and can't move for 0.5 s. It always crits on nightmares with {held} or {drowsy}."
7. **Grandfather Stump** (grandfather_stump.tres:9). "4% stronger for each Warden" reads as x1.04 of the aura. Code
   (tower.gd:2307-2312): +0.04 **attack speed** added flat per Warden in the aura, total aura capped at +45%; and it does
   not add to Grove Heart's own per-Warden growth (maxf: the larger). Rewrite: "{family:acorn} Wardens' speed auras give
   +4% attack speed for each Warden in them, up to +45% in all." Tip: "Not damage auras. Doesn't add to another per-Warden
   growth: the larger counts. Safe."
8. **Clean Strike** (clean_strike.tres:9-10). Desc says "Hits", tip says "Direct hits only"; desc says statuses that
   "come from the hitting Warden's family", tip (and code dream_hit_cards.gd:237-263) say a status counts if any form of
   the family open this run **can give** it (kind, not source). A Soaked from Dewdrop counts for a Rain Lily even if
   another family's Warden added it. Rewrite: "Direct hits deal 25% more to nightmares whose every status is one the
   hitting Warden's family can give. {final_form} and {ascended}: 50%." Tip: "Needs at least one status. Can give: any
   form of the family open this run. Walls and Sprouts never count."
9. **Family hit cards: "direct hits"** (charged_feathers.tres:9, pollen_beaks, resonance.tres:9/16, needle_point,
   loose_stones). Code tower.gd:3545-3547: the status cards (Charged Feathers, Pollen Beaks, Resonance, Eddy) fire on any
   **status-carrying hit, jumps included** ("jumps count, repeats don't"), never a splash's others; only the every-3rd
   counter (Needle Point, Loose Stones) uses original direct hits. "Direct hits" on the status cards is then wrong for
   any form that jumps. Either the code drops jumps, or the face says "hits (not splashes or repeats)". Decide one, and
   use it on all four. (check with Tower Code)
10. **The Tallest Tree** (the_tallest_tree.tres:9-10; warden_panel tooltip). Hidden rule: only TALLEST_PROCS = 2 of each
   volley's extra attacks fire on-hit cards (dream_hit_cards.gd:65); feeders keep their auras and bonds (section 36).
   A theorycrafter stacking on-hit cards on the Tree will misplay. Tip add: "Only 2 extra attacks a time set off on-hit
   cards. Feeders keep their auras and Kinships." (check the exact proc rule.)

### 2. Other flagged strings

| where | now | problem | rewrite |
|---|---|---|---|
| tower/rain_lily.tres:14 vs dream_rain_lily.tres:10 | Warden: "...takes N {damp}, which lasts longer." Card: no "longer" | Two screens disagree (status_duration 6 vs Soaked 4). | Card: "...a bigger splash; the nightmare hit gains N {damp}, which lasts longer." |
| tower/puffball.tres:13 | "Its puffs burst over a tile." | "tile" is on the avoid list (M5: cells, not tiles); the card says {field:puffball.splash_radius:cells}. | "Its puffs burst over {field:puffball.splash_radius:cells}." |
| tower/tidecaller.tres:12 vs dream_tidecaller.tres:10 | "drags nightmares back 1 cell" vs "pushes it back 1 {step}"; "gives {damp}" vs "gives everything in range {damp}" | Two units and two verbs for one drag; the Warden text drops "everything in range". | Both: "every 6 s a great wave gives everything in range {damp}, drags it back 1 {step}..." |
| loose_stones.tres:9 | "...to a nearby cell." | Old text said random; it still is (tower.gd:5592: 0.5-1.5 cells, random angle, each a half-cell splash). "Throws 3 stones" + "a nearby cell" reads as one cell. | "...throws 3 stones, each dealing 35% of its damage to a random nearby cell." |
| starlit_aim.tres:10 | "A crit uses up half of that status's {stacks}." | Which status when two are nearly full (code: the first found, enemy_statuses.gd:595)? Rooted / Drowsy never spent (comment at :601-603). Frost now counts too (any_full has no Frost skip) - a crit spends half the Frost. | Tip add: "One status pays: never {held} or {drowsy}." (check Frost with Frost builder) |
| guiding_light(_ii).tres:9 | "...{jumps} for half to every nightmare within 1 cell." | Half of what - hit before or after crit / cards? Code: event.base (firefly_lights.gd:1552). No limit (fine, "every" says it). | Keep; tip add "Half of the hit before crits." (check) |
| forest_floor.tres:15 | "Clearing one of yours gives no Seeds or Dew." | Also leaves no cleared cell (no Heartwood's Reach, Tended Forest, fertile cell; commit a8e27b1b). A Reach player will clear one expecting a half-price cell. | "Clearing one of yours gives no Seeds or Dew and leaves no cleared cell." |
| heartwoods_reach.tres:9 | "The first Warden planted on each cleared cell costs half..." | Do cells cleared before the card count? Code: yes (run_state.tended_cells, dream_batch_rules.gd:274). | Tip add: "Cells cleared before you took it count." |
| chain_bloom.tres:9 | "Splashes on a nightmare with 2 or more statuses are ×1.5 as wide." | Matches code (tower.gd:4070). Unit style differs from Wide Petals' "0.75 cells wider" and house "% more". | "Splashes landing on a nightmare with 2 or more statuses are 50% wider." |
| hailfall.tres:10 | "...at least 40% within 1 cell, with no limit." | "no limit" of what (targets). | "...at least 40% and 1 cell, with no 3-nearest limit." |
| warden_header_view.gd (Splash + status tip) | "...splashes the ones beside it, giving them its status too (Spattered)." | "beside" undefined; the splash radius is the rule. | "...splashes the nightmares near it, giving them its status too (Spattered)." |
| afterglow.tres / spent_light.tres cost | "The {stacks} it gives can't set off a {reaction} for 2 s." | 2 s from when? Do they still count after (yes)? | "The {stacks} it gives can't set off a {reaction} for 2 s after they land." |
| eddy.tres:16 | "Never copies {held}, {asleep} or {caught}." | Code skips only HELD; asleep / caught aren't statuses (fine). Gust's spread attack kind is excluded (tower.gd:5539): does Gust Eddy at all? | Tip add, if true: "{warden:gust}'s spread copies its own way, not this." (check) |
| carried_on_the_wind.tres:9 | "{family:whirligig} Wardens copy all..." | Only Wardens that copy (Gust, Zephyr, Samara, Whirlwind, Eddy). Pinwheel / Windmill don't. | "{family:whirligig} copies (Eddy's too) move all of a status's {stacks} instead of half." |
| one_bough.tres:9 | "A Warden {touching} 2 or more Wardens of its own {branch}..." | Code says a grown Warden (dream_role_cards.gd:62); Sprouts can't take it? Tip repeats "Sprouts don't count" twice (desc + tip). | Drop the tip's repeat. |
| trophies.tres | desc "dispels 10 nightmares" | Fine; tip covers Deeply Blighted / bosses 5. OK. | - |
| headlong.tres:9 + drift_panel Rush tooltip | "arrives in a third of its time" | At least 1 s (HEADLONG_MIN_SECONDS). Fine to leave. Tooltip says "the next drift", card "one drift per press" - same. | - |
| slow_burn.tres:9 | "...and {static} bolts once its {static} is 1.5 s old." | Good. "Old" = carried with no gap (tip). OK. | - |
| dream_reaction_cards.gd need text | "Needs %d different Reactions, each triggered %d times (you have %d)" | "you have" N of what (kinds). | "...(you have %d of them)". |
| codex_data.gd (working tree):129 | "Up to 3 bursts in a chain." | Draft: links 1-3 after the first burst = up to 4 bursts deep. Which? | See Job 2 Codex Frostburst. |

### 3. Patterns

- "Direct hit" vs "hit" vs "attack" drift on the same mechanic (Tangled "attacks", Clean Strike "Hits" + tip "Direct
  hits"). Fix: one convention (below), and the face, not the tip, carries it.
- Range words without numbers ("nearest other", "beside", "nearby") while the code has a fixed reach. Fix: always "within
  N cells" or a defined {near}.
- Per-what limits split between face and tip and contradicting (Spattered). Fix: the limit sits in the sentence it limits.
- A Warden text and its Dream unlock card drift apart after reworks (Dewdrop, Old Mountain, Rain Lily, Tidecaller). Fix:
  every rework edits both, one shared sentence.
- "% stronger" for a flat percentage-point add (Grandfather Stump). Fix: "+N% attack speed" for flat adds, "N% more" for
  multipliers.

### 4. What already works

Conductive Soil (reach, cap, half, cost, cooldown all on the card and true to code: tower.gd:2789-2792 / 5547-5566).
"Nearly {full}" defined once, used on Starlit Aim / Guiding Light, Codex entry added. Undiluted's tip answers bosses and
Brimming. Towering spells out its ladder (V +30%, VII +50%). Heartwood's Reach tip says who doesn't use the cell. Headlong
says boss drifts, Auto-drift, next drift's clock. Slow Burn's "Carried" definition. Unfettered names its clocks.

---

## Job 2: Frost texts

Questions a theorycrafter asks, then the recommended text (under 25 words; draft numbers, with the token to use).

**Codex: Frost**
- Does the burst nightmare take the 5x? (Draft: yes; the draft Codex line "damage around it" hides it.)
- "Beside" = up to the 4 nearest within 1 cell. Corner-to-corner? Pick "within 1 cell" (Hailfall's words).
- 5x of what: the strongest Frost applier's potency (not the last stack's Warden, not the hit).
- Is it a hit? Does it crit? Count as Area? Is it a {reaction} (Afterglow, "after 20 Reactions", Reaction pool)? Draft:
  effect damage, not a Reaction, Potency / Seeping scale it, Undiluted doubles it (dream_state.gd:6119).
- Brimming: cap 20, burst x2.2. But draft section 3: a Frost Reaction fires at 10 even with Brimming, so with a ready
  partner the burst comes at 10, not 20. That is a hidden second "full". Must be in the Reaction texts / Codex.
- Decay: 5 s refresh then 1 stack per 0.5 s (code: 1 s). Bosses cap 15 (code 22), half burst; flyers normal.
- Text: "Builds up; at {stacks:cap_frost} [10] a nightmare bursts: 5x to it, 2.5x to up to 4 others within 1 cell, which gain 1 {frost}. Not a {reaction}." (25)

**Codex: Frostburst chain** (separate line; needed, the Frost line can't hold it)
- Chain limit: link 3 is the last, its burst gives no Frost: is that 3 or 4 bursts? x0.75 per link, from what?
- 2 s lock: a burst nightmare ignores burst-given Frost, not Wardens' Frost. 8 bursts a second field cap (queued).
- Do chain bursts set off Frost Reactions? (No.)
- Text: "A burst's {frost} can burst a neighbour, up to 3 more bursts, each 25% weaker. A nightmare that burst takes no burst {frost} for 2 s." (24)

**Codex: Cold Snap**
- Which statuses: all but {held}, sleep, Caught and slows; Frost itself? Ticks keep ticking (Poisoned damage goes on).
- Repeat: draft "a second resets to 2 s"; code: at most once per 6 s (bosses 10 s). Players need the cooldown.
- With Bound and Burning: paused is paused, never adds.
- Text: "After a {frostburst}, the nightmare's other statuses stop wearing off for 2 s (bosses 1 s), not {held}. Once every 6 s." (21) [code: 1.5 s / 0.5 s, 6 s / 10 s; use a {const:} token]

**Frostfern**
- Which number is "full" (Brimming doubles it)? Must the last stack be a Frost Warden's? (Yes: copies stop short.)
- Does its rank raise the burst? (Draft: deep rank = Frost Potency.) Does it still Hold? (No: say nothing that implies a slow.)
- Text: "Its hits give 2 {frost} [{field:frostfern.status_stacks:count}; code 1]. At {full} {frost} a nightmare bursts, hurting it and up to 4 others within 1 cell." (22)

**Hoarfrost**
- Does the splash give Frost? (Only the nightmare hit; with Spattered the others get 1.) "+20% crit chance": points, on
  top of its 5%? "5 Frost or more": counts after a burst empties it (back to 0).
- Text: "Its hits splash; the nightmare hit gains 3 {frost} [code 2]. +20% crit chance against nightmares with 5 {frost} or more." (19)

**Tidecaller**
- Its +2 Frost: a Frost Warden's stack (can finish a burst) or a quiet one (stops at 9 / 13)? Draft table implies it
  can't seed a nightmare with no Frost; silent on finishing. Bosses dragged? 1 cell or 1 {step} (its two texts differ)?
- Text: "Every 6 s a great wave gives everything in range {damp}, drags it back 1 {step}, and gives 2 {frost} to those with {frost}." (23) + tip "Its {frost} can complete a {frostburst}." (or "stops at N", whichever the code does)

**Windmill**
- "Every second spin" reads as each second: use "every other". "Each nightmare there" = its 8 cells. Copied-style
  Frost stops at cap - 1 [9; code 13]: Windmill alone never bursts anything. That must be on the card.
- Text: "...Every other spin gives 1 {frost} to each nightmare on its 8 cells, up to 1 short of {full}." (blade line unchanged; Frost clause 17)

**Hoar Fog (Kinship)**
- 1 Frost a second "x bond share": what is half a Frost? (Every 2 s? a fraction?) Stops at cap - 1; never bursts alone.
- Text: "The fog gives 1 {frost} a second to nightmares inside, up to 1 short of {full}. Weaker bonds give it slower." (20) (check how bond share applies)

**Brittle**
- "Resists nothing": family resistances and shape (Area / single) penalties gone, weak-to stays x1.5, blight coat
  absorbs nothing. Name the coat by its token ({dread_shell}?). Council number differs (coat halved 3 s, bosses 1 s,
  8 s cooldown): pick one before text. Needs "at least 10" {marked}; Brimming never raises it. Spends all Exposed, so
  Exposed's own bonus ends: say it. Order: Brittle wins over Frostbite / Rime on one burst.
- Text: "A {frostburst} on a nightmare with 10 {marked} spends it: for 4 s it has no resistances and its {dread_shell} blocks nothing (bosses 2 s)." (24)

**Frostbite**
- Max or current health? (Max.) Half of what: the oldest half of Poisoned batches. Elites 2%. Owner: outside the Reaction
  pool, so the "x pool, at most 12%" line in the draft is dead; is it still a {reaction} for Reaction cards and counts?
  Cooldown 6 s (council 10 s). Chain bursts never set it off.
- Text: "A {frostburst} on a nightmare with 12 {spored} spends half of them and deals 3% of its max health (bosses 1%). Once every 6 s." (23)

**Third Reaction: Flash Freeze** (owner ruled the name, section 37; not Rime, not Blizzard)
- Does the 2-cell reach raise burst damage targets to 6 at 2.5x? Do the 2 Frost count as burst Frost (lock, 3 links,
  stop short)? Needs 8 Soaked, spends all; Brimming need unchanged.
- Text: "A {frostburst} on a nightmare with 8 {damp} spends it: the burst reaches 2 cells, hits up to 6 and gives them 2 {frost}." (23)

**Deep Frost** (code: retired = true; council retired it from offers; only if it returns)
- Neighbours and chain bursts too? Additive with Brimming's x2.2 (multiplier) or inside the x4 card cap? Bosses' Cold
  Snap 1 s + 1?
- Text: "{frostburst}s deal 50% more damage, chains included, and their {cold_snap} lasts 1 s longer." (14)

**Long Winter** (parked)
- "One link further" = 4 links after the first; the last still gives no Frost; field cap unchanged? Drop the Rooted
  clause (breaks "Frost stops nothing").
- Text: "{frostburst} chains go one burst further: up to 4 after the first." (11)

**First Frost rename**
- Working tree already shows "First Grip" (first_frost.tres), not the draft's "First Chill"; the council said "no cold
  word", so First Grip is right. Text unchanged and fine: "...gain 1 {held}: they can't move for 1.5 s." Tip should add
  "Flyers count." (check) Keep id first_frost.

**Copies stop short.** Gust, Zephyr, Samara, The Whirlwind, Eddy, Spent Light-style spreads: put "Copied {frost} stops 1
short of {full}" in the {frost} glossary tip once, not on every card (and show the dimmed last pip, per the player seat).

---

## Conventions (fixed phrasings, use everywhere)

- **direct hit**: a Warden's own attack on its target (no splash others, jumps, repeats, ticks). **hit**: any damage
  instance from a Warden. **attack**: never in rules text for a damage condition.
- **within N cells**: a radius. **{touching}**: the 8 around. **up to the N nearest within X cells**: a capped spread.
  Never "beside", "nearby", "around" as a rule unless followed by a number.
- **+N% crit chance**, **+N% attack speed**: flat adds. **N% more damage**: a multiplier. "x1.5 as wide" -> "50% wider".
- **for N s**: a duration. **every N s**: a clock. **once every N s per nightmare / per Warden**: a cooldown, always
  saying per what, on the face.
- **gains** (the nightmare gets stacks) / **gives** (the Warden or card adds them) / **spends** (a card or Reaction takes
  stacks as a price) / **loses** (the nightmare's stacks go as a side effect).
- **Not a {reaction}** on any status payoff (Charged bolt, Frostburst), so Reaction cards' reach is clear.
- **Bosses: X** as the last clause; elites only when they differ.
- **stops 1 short of {full}** (or "stops at {stacks:...}") for any capped copy.
- Numbers in Frost and status texts as tokens, never typed.
