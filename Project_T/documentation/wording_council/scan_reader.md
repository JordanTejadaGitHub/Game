# Wording Council: Scan Reader (mid-fight, small screen)

Seat: the player glances at a card offer or tooltip mid-run, often on a phone. Questions asked of every
text: is the effect in the first few words? Does the condition sit in a natural place? Is it short
enough for a card face (cards over ~25 words, tooltips over ~40, buttons over ~4)? Are there nested
clauses, semicolons, parentheses or "unless / except" chains that force a re-read? Can the numbers be
found at a glance? Do sibling cards share a shape?

Corpus: `corpus_resources.txt` and `corpus_ui.txt` (2026-10-22). Word counts: a `{token}` (nested ones
too) counts as one word; `%d` / `%s` count as one word. Judged as the text is now. No numbers invented:
every rewrite keeps the original numbers and tokens; where a rewrite drops words, the "Note" column
says where that information already lives (usually the token's own tooltip).

Shorthand used in the rewrites, to keep the tables readable:
- **[P]** = the unchanged evolution prefix, e.g. `{warden:frostfern}s can now {grow} into {warden:hoarfrost}s ({dew:{grow_cost:hoarfrost}})`.
  For ascensions, [P] = `Any {family:x}-{family} final form can ascend into {warden:y} ({dew:{grow_cost:y}}, one per run)`.
- **{f:name}** = the existing `{field:<warden>.name:...}` / `{pct:<warden>.name}` token of that card, unchanged.
- " / " inside a rewrite = a line break on the card (recipe or limiter line).

---

## Headline findings

1. **Dream cards are mostly fine; evolution-unlock cards and Reactions are not.** 2 of 261 regular Dream
   cards exceed 25 words, but 35 of 117 evolution-unlock cards do, and 8 of 10 Reactions (average 37
   words). Warden descriptions: 34 of 122 over 25.
2. **Evolution cards spend their first ~8 words on the prefix** (`X can now grow into Y (cost):`). The
   effect starts at word 9. Recommendation for Roguelite Code / UI: render "Frostfern → Hoarfrost · cost"
   as a small header row on the card and keep only the effect clause as body text. That alone puts 25
   of the 35 long evolution cards under 25 words. (If the prefix must stay as text, the rewrites below
   still cut each one.)
3. **Five repeated phrases make up much of the length.** Replacing them with one fixed short form (and
   leaving the explanation in the token tooltip) saves 4–15 words wherever they appear:
   - "gains 1 {held} and can't move for X" (14 places) → **"1 {held} for X"**. The Root tooltip
     already says a Rooted nightmare can't move.
   - "the nightmare furthest along (the path)" (9 places) → **"the leader"** (Snugroot's role line
     already says "Roots the leaders"; add "Leader" to the glossary).
   - "Doesn't add {held}; never past {full}; {static} stops 1 short of a bolt." (8 tips) → one Dream
     keyword with its own tooltip (e.g. "Top-up rules"), or at least a fixed short form: "Never {held} or
     past {full}; {static} stops 1 short."
   - "At most 3 s of that Firefly's damage" (8 Firefly jump cards) → a keyword, or the fixed short form
     "Capped at 3 s of Firefly damage."
   - "Works for: … Safe." / "A bet: needs …" tails on 150+ tips: these work better as a badge
     (Safe / A bet) than as words; the "Works for" clause is the first thing to cut when a tip is long.
4. **Order:** Reactions put numbers *after* the recipe (Thunderclap's "×12 damage, ×6 per arc" is in
   its last sentence; Drown's slow is after "Needs"). Rule: effect and numbers first, then
   "Needs A + B. Uses up X.", then limits. Three regular cards open with a requirement instead of the
   effect ("Needs an area Warden near a Firefly." Flashover; "Needs another source of jumps." Gathering
   Storm; "Needs another family's status." Overnight).
5. **Sibling shapes drift** (details in section 3): the 8 Firefly jump cards use 4 different shapes; the
   Dewdrop cards name their Wardens 4 different ways ("Dewdrops and Wardens near them", "Hits from
   Wardens near a Dewdrop", "in a Dewdrop's range", "touching a Dewdrop"); Sporeling cards the same.
6. **Number mismatches found while scanning** (not this seat's call; pass to owners): see section 5.

---

## 1. Top 15 hardest-to-scan texts (ranked)

| # | Where | Now (words) | What trips the eye | Rewrite (keeps every mechanic, number, token) | Words |
|---|---|---|---|---|---|
| 1 | Reaction **Sleepwalk** `resource/reaction/sleepwalk.tres` | "It turns and walks back up the path for 2 s at half speed (bosses 1 s), and every nightmare it bumps into turns round too for 0.5 s (never bosses). Needs {stacks:need_spored} {spored} + {full} {drowsy}. Uses up the {drowsy}. Twice per nightmare at most (bosses once). Waits while it is {asleep} or near a {warden:dreamcatcher}. Never flyers." (59) | Four parentheses, six sentences, three different "bosses" exceptions; the recipe sits in the middle of the effect and the limits. | "Walks back up the path at half speed for 2 s (bosses 1 s). Nightmares it bumps turn back for 0.5 s, not bosses. / Needs {stacks:need_spored} {spored} + {full} {drowsy}. Uses up the {drowsy}. / Twice per nightmare (bosses once). Not flyers. Waits while {asleep} or near a {warden:dreamcatcher}." | ≈46 |
| 2 | Status tooltip **Silenced** `scripts/ui/icon_info.gd:33` (mid-fight tooltip) | "It can't use its abilities. A Watcher can't wake, a Weeper can't heal, and a Lantern Bearer's lantern goes dark, so its Wraiths lose their way. Bosses still fight, but their timed abilities come at half speed.\nLasts while a Hushbell's song reaches it. A Silence (Hushbell's next form) or a Vespers toll keeps it 2 s longer." (58) | Longest status tooltip; "so … lose their way" and "but …" clauses; the duration rule is in the last line. | "No abilities: a Watcher can't wake, a Weeper can't heal, a Lantern Bearer's Wraiths lose their way. Bosses' timed abilities come at half speed. / Lasts while a Hushbell reaches it, 2 s longer from {warden:silence} or a Vespers toll." | ≈38 |
| 3 | Reaction **Night Terror** | "It wakes screaming: its {static} goes off at once as a bolt, and every nightmare within 2 cells can't move for 1 s (bosses 0.5 s) and gains 2 {held}. Needs {stacks:need_static} {static} + {full} {drowsy}. Uses up the {static} and the {drowsy}. Waits while it is {asleep} or near a {warden:dreamcatcher}." (52) | Flavour opener before the effect; two effects joined by "and"; held stacks named after the duration. | "Its {static} bolts at once. Nightmares within 2 cells gain 2 {held}: 1 s (bosses 0.5 s). / Needs {stacks:need_static} {static} + {full} {drowsy}. Uses up both. / Waits while {asleep} or near a {warden:dreamcatcher}." | ≈34 |
| 4 | Evolution **Tidecaller** `dream_tidecaller.tres` | "[P]: every 6 s a great wave gives everything in range {damp}, pushes it back 1 {step}, and leaves the ones at {f:freeze_needs_stacks} {damp} {stacks} {frozen}: each gains 1 {held} and can't move for {f:freeze_duration}." (46) | Three colons in one sentence; the freeze rule nests inside the wave list. | "[P]. Every 6 s a wave gives everything in range {damp} and pushes it back 1 {step}. At {f:freeze_needs_stacks} {damp} {stacks}: {frozen}, 1 {held} for {f:freeze_duration}." | ≈32 (≈21 without [P]) |
| 5 | Reaction **Pinned** | "The next hit on it is a guaranteed crit for ×3 damage that pierces: nightmares in a 3-cell line behind it take half. Needs {stacks:need_marked} {marked}, plus {stacks:need_held} {held}, {full} {drowsy} or {asleep}. Uses up the {marked}, and the {drowsy} when that set it off." (45) | "plus A, B or C" reads as all three at first glance; the conditional use-up trails. | "Its next hit is a sure crit for ×3 that pierces: half to nightmares in a 3-cell line behind. / Needs {stacks:need_marked} {marked} + one of {stacks:need_held} {held}, {full} {drowsy}, {asleep}. / Uses up the {marked}, and the {drowsy} if that set it off." | ≈42 |
| 6 | Warden **Wellspring** `resource/tower/wellspring.tres` | "Pulses damage to every nightmare in range. Nightmares dispelled within {f:catch_radius} drop {f:catch_share} more {dew}, paid at the {rest}. At every rest it also pays {f:rest_interest} of your banked Dew (up to {dew:{f:rest_interest_max}}; all Wellsprings together up to {dew:260}), and {dew:{f:dew_per_drift}} each {drift}." (43) | A semicolon inside parentheses inside a sentence; three incomes in three shapes; "rest" raw beside {rest}. | "Pulses damage to every nightmare in range. / Dispels within {f:catch_radius}: {f:catch_share} more {dew}, paid at the {rest}. / Each {rest}: {f:rest_interest} of banked {dew}, up to {dew:{f:rest_interest_max}} (all Wellsprings: {dew:260}). / Each {drift}: {dew:{f:dew_per_drift}}." Also see the cap mismatch, section 5. | ≈36 |
| 7 | Warden **Dream Oak** | "Pulses damage to every nightmare in range. It also makes {dreamlight} slowly, faster with more {families} near it: 1 shard each {drift}, +1 for each different {family} among Wardens within {f:family_reach} (up to +{f:family_max}). 10 shards make 1 Dreamlight (up to {f:dreamlight_max} a run)." (44) | "slowly, faster with more families" says the formula twice; two parentheses. | "Pulses damage to every nightmare in range. / {dreamlight} shards each {drift}: 1, +1 per different {family} among Wardens within {f:family_reach}, up to +{f:family_max}. / 10 shards make 1 {dreamlight}, up to {f:dreamlight_max} a run." | ≈36 |
| 8 | Warden **Heartwood Sapling** | "A seedling of the Heartwood, 2×2 and rooted for good. Gives {dew:8} after every {drift} and 1 {dreamlight} every 10 drifts. Each Nurture {rank} adds {dew:4}; from rank III, Dreamlight every 8 drifts. Each {leaf} lost withers the yield 5% until the next {rest}." (44) | Rank bonuses split across a semicolon; "drifts" raw twice beside {drift}. | "2×2, rooted for good. / After every {drift}: {dew:8}, +{dew:4} per Nurture {rank}. / 1 {dreamlight} every 10 {drifts}, every 8 from {rank} III. / Each {leaf} lost: yield −5% until the next {rest}." | ≈33 |
| 9 | Evolution **Hoarfrost** | "[P]: splashing frost shards that give nightmares {damp}, up to {f:status_max_stacks} {stacks}; at {f:freeze_needs_stacks} {stacks} of {damp} a nightmare is {frozen}: it gains 1 {held} and can't move for {f:freeze_duration}. More crits on nightmares with {held}." (42) | Semicolon then colon then colon. | "[P]: splashing frost that gives {damp}, up to {f:status_max_stacks} {stacks}. At {f:freeze_needs_stacks} {damp}: {frozen}, 1 {held} for {f:freeze_duration}. More crits on nightmares with {held}." | ≈31 |
| 10 | Reaction **Mushrooming** | "A spore cloud grows on its cell and the next path cell for 4 s: nightmares inside take 30% more effect damage (statuses, bolts and most {reactions}), until 1 s after they leave. Needs {stacks:need_spored} {spored} + {stacks:need_damp} {damp}. Uses up the {damp}." (43) | Parenthesis splits the payoff from its "until" clause. | "A spore cloud covers its cell and the next for 4 s. Nightmares inside, and for 1 s after, take 30% more effect damage. / Needs {stacks:need_spored} {spored} + {stacks:need_damp} {damp}. Uses up the {damp}." Note: "effect damage" is a glossary link (Effect = statuses, bolts, Reactions); "most Reactions" moves into the Codex entry. | ≈34 |
| 11 | Evolution **The Great Bell** | "[P]: every 8 s it peals across a huge range: every nightmare falls {asleep}, and every nightmare with {f:sets_off_static_at} or more {static} {stacks} releases its bolt at half strength." (40) | Colon after colon; "every nightmare" three times. | "[P]. Every 8 s, across a huge range: all nightmares fall {asleep}. Those with {f:sets_off_static_at}+ {static} {stacks} release their bolt at half strength." | ≈30 |
| 12 | Dream tip **Wild Growth** | "A dispel counts for the Warden that lands it and the 2 nearest other Wardens with it in range. You pick the form; branches still need Dreamlight, and Nurture ranks still pay their difference. Not Thornwalls, the Sapling or Ascended forms. Can't be taken with {card:clean_night}. Works for: Sprouts and every family's Wardens. A bet: where nightmares die." (58) | Longest tip; raw "Dreamlight"; two rules joined by a semicolon. | "A dispel counts for its Warden and the 2 nearest Wardens with it in range. You pick the form. Branches still cost {dreamlight}; Nurture ranks pay the difference. Not Thornwalls, the Sapling or {ascended} forms. Not with {card:clean_night}. A bet: where nightmares die." | ≈42 |
| 13 | Dream **Afterroot** | "When {held} ends on a nightmare, the next hit on it from another Warden within 2 s adds 5 {stacks} of {marked}. Each nightmare once every 4 s." (28) | Three nested conditions (held ends → another Warden → within 2 s) before the payoff. | "After {held} ends, another Warden's next hit within 2 s adds 5 {marked} {stacks}. Each nightmare once every 4 s." | 18 |
| 14 | Dream **Momentum** | "A Warden attacks 6% faster for each hit in a row on the same nightmare, up to +45%. On a new nightmare, the bonus drains over 1 s." (28) | Fine shape, just long; second sentence opens with its condition. | "Wardens attack 6% faster per hit in a row on one nightmare, up to +45%. Switching targets drains it over 1 s." | 21 |
| 15 | Warden **Quaker** | "Slams sprints to a stop: every 3 s it slams the ground around it, and the nightmares it hits lose their speed boosts (a sprinting {nightmare:hedgehog} stops). The slam also shakes {hidden} nightmares loose: they show for 3 s." (39) | "slams" twice; parenthesis inside the effect. | "Every 3 s it slams the ground around it. Nightmares hit lose speed boosts; a sprinting {nightmare:hedgehog} stops. {hidden} nightmares show for 3 s." | ≈24 |

---

## 2. All other over-long or badly ordered strings

### 2a. Evolution-unlock Dream cards over 25 words (not in the top 15)

All keep [P] unchanged; counts are for the whole card now. With the header-row change from finding 2,
only the rewrite text after [P] would remain.

| Where | Words | Now (after [P]) | Rewrite (after [P]) |
|---|---|---|---|
| dream_frostfern | 41 | "hits on nightmares with {f:freeze_needs_stacks} or more {damp} {stacks} leave them {frozen}: each gains 1 {held} and can't move for {f:freeze_duration}. It adds no {damp} of its own: pair it with Wardens that do." | "hits on nightmares with {f:freeze_needs_stacks}+ {damp} {stacks} leave them {frozen}: 1 {held} for {f:freeze_duration}. Adds no {damp} itself." ("pair it with…" is hand-holding.) |
| dream_old_mountain | 41 | "every 3 s it drops a boulder: what it hits gains 1 {held} and can't move for 0.5 s, and it always crits on nightmares with {held} or {drowsy}." | ". Every 3 s a boulder drops: what it hits gains 1 {held} for 0.5 s. Always crits on nightmares with {held} or {drowsy}." |
| dream_whirligig | 37 | "(base prefix, plant cost). Its gusts carry trouble along: every {f:copy_status_every} it copies one status, at half the {stacks}, from the most afflicted nightmare in range onto a neighbour." | "Every {f:copy_status_every} it copies one status from the most-afflicted nightmare in range onto a neighbour, at half the {stacks}." (Drop the flavour opener.) |
| dream_midsummer | 36 | "a brighter beam that grows stronger the longer it stays on one nightmare, and carries on to the nightmare right behind it. Switching nightmares keeps half of that strength." | "a brighter beam that ramps up on one nightmare and also hits the one right behind it. Switching keeps half the ramp." |
| dream_mother_log | 36 | "Wardens {touching} it pay {f:nurture_discount} less to Nurture, and a Warden sold there leaves its {rank} in the log for the next one planted on that cell this {rest}." | "Wardens {touching} it pay {f:nurture_discount} less to Nurture. Sell one there and the next Warden planted on that cell this {rest} keeps its {rank}." |
| dream_world_root | 36 | "every {f:attacks_per_second} roots erupt: everything in range gains 1 {held} and can't move for {f:freeze_duration}; nightmares with {held} take {f:held_damage_bonus} more from every Warden." | ". Every {f:attacks_per_second}, everything in range gains 1 {held} for {f:freeze_duration}. Nightmares with {held} take {f:held_damage_bonus} more from every Warden." |
| dream_pebbling | 35 | "A heavy pebble: {f:splash_share} splashes onto nightmares {touching} the one it hits, then it skips on to another within {f:skip_radius} for {f:skip_share} damage." | "A heavy pebble: {f:splash_share} splash to nightmares {touching} its target, then a skip to one within {f:skip_radius} for {f:skip_share}." |
| dream_sporemother | 35 | "her storm gives {f:status_stacks} {spored} per second to everything in range, and {spored} never wears off while a nightmare is in her range." | "{f:status_stacks} {spored} a second to everything in range. In her range, {spored} never wears off." |
| dream_tempest | 35 | "a cyclone roams the path in its range, hitting everything it passes; statuses it touches travel with it and settle on the rest." | "a cyclone roams the path in range, hitting all it passes. It carries the statuses it touches onto the rest." |
| dream_beacon | 34 | "every {f:ability_every} it adds 1 {stack} of {marked} to every nightmare in range, and nightmares at {full} {marked} take +{f:marked_bonus} damage on top of what {marked} gives." | "every {f:ability_every}, 1 {marked} {stack} on every nightmare in range. At {full} {marked} they take +{f:marked_bonus} more damage, on top." |
| dream_dawnwing | 34 | "a great bird patrols the path in its range, hitting every nightmare it passes; it flies faster the more nightmares there are." | "a great bird patrols the path in range, hitting every nightmare it passes. More nightmares, faster flight." |
| dream_great_dreamcatcher | 34 | "a wider net; {caught} nightmares' statuses stop wearing off and tick 25% harder; {asleep} lasts 1 s longer in its range, and {caught} nightmares leave {dreamlight} shards." | "a wider net. {caught} statuses never wear off and tick 25% harder. {asleep} lasts 1 s longer in range. {caught} nightmares drop {dreamlight} shards." |
| dream_acorn | 33 | "(base prefix). It throws acorns that bounce onto the nightmares {touching} the one it hits, and Wardens {touching} it deal {f:aura_damage_bonus} more damage." | "Acorns bounce to nightmares {touching} its target. Wardens {touching} it deal {f:aura_damage_bonus} more damage." |
| dream_stormheart | 32 | "its lightning {jumps} to every nightmare in range, dealing {f:chain_falloff} less with each {jump}, and leaves {f:status_stacks} {stacks} of {static}." | "lightning {jumps} to every nightmare in range, {f:chain_falloff} less per {jump}, leaving {f:status_stacks} {static}." |
| dream_dream_oak | 31 | "it gathers {dreamlight} shards from a mixed grove: a shard each {drift}, and one more for each different {family} among the Wardens within {f:family_reach}." | "1 {dreamlight} shard each {drift}, +1 per different {family} among Wardens within {f:family_reach}." |
| dream_boulderback | 30 | "a crushing hit that splashes {f:splash_share} of its damage; double damage on nightmares with {marked}, and it always crits on those with {drowsy}." | "a crushing hit, {f:splash_share} splash. Double damage on nightmares with {marked}; always crits on {drowsy}." |
| dream_grandmother_oak | 30 | "Wardens in her range deal {f:aura_damage_bonus} more damage and attack {f:aura_speed_bonus} faster; she gives {dew:{f:dew_per_drift}} after every {drift}." | ": Wardens in her range deal {f:aura_damage_bonus} more damage and attack {f:aura_speed_bonus} faster. {dew:{f:dew_per_drift}} after every {drift}." |
| dream_rootlight | 30 | "glowing roots light the path around it; {held} lasts {f:lit_hold_multiplier} times as long on glowing cells, and {hidden} nightmares show in the light." | "roots light the path around it. On lit cells {held} lasts {f:lit_hold_multiplier} times as long and {hidden} nightmares show." |
| dream_dreamcatcher | 29 | "nightmares in its range that are {asleep} or at {full} {drowsy} are {caught}: their statuses stop wearing off while they stay {caught}." | "nightmares in range that are {asleep} or at {full} {drowsy} are {caught}: their statuses stop wearing off." |
| dream_lullaby_bell | 29 | "a bigger pulse that gives nightmares {static} and {drowsy}; any nightmare with {f:sets_off_static_at} or more {static} {stacks} releases its bolt at once." | "a bigger pulse that gives {static} and {drowsy}. Nightmares with {f:sets_off_static_at}+ {static} release their bolt at once." |
| dream_puffball | 29 | "its puff bursts on landing over {f:splash_radius}, giving {f:status_stacks} {spored} to every nightmare there, and nightmares it hits can hold {f:status_max_stacks} {spored}." | "puffs burst over {f:splash_radius}: {f:status_stacks} {spored} on every nightmare there. Its targets hold up to {f:status_max_stacks} {spored}." |
| dream_autumn_gale | 28 | "{f:boomerang_seeds} seeds down the busiest lines; each caught seed that hit something makes the next throw {f:catch_bonus} stronger, up to {f:catch_bonus_max}." | "{f:boomerang_seeds} seeds down the busiest lines. Each returning seed that hit makes the next throw {f:catch_bonus} stronger, up to {f:catch_bonus_max}." |
| dream_chime_stone | 28 | "a weak pulse that gives everything around it {static}, and sets off a bolt on nightmares with {f:sets_off_static_at} or more {stacks}." | "a weak pulse that gives {static}. Nightmares with {f:sets_off_static_at}+ {stacks} bolt at once." |
| dream_earthbind | 28 | "every {f:ground_every} it pulls up to {f:ground_max} flyers down; each gains 1 {held} when it lands and can't move for {f:land_hold}." | "every {f:ground_every} it pulls down up to {f:ground_max} flyers, each landing with 1 {held} for {f:land_hold}." |
| dream_jewelwing_court | 28 | "{f:peck_birds} hummingbirds, {f:pecks} pecks each; every {f:flurry_every} pecks, one is a guaranteed crit. They spread out or all focus the strongest." | "{f:peck_birds} hummingbirds, {f:pecks} pecks each. One peck in every {f:flurry_every} is a sure crit. They spread out or focus the strongest." |
| dream_sunpetal | 28 | "a beam that grows stronger the longer it stays on one nightmare; twice as fast on nightmares with {drowsy} or {held}." | "a beam that ramps up on one nightmare, twice as fast on nightmares with {drowsy} or {held}." |
| dream_samara | 27 | "throws a spinning maple seed down a straight line and back through everything, carrying the first nightmare's statuses along it." | "a maple seed flies down a line and back, hitting everything and carrying the first nightmare's statuses." |
| dream_starcave | 27 | "a bigger glowing area; {held} lasts {f:lit_hold_multiplier} times as long on glowing cells, and {hidden} nightmares show in the light." | "a bigger glow. On lit cells {held} lasts {f:lit_hold_multiplier} times as long and {hidden} nightmares show." |
| dream_echo_hollow | 26 | "a hollow log that echoes {reactions}: one nearby repeats a second later on the same nightmare, at {echo:echo_hollow} strength." | "{reactions} nearby repeat 1 s later on the same nightmare, at {echo:echo_hollow} strength." |
| dream_rockslide | 26 | "a bigger splash, and the path where its stones land is left with rubble that slows for 3 s." | "a bigger splash that leaves rubble on the path, slowing for 3 s." |
| dream_standing_stone | 26 | "one slow, heavy attack that hits harder the further away the nightmare is; it can't hit nightmares {near} it." | "slow, heavy shots that hit harder the farther the target. Can't hit nightmares {near} it." |
| dream_starling_murmuration | 26 | "{f:multi_targets} starlings each hunt one of the fastest nightmares in range; extra damage to Phantoms and sprinting Night Hounds." | "{f:multi_targets} starlings hunt the fastest nightmares in range. Extra damage to {nightmare:dandelion_seed}s and sprinting {nightmare:hedgehog}s." (Raw names → tokens, as on the Warden.) |

Under 25 but a scan problem: **dream_deeproot** / **dream_snugroot** / **dream_tangleroot** / **dream_rootcurl** /
**dream_long_way_home** all say "the nightmare furthest along … gains 1 {held} and can't move for X" →
"the leader gains 1 {held} for X" (finding 3).

### 2b. Regular Dream cards: over 25, or badly ordered

| Where | Words | Now | Rewrite |
|---|---|---|---|
| Flashover | 23 | "Needs an area Warden {near} a Firefly. When its attack hits 2 or more nightmares, half {jumps} to the nearest one it missed." | "When an area Warden {near} a Firefly hits 2+ nightmares, half {jumps} to the nearest one it missed." (Requirement folded into the trigger.) |
| Gathering Storm | 22 | "Needs another source of {jumps}. Each {jump} a nightmare takes makes the next {jump} on it 25% stronger, up to +200%." | "Each {jump} on a nightmare makes the next {jump} on it 25% stronger, up to +200%. Needs another source of {jumps}." (Effect first.) |
| Overnight | 21 | "Needs another {family}'s status. A Sporeling's hit adds 2 {stacks} to each status other {families} put on the nightmare." | "A Sporeling's hit adds 2 {stacks} to each status other {families} put on the nightmare." (The tip already says it never starts a status; the "Needs" line can be the card's needs row.) |
| Sparks Fly | 24 | "After a Firefly hits a nightmare, every 3rd hit another Warden lands on it within 2 s {jumps} half to the nearest other nightmare." | "For 2 s after a Firefly hits a nightmare, every 3rd hit on it from another Warden {jumps} half to the nearest other nightmare." (Same shape as Brushfire; the "2 s" window moves next to the Firefly.) |
| Shared Fever | 25 | "An area attack hitting 3 or more nightmares gives each 1 {stack} of the most-stacked one's top 2 statuses. Each Warden once every 2 s." | "Area attacks hitting 3+ nightmares give each 1 {stack} of the top 2 statuses on the most-stacked one. Each Warden once every 2 s." |
| Breathe It In | 24 | "Statuses added to nightmares in a Sporeling's range get 1 more {stack}, 3 if it is {asleep} or {held}. Once a second per Warden." | "Statuses added to nightmares in a Sporeling's range get 1 more {stack}, 3 more if the nightmare is {asleep} or {held}. Once a second per Warden." ("it" was ambiguous: Sporeling or nightmare.) |
| Last Drop | 23 | "When {damp} from Dewdrops or Wardens {near} them runs out, the nightmare takes 40% of their hit per {stack}, up to 3 hits." | Order is fine; "40% of their hit per stack, up to 3 hits" is ambiguous (3 hits = 3 stacks?). Owner to confirm, then e.g. "…takes 40% of that Warden's hit per {stack}, at most 3 {stacks}' worth." |
| Mixed Company | 24 | "Hits on a nightmare {near} a Sporeling add 1 more {stack} for each status it carries, up to 4. Each Warden once a second." | "Hits on a nightmare {near} a Sporeling add 1 more {stack} per status it carries, up to 4. Each Warden once a second." (Fine; "per" for "for each" saves the eye across all scaling cards.) |
| Heavy Heart | 23 | "A {heavy} Warden's hit sets off a {reaction} if the nightmare carries both of the {reaction}'s statuses. Each nightmare once every 3 s." | Good. Keep as the model for Witching Bend (same shape: "[trigger] sets off a {reaction} if it carries both statuses. Each nightmare once every N s."). |
| Old Heart | 24 | "An {ascended} Warden's hit lets the nightmare's next {reaction} go off at once; then the Warden attacks again. Each nightmare once every 4 s." | "An {ascended} Warden's hit sets off the nightmare's next {reaction} at once, and the Warden attacks again. Each nightmare once every 4 s." (Same verb as Called from Afar should use: "sets off … at once".) |
| Called from Afar | 25 | "A hit from a Warden 4 or more cells away lets the nightmare's next {reaction} go off at once. Each nightmare once every 3 s." | "Hits from 4+ cells away set off the nightmare's next {reaction} at once. Each nightmare once every 3 s." |
| Rooted Nightmares | 25 | "Every 8th hit from a Warden adds 1 {held}: the nightmare can't move for 1 s (bosses 0.5 s). Each nightmare once every 4 s." | "Every 8th hit from a Warden adds 1 {held} for 1 s (bosses 0.5 s). Each nightmare once every 4 s." |
| First Frost | 22 | "The first 5 nightmares of each {drift} to enter an attacking Warden's range gain 1 {held}: they can't move for 1.5 s." | "The first 5 nightmares each {drift} to enter an attacking Warden's range gain 1 {held} for 1.5 s." |
| Briar Trap | 20 | "Each {drift}, each Thornwall adds 1 {held} to the first nightmare that passes it: it can't move for 1.5 s." | "Each {drift}, each Thornwall gives the first nightmare passing it 1 {held} for 1.5 s." |
| Refrain | 25 | "After a bell hits a nightmare, the next hit on it from another Warden within 2 s lands twice. Each Warden once every 4 s." | "For 2 s after a bell hits a nightmare, the next hit on it from another Warden lands twice. Each Warden once every 4 s." (Same window-first shape as Brushfire / Sparks Fly / Opening Fracture.) |
| Opening Fracture | 24 | "After a crit, the next hit on that nightmare from another Warden within 2 s deals 40% more. Each nightmare once every 3 s." | "For 2 s after a crit, another Warden's next hit on that nightmare deals 40% more. Each nightmare once every 3 s." |
| Lingering Splash | 25 | "Every 3rd area attack a Warden makes leaves a patch for 2 s that deals 25% of that hit each second to nightmares in it." | "Every 3rd area attack a Warden makes leaves a 2 s patch: nightmares in it take 25% of that hit each second." |
| Loose Stones | 25 | "{warden:cairn} and {warden:rockslide} stones break into 3 when they land. Each piece deals 35% of the stone's damage on a random cell within 1.5 cells." | "{warden:cairn} and {warden:rockslide} stones break into 3 on landing, each dealing 35% of the stone's damage to a random cell within 1.5 cells." |
| Hunt's Rush II | 25 | "When a nightmare is dispelled in a Warden's range, that Warden attacks 30% faster for 5 s. Each further one adds 10%, up to +60%." | Fine shape (Hunt's Rush + one sentence). Keep: it compares well with Hunt's Rush side by side. |
| Thousand Cuts | 25 | "Each hit on a nightmare makes it take 2% more damage from every Warden, up to +60%. It fades 2 s after the last hit." | Fine. |
| Growth Rings | 24 | "At a {rest}, if you planted nothing since the last {rest}, the {block}'s top Warden gets a free Nurture {rank}, up to {rank} III." | "At each {rest}, if you planted nothing this {block}, its top Warden gets a free Nurture {rank}, up to {rank} III." |
| Hunter's Moon | 24 | "Each Warden's first hit on a nightmare adds 1 {stack} of {marked} that never wears off. Dispelling it gives the 2 nearest 1 {stack}." | "Each Warden's first hit on a nightmare adds 1 {marked} {stack} that never wears off. When it is dispelled, the 2 nearest get 1 {stack}." ("Dispelling it" reads as dispelling the stack.) |
| Reprise | 24 | "A {reaction} on a nightmare in a bell's range goes off again 1 s later at half damage. Each nightmare once every 8 s." | Fine. |
| Chain of Lanterns | 23 | "A {reaction} on a nightmare a Firefly hit in the last 2 s also {jumps}, at half damage, to the 2 nearest nightmares." | "For 2 s after a Firefly hits a nightmare, a {reaction} on it also {jumps} at half damage to the 2 nearest." (Firefly shape.) |
| Witching Bend | 23 | "A nightmare rounding a bend sets off a {reaction} if it carries both of the {reaction}'s statuses. Each nightmare once every 5 s." | Fine (matches Heavy Heart). |
| Nod Off | 23 | "The first time a bell gives a nightmare {drowsy}, it falls {asleep} for 1 s. Each bell keeps one sleeper at a time." | Fine. |
| The Walking Wood | 23 | "Swap any two Wardens' places, free, even during a {drift}. Both wait 2 s before attacking; you can swap again after 10 s." | "Swap any two Wardens, free, even during a {drift}. Both wait 2 s to attack. Swap again after 10 s." |
| Bitter Hedges | 23 | "Nightmares take 8% more damage from hits for each Thornwall, Bramble or Honeysuckle they passed in the last 2 s, up to +40%." | Fine (scaling template). |
| High Tide | 18 | "Hits from Wardens {near} a Dewdrop deal 10% more for each status on the nightmare, up to +30%." | "Dewdrops and Wardens {near} them deal 10% more per status on the nightmare, up to +30%." (Sibling shape with Heavy Going / Sodden; tip already says "Dewdrops count" and "hits only".) |
| Steeped | 21 | "Statuses last 40% longer when added by a Warden {touching} a Dewdrop, or to a nightmare in range of two Dewdrops." | "Statuses last 40% longer if added by a Warden {touching} a Dewdrop, or to a nightmare in two Dewdrops' range." (Minor.) |

### 2c. Warden descriptions over 25 words (not in the top 15)

| Where | Words | Now | Rewrite |
|---|---|---|---|
| Great Dreamcatcher | 39 | "Shoots one nightmare. Nightmares in its range that are {asleep} or at {full} {drowsy} are {caught}: their statuses stop wearing off and hurt 25% more. {asleep} lasts 1 s longer in its range, and {caught} nightmares leave {dreamlight} shards." | "Shoots one nightmare. In range, nightmares {asleep} or at {full} {drowsy} are {caught}: statuses never wear off and hurt 25% more. {asleep} lasts 1 s longer. {caught} nightmares drop {dreamlight} shards." |
| Seedbearer | 38 | "Pulses damage to every nightmare in range. Every {f:seed_every} {drifts} it grows a seed, and at the {rest} you plant it as a free Sprout anywhere you could plant one (up to {f:seed_max} of its Sprouts at once)." | "Pulses damage to every nightmare in range. A seed every {f:seed_every} {drifts}: plant it at the {rest} as a free Sprout. Up to {f:seed_max} of its Sprouts at once." |
| Mother Log | 37 | "Pulses damage to every nightmare in range. Wardens in the 8 cells around it pay 35% less to Nurture. Sell a Warden beside it and the next Warden planted on that cell this {rest} keeps its {rank}." | "Pulses damage to every nightmare in range. Wardens {touching} it pay 35% less to Nurture. Sell one beside it: the next Warden planted there this {rest} keeps its {rank}." ({touching} = the 8 cells around, per the glossary.) |
| Tidecaller | 36 | "Every 6 s a great wave gives everything in range {damp} and drags it back 1 cell along the path. The ones with {f:freeze_needs_stacks} {damp} are {frozen}: each gains 1 {held} and can't move for {f:freeze_duration}." | "Every 6 s a wave gives everything in range {damp} and drags it back 1 cell. At {f:freeze_needs_stacks} {damp}: {frozen}, 1 {held} for {f:freeze_duration}." (Card says "1 {step}", Warden says "1 cell": pick one.) |
| Hoarfrost | 32 | "Splashing frost that gives nightmares {damp} (up to {f:status_max_stacks}). At {f:freeze_needs_stacks} {damp} a nightmare is {frozen}: it gains 1 {held} and can't move for {f:freeze_duration}. It crits more on nightmares with {held}." | "Splashing frost gives {damp}, up to {f:status_max_stacks}. At {f:freeze_needs_stacks} {damp}: {frozen}, 1 {held} for {f:freeze_duration}. More crits on nightmares with {held}." |
| Acorn | 31 | "Throws acorns that bounce onto the nightmares beside its target. Wardens in the 8 cells around it deal {f:aura_damage_bonus} more damage; a second Acorn's boost on the same Warden counts half." | "Acorns bounce to nightmares beside its target. Wardens {touching} it deal {f:aura_damage_bonus} more damage. A second Acorn's boost counts half." |
| Earthbind | 31 | "Its roots damage every nightmare in range. Every {f:ground_every} it drags up to {f:ground_max} flyers down to the path. Each gains 1 {held} when it lands: it can't move for {f:land_hold}." | "Roots damage every nightmare in range. Every {f:ground_every} it drags down up to {f:ground_max} flyers, each with 1 {held} for {f:land_hold}." |
| Rampart | 31 | "Hits the path cells around it, and deals {f:per_wall} more damage for each Thornwall beside it (up to {f:max_walls}). Those Thornwalls turn to stone: they can't be trampled or burrowed under." | "Hits the path cells around it. Deals {f:per_wall} more damage per Thornwall beside it, up to {f:max_walls}. Those walls turn to stone: no trampling or burrowing." |
| Rockslide | 30 | "A bigger splash, and the path where its stones land is left with rubble that slows nightmares by 40% for 3 s. Nightmares right beside it are safe from it." | "A bigger splash. Its stones leave rubble that slows nightmares 40% for 3 s. Can't hit nightmares right beside it." |
| Groundroot | 29 | "Its roots damage every nightmare in range. Every {f:ground_every} it drags up to {f:ground_max} flyers within {f:ground_reach} down onto the path, where they must walk the maze for {f:ground_time}." | "Roots damage every nightmare in range. Every {f:ground_every}, up to {f:ground_max} flyers within {f:ground_reach} are dragged down to walk the maze for {f:ground_time}." |
| Grove Heart | 29 | "Pulses damage to the nightmares in range. Wardens within {f:aura_radius} deal {f:aura_damage_bonus} more damage and attack {f:aura_speed_bonus} faster, 3% more for each Warden in that area (up to 45%)." | "…attack {f:aura_speed_bonus} faster, +3% per Warden there, up to 45%." |
| Old Lichen | 29 | "Each tick of its {spored} (twice a second) wears {f:shell_strip} of a {dread_shell} away, and nightmares with its {spored} can't heal. At {f:crack_at} {spored} {stacks} the whole shell breaks." | "Its {spored} ticks twice a second, each wearing {f:shell_strip} off a {dread_shell}. Nightmares with its {spored} can't heal. At {f:crack_at} {stacks} the whole shell breaks." (Same fix for Lichenling, 25.) |
| Old Mountain | 29 | "Every 3 s it drops a boulder: what it hits gains 1 {held} and can't move for 0.5 s, and it always crits on nightmares with {held} or {drowsy}." | "Every 3 s a boulder drops: what it hits gains 1 {held} for 0.5 s. Always crits on nightmares with {held} or {drowsy}." |
| Whirligig | 29 | "Its gusts damage every nightmare in range. Every {f:copy_status_every} it copies one status (half the {stacks}) from the nightmare with the most statuses in range onto one beside it." | "Gusts damage every nightmare in range. Every {f:copy_status_every} it copies one status, at half the {stacks}, from the most-afflicted nightmare onto one beside it." |
| Elder Stump | 28 | "Pulses damage to the nightmares in range. Wardens in the 8 cells around it attack {f:aura_speed_bonus} faster; a second Elder Stump's boost on the same Warden counts half." | "Pulses damage in range. Wardens {touching} it attack {f:aura_speed_bonus} faster. A second Elder Stump's boost counts half." |
| Hushbell | 27 | "Rings out, damaging every nightmare in range and leaving them {silenced}: they can't use their abilities (no waking, no healing; bosses' timed abilities come at half speed)." | "Rings out, damaging every nightmare in range. They are {silenced}: no waking or healing; bosses' timed abilities at half speed." |
| Jetreed | 27 | "A jet that hits every nightmare in a line. Each hit also takes {f:erosion} of its target's max health (0.5% on bosses), so it suits big nightmares." | "A jet hits every nightmare in a line. Each hit also takes {f:erosion} of max health (bosses 0.5%)." ("so it suits…" is hand-holding; the role line says Boss killer.) |
| Long Way Home | 27 | "Its roots damage every nightmare in range. Every {f:ability_every} it drags the nightmare furthest along the path back {f:pull_tiles} cells (each nightmare only once; bosses 1 cell)." | "Roots damage every nightmare in range. Every {f:ability_every} the leader is dragged back {f:pull_tiles} cells (bosses 1). Once per nightmare." |
| Morning Fog | 27 | "A wide fog that lasts {f:cloud_duration}. Nightmares in it have {damp}, for {f:status_duration} after leaving too, and {spored} hurts more. Nothing can hide or heal in it." | "A wide fog for {f:cloud_duration}. Nightmares in it have {damp}, and keep it {f:status_duration} after leaving. {spored} hurts more. Nothing hides or heals in it." |
| Pebbling | 27 | "A slow, heavy pebble: 40% of the hit splashes onto nightmares right beside its target, then it skips on to one within 1 cell for three-quarters damage." | "A slow, heavy pebble. 40% splashes onto nightmares beside its target, then it skips to one within 1 cell for three-quarters damage." |
| Snugroot | 27 | "Its roots damage every nightmare in range. Every {f:ability_every} up to {f:hold_targets} of the nightmares furthest along the path gain 1 {held} and can't move for {f:hold_time}." | "Roots damage every nightmare in range. Every {f:ability_every}, up to {f:hold_targets} leaders gain 1 {held} for {f:hold_time}." |
| World Root | 27 | "Every 5 s roots erupt: everything in range gains 1 {held} and can't move for 1 s. Nightmares with {held} take 30% more damage from every Warden." | "Every 5 s, everything in range gains 1 {held} for 1 s. Nightmares with {held} take 30% more damage from every Warden." |
| Cairn | 26 | "Lobs its top stone over the maze onto a cell up to 6 cells away, hitting everything there. Nightmares right beside it are safe from it." | "Lobs a stone over the maze up to 6 cells away, hitting everything on that cell. Can't hit nightmares right beside it." (Same "can't hit up close" sentence for Moonstone, Standing Stone, Rockslide.) |
| Dreamroot | 26 | "Pulses damage to every nightmare in range. It gathers {dreamlight} shards like {warden:dream_oak}, and twice as many in a {block} where no nightmare reaches the Heartwood." | "Pulses damage to every nightmare in range. Gathers {dreamlight} shards like {warden:dream_oak}, twice as many in a {perfect_block}." |
| Frostfern | 26 | "A hit on a nightmare with {f:freeze_needs_stacks} {damp} leaves it {frozen}: it gains 1 {held} and can't move for {f:freeze_duration}. Pair it with Wardens that Soak." | "Hits on nightmares with {f:freeze_needs_stacks} {damp} leave them {frozen}: 1 {held} for {f:freeze_duration}. Adds no {damp} itself." (Raw "Soak" → token.) |
| The Great Bell | 26 | "Every 8 s it peals across a huge range: every nightmare falls {asleep}, and every nightmare with {static} is struck by its bolt for half damage." | "Every 8 s, across a huge range: all nightmares fall {asleep}; those with {static} take its bolt for half damage." (Threshold mismatch with the card, section 5.) |
| Heartroot | 26 | "Its roots damage every nightmare in range. Once per {drift}, the first nightmare about to reach the Heartwood is dragged back {f:not_yet_tiles} cells instead. Not bosses." | Drop "instead"; otherwise fine. |
| Jarlink | 26 | "Plant two within {f:link_range} and lightning joins them (shown when placing). Nightmares crossing it take damage and {static} every second. Flyers take {f:flyer_charge} {static} at once." | "Two within {f:link_range} are joined by lightning. Nightmares crossing it take damage and {static} every second; flyers take {f:flyer_charge} {static} at once." ("(shown when placing)" is a UI hint.) |
| Maelstrom | 26 | (as is) | Fine; borderline. |
| Midsummer | 26 | "A brighter beam that builds to far higher damage and also hits the nightmare behind its target. It keeps half its build-up when it switches target." | "A brighter beam that ramps far higher and also hits the nightmare behind. Keeps half its ramp when it switches." |
| Dewcatcher | 25 | "Pulses damage… Nightmares dispelled within {f:catch_radius} drop {f:catch_share} more {dew}, paid at the {rest}. Also {dew:{f:dew_per_drift}} each {drift}." | Use the same three-line shape as Wellspring (top 15 #6) so the two compare side by side. |

### 2d. Reactions (not in the top 15)

| Where | Words | Now | Rewrite |
|---|---|---|---|
| Thunderclap | 33 | "A Thunderclap hits it hard and arcs to nightmares with {damp} in range. Needs {stacks:need_damp} {damp} + 10 {static} (15 on bosses). ×12 damage, ×6 per arc, and each arc adds 1 {static}." | "Hits it for ×12 and arcs to nightmares with {damp} in range, ×6 each, adding 1 {static}. / Needs {stacks:need_damp} {damp} + 10 {static} (15 on bosses)." (Numbers were after the recipe.) |
| Ignite | 32 | "Its {spored} burns for 3 s, hurting 4 times as fast, and each second a {stack} spreads to the nightmares beside it. Needs … Uses up the {static}." | "Its {spored} burns 4 times as fast for 3 s and spreads 1 {stack} a second to nightmares beside it. / Needs {stacks:need_spored} {spored} + {stacks:need_static} {static}. Uses up the {static}." |
| Drown | 29 | "It is pulled under for 3 s and takes more damage each second. Needs … Uses up the {drowsy}. 60% slower while under (bosses 30%)." | "Pulled under for 3 s: 60% slower (bosses 30%), taking more damage each second. / Needs {stacks:need_damp} {damp} + {full} {drowsy}. Uses up the {drowsy}." (The slow was after the recipe.) |
| Smother | 28 | "While its {held} lasts, its {spored} stops hurting and swells. When its {held} ends, all of it bursts at once for double. Needs …" | "While {held} lasts its {spored} stops ticking and swells, then bursts all at once for double. / Needs {stacks:need_held} {held} + {stacks:need_spored} {spored}." |
| Lightning Rod, Shatter | 25 | (fine shape) | Keep; they are the model: effect, then "Needs …". |

### 2e. Omens, nightmares

| Where | Words | Now | Rewrite |
|---|---|---|---|
| Omen Second Path | 26 | "For the next 5 {drifts}: the Thornwall that makes the path longest crumbles at the start (full refund). Nothing can be planted there until the {rest}." | "For the next 5 {drifts}: the Thornwall that lengthens the path most crumbles at the start, full refund. Its cell stays empty until the {rest}." |
| All 27 Omens | — | Every one opens "For the next 5 {drifts}:" (5 words before the effect). | Show "5 drifts" as a chip on the Omen card and start the text at the effect: "Nightmares move 35% faster and give 40% more {dew}." Only if the UI owner agrees; the text alone is consistent and readable. |
| Giants' Walk | 23 | "… half as many nightmares, each with 2.4× health. Each one that reaches the Heartwood takes 1 more {leaf}." | Fine. |
| The Night Mare (trait) | 26 | "At the Heartwood it can't be hurt and drains {leaves}, then it runs the maze again: hurt it as much as you can on every pass." | "Drains {leaves} at the Heartwood, where it can't be hurt, then runs the maze again: hit it hard on every pass." |
| Husk (trait) | 24 | "A {dread_shell} blocks part of every hit until it breaks, and it is slow and very tough: heavy hits first, then a long path." | "Slow and very tough, with a {dread_shell}: heavy hits first, then a long path." ({dread_shell} tooltip explains the shell; Shellbound repeats the same definition too.) |

### 2f. Dream tips over 40 words (not in the top 15)

| Where | Words | Rewrite |
|---|---|---|
| Second Verse | 52 | "Any Warden but that bell; other bells count. Same {stacks} as before. Once per bell and nightmare. Never {held}, never a new status, never past {full}; {static} stops 1 short of a bolt. A bet: status Wardens before a bell." |
| Thunderstruck | 51 | "Only nightmares a Warden hit in the last 2 s. Fireflies' {heavy} forms count. Each {jump} adds 1 {static} from the Firefly, not to bosses. Once per attack; at most 1.5 s of the Firefly's damage in all. Safe." |
| Witching Bend | 49 | "Only {named_combo:thunderclap}, {named_combo:ignite}, {named_combo:mushrooming}, {named_combo:drown}. Half the usual {stacks} ({drowsy} still {full}); a {named_combo:thunderclap} this way deals half. Bosses once every 10 s. Bend: a turn with a full cell of straight path each side. Offered after 20 {reactions}." (Same order as Heavy Heart's tip: list first.) |
| Breathe It In | 46 | "Any family's statuses, {spored} too; {drowsy} only 1 more. Only stacks from a Warden's own attack count, not cards or your Calling. Never {held}, never past {full}. Safe." |
| The Walking Wood | 46 | "One-cell Wardens, Sprouts and Thornwalls; not the Sapling or Twig Walls. The route never changes. {kinships} start again. At a {rest}, swap freely. A bet: a few strong Wardens, many walls." |
| Gone to Seed | 45 | "Any family's statuses, {spored} too. Each nightmare once every 2 s. Never {held}, never past {full}; {static} stops 1 short of a bolt. A bet: needs a second status." |
| Homesick | 45 | "Each status restarts its time, at most 4 s past its last landing ({static} 2 s). Never {held} or {drowsy}. Pullers: the Puddles {calling}'s Whirlpool and Drowning Deep, {warden:rootcurl}, {warden:long_way_home}. A bet." |
| Flashover | 43 | "Half of its biggest hit on one nightmare. Once per attack. At most 3 s of the Firefly's damage. {warden:sparkler} and {warden:starburst} need another Firefly {near}. A bet." |
| Last Drop | 43 | "Runs out: wears off with time, not spent by a {reaction}. Dealt as one new hit by the Warden that added it. Each nightmare once every 6 s. Safe." |
| Nothing Wasted | 43 | "Nearest: within 2 cells. Once per hit. From another family, a {jump} deals at most 3 s of the Firefly's damage. Safe." (The {dread_shell} definition repeats its tooltip.) |
| Waymark | 42 | "Free. Placed when taken, movable at any {rest}. Its cell stays open. Flyers fly straight past. A bet: a kill zone on each leg." |
| Brushfire | 41 | "Status damage: {spored} ticks, clouds and fog; not bolts or {reactions}. Nearest: within 2 cells. Each nightmare once a second; at most 3 s of the Firefly's damage. A bet." |
| Ebb | 41 | "Only a status that timed out, never one a {reaction} spent. Once per status and nightmare. Not {held} or {drowsy}; {static} stops 1 short of a bolt. Safe." |
| Headlong | 41 | "Not from a {rest}, Auto-drift or boss {drifts}. Its {dew} is already yours: a leak costs only {leaves}. A bet: a board that takes a whole {drift} at once." |
| Sap Rising | 41 | "Support: aura Wardens, catchers, {warden:dreamcatcher}; not walls. An area attack. At most a quarter of a nightmare's health in all ({deeply_blighted} and bosses: a tenth). Safe." (Raw "Deeply Blighted" → token, as Thorny Walls uses.) |

### 2g. UI strings: tooltips over ~40 words, long buttons

Codex entries are read at rest, not mid-fight; they are listed for phones (Codex on a 380 px screen) but
rank below card and tooltip text.

| Where | Words | Now (start) | Rewrite |
|---|---|---|---|
| codex_data.gd:88 Current | 53 | "Undercurrent opens a whirlpool on the path for 3 s that links up to 6 nightmares in it: 25% of any hit on one also hits each of the others. Maelstrom's is wider…" | "A whirlpool for 3 s linking up to 6 nightmares: 25% of any hit on one hits each other. Maelstrom: wider, up to 8 at 45%, and carries {static} bolts to the others for half damage." |
| codex_data.gd:91 Ink | 52 | "An Inkcap shot on a nightmare with {spored} inks every cell of path it walks for 2 s; a nightmare standing in ink gains 1 {spored} each second. A nightmare Deliquescent inked melts…" | "Inkcap: a nightmare with {spored} it shoots inks the path it walks for 2 s. Ink gives 1 {spored} a second. Deliquescent: an inked nightmare dispelled melts into a 2-cell pool for 4 s, {spored} twice a second." |
| codex_data.gd:92 Spore-sprite | 51 | "Brood Cap hatches little sprites (up to 4 at once) that walk up the path and burst on the first nightmare they touch…" | "Up to 4 sprites at once walk up the path and burst on the first nightmare they touch: a full hit and 2 {spored} (Hatchery 3). They reveal {hidden} nightmares they bump. Every 5th Hatchery sprite is big and splits into 3." |
| codex_data.gd:95 Nightmare Kind | 46 | "What a nightmare does, shown as a badge on its card…" | Fine for the Codex. |
| codex_data.gd:90 Arc | 44 | "Two Jarlinks within 4 cells join with an arc: nightmares touching it take damage every moment and gain 1 {static} each second, and a flyer crossing it takes 3 {static} at once. A Lightning Fence's arc…" | "Two Jarlinks within 4 cells join with an arc. Nightmares touching it take damage and 1 {static} a second; a flyer crossing takes 3 {static} at once. Lightning Fence: much harder, and it catches Phantoms." |
| codex_data.gd:131 Reaction mark | 44 | "The small slash on a status's stack bar or pips…" | "The slash on a status's stack bar: past it the status is Reaction-ready. Brimming lengthens the bar but the mark stays at the same stack count, so it sits further left." |
| codex_data.gd:132 Reaction | 43 | "When a nightmare carries enough stacks of two different statuses, they set each other off…" | Fine for the Codex. |
| codex_data.gd:70 Not in this run | 41 | "A family has five branches and each run offers two of them, chosen at random (plus its Grove branch)…" | "Each run offers 2 of a family's 5 branches at random, plus its Grove branch. The rest are misty on the Remember screen; add one for {dreamlight:3}, once per family." |
| omen_director.gd:245 REWARD_RULE | 41 | "Lose no leaf in the Omen's drifts and its reward is yours in full. Each leaf lost takes a quarter…" | "No leaf lost: the full reward. Each leaf lost: −¼ of its Dew and Seeds (4 leaves: nothing). A Dream reward needs at most 1 leaf lost." |
| lesson_card.gd:216 STACK_TEXT | 41 | lesson, read paused | Fine (lesson). |
| remember_screen.gd:552 MISTY_TIP | 39 | "Each run the dream offers only some of a family's branches, at random. These weren't drawn this time: call one in for Dreamlight (once per family), or find the Borrowed Branch card…" | "Not drawn this run. Call one in for {dreamlight} (once per family) or with {card:lucid_dream}. The Heartwood may offer them next run." |
| icon_info.gd:21 Poison tooltip | 36 | "A nightmare with it takes damage every second, more per stack. Every new stack keeps the whole pile going; it wears off 5 s after the last one. At {stacks:need_spored} stacks…" | "Damage every second, more per stack. Each new stack refreshes the pile; it ends 5 s after the last. At {stacks:need_spored} stacks it can set off {reactions}." |
| codex_data.gd:17 Dreamlight shard | 37 | | "10 shards make 1 {dreamlight}. Caps per source: Dreamcatchers' shards at most {dreamlight:2} a run; other sources say theirs on their card." |
| warden_panel.gd:425 (disabled button) | 12 | "Make this the Eldest? Only one Warden can grow past rank V" | Button "Make Eldest?"; the sentence goes to its tooltip. |
| warden_panel.gd:490 sell button | 8 | "Permanent: the Sapling can't be sold or moved" | Button "Can't be sold"; rest in tooltip. |
| warden_panel.gd:471 (disabled) | 6 | "Rank %s: only the Eldest grows further" | "Rank %s · max" + tooltip. |
| warden_panel.gd:1966 | 7 | "Plant Sprout (%d) · at the next rest" | "Plant Sprout (%d)" disabled + tooltip "At the next rest". |
| warden_panel.gd:1370 | 6 | "Swap places: again in %d s" | "Swap · %d s". |
| remember_screen.gd:1016 | 7 | "Add to this run, free (Borrowed Branch)" | "Add free" + tooltip naming {card:lucid_dream}. |
| pause_menu.gd:527 / 530 | 9 / 9 | "No save yet (one is written at each rest)" / "Save copied (%d KB): paste it in a message" | "No save yet" / "Save copied" + tooltip for the rest. |
| gift_screen.gd:824 | 9 | "Keep the start where it is · route %d cells" | "Keep start · %d cells". |
| drift_panel.gd:256 | 5 | "Call drift %d early, %s" | Fine (phones already get "Call early, …"). |

---

## 3. Card shape rules (templates from the best existing cards)

Use one of these shapes. Effect and number in the first 6 words; one condition; limiter as its own
short last sentence. Target ≤ 20 words, hard cap 25.

**T1 · Flat bonus: "[Who] [verb] [N%] [condition]."**
Models: Forest Floor "Wardens {touching} an obstacle deal 20% more damage." · Rootbound "Wardens {touching}
3 or more other Wardens attack 100% faster." · Long Shadows "Wardens with range 5 or more get +2 range."
Rules: who first, then verb + number (style guide verbs: "deal N% more damage", "attack N% faster",
"+N range"; nightmares "take N% more damage"), then the condition.

**T2 · Scaling: "[Who] [verb] [N%] per [thing], up to +[cap]."**
Models: Hedge Maze "A Warden deals 5% more damage for each Thornwall {touching} it, up to +30%." · Last Leaf ·
Mixed Grove · Root Network. Rule: cap always last, always "up to +N%". Prefer "per" to "for each" (2 words
saved on ~40 cards, and the number sits closer to its unit).

**T3 · Trigger: "When [event], [result]. [Limiter]."** (window form: "For N s after [event], [result].")
Models: Hobble "When a crit lands, the nightmare is slowed 30% for 1 s." · Shattering Blow · Spillover ·
Hunt's Rush · Brushfire "For 2 s after a Firefly hits a nightmare, half the status damage it takes {jumps}…".
Rules: one event, one result. Time windows go *first* ("For 2 s after…"), never as "within 2 s" mid-sentence.
Limiter is a separate sentence in a fixed form: "Each nightmare once every N s." / "Each Warden once a
second." / "Once per attack."

**T4 · Periodic: "Every [N s / Nth hit], [who] [does what]."**
Models: Da Capo "Every 6 s, a bell's next attack happens twice in a row." · Eternal Charge · Rooted
Nightmares (after the "1 {held} for 1 s" fix).

**T5 · Evolution unlock: "[From]s can now {grow} into [To]s (cost): [one clause, ≤ 12 words]."**
Models: Quaker "…: a slam that stops sprints." · Cloudlet "…: rain clouds over any spot in range, flyers
too." · Earthshaker · Silence. Rules: one clause after the colon; numbers as fields; never a second
colon; status timing as "1 {held} for X"; the leader is "the leader". Better still, the prefix as a
header row (finding 2).

**T6 · Reaction: "[Effect with numbers]. / Needs A + B. Uses up X. / [Limits]."**
Models: Shatter "A crit or heavy hit on it deals ×4 damage, and ice shards fly into the nightmares beside
it. Needs {stacks:need_held} {held} + {stacks:need_damp} {damp}." · Lightning Rod.

**Pairs and fixed lines (already good, keep):**
- Bittersweet cost: "{named_combo:X} can go off only half as often." / "Taking it removes {card:X} from this run."
- Instant: "Now: {dew:+100}." (Dew Bowl, Sudden Insight, Burn Back).
- Omen: "For the next 5 {drifts}: [nightmares / Wardens] [change], [and / but] [second change]."
- Upgrade (II) cards: the base card's sentence word for word, plus one sentence (Hunt's Rush II, Root
  Network II, Guiding Light II): perfect for side-by-side comparison.

**Sibling shapes to unify:**
- Firefly jump cards (Brushfire, Chain of Lanterns, Flashover, Hammerfall, Sparks Fly, Thunderstruck,
  Nothing Wasted, Struck Twice): one shape, "When [who] {near} a Firefly [hits], [share] {jumps} to the
  nearest other nightmare." or the T3 window form. Now 4 shapes.
- Dewdrop cards: one who-phrase, "Dewdrops and Wardens {near} them …" (Heavy Going, Sodden; High Tide,
  Last Drop, Wash Away should match). Steeped / Topped Up / Never Quite Dry use "{touching}", "a
  Dewdrop's hit", "{near} a Dewdrop": pick one per meaning.
- Sporeling cards: "in a Sporeling's range" (Breathe It In) vs "{near} a Sporeling" (Gone to Seed, Mixed
  Company) vs "Sporelings and Wardens {near} them" (Fruiting, Parting Puff) vs "{touching} a Sporeling"
  (Pass It Round, Mycelium). If these are different reaches on purpose, keep them, but put the reach
  word in the same position.
- "most-afflicted nightmare" (Gust / Zephyr cards, Whirligig card) vs "the nightmare with the most
  statuses" (Gust, Zephyr, Whirligig Wardens): one term.
- Bell cards (Da Capo, In Time, Knell, On the Beat, Refrain, Reprise, Second Verse, Nod Off): all
  "a bell's [attack] …" shape: good, keep.

---

## 4. Length stats

Counting rule: tokens (nested too) = 1 word.

| Text kind | Count | Over limit | Average words |
|---|---|---|---|
| Dream card descriptions (all) | 378 | **37 over 25** | 18.2 |
| · regular Dream cards | 261 | 2 over 25 (61 at 21–25) | |
| · evolution-unlock cards | 117 | 35 over 25 | |
| Warden descriptions | 122 | 34 over 25 | 22.1 |
| Reactions | 10 | 8 over 25 | 37.1 |
| Omens | 27 | 1 over 25 | 15.2 |
| Bittersweet cost lines | 37 | 0 | 7.9 |
| Dream tips | 186 | 16 over 40 | 19.5 |
| Nightmare traits | 35 | 1 over 25 | 15.9 |
| Diagram captions | 21 | 0 | 14.6 |

**Longest 10 Dream card descriptions:**

| # | Card | Words |
|---|---|---|
| 1 | Tidecaller (ascension) | 46 |
| 2 | Hoarfrost (evolution) | 42 |
| 3 | Frostfern (evolution) | 41 |
| 3 | Old Mountain (ascension) | 41 |
| 5 | The Great Bell (ascension) | 40 |
| 6 | Whirligig (family) | 37 |
| 7 | Midsummer (evolution) | 36 |
| 7 | Mother Log (evolution) | 36 |
| 7 | World Root (ascension) | 36 |
| 10 | Pebbling (family) | 35 (tied with Sporemother, The Whirlwind) |

Longest regular (non-evolution) Dream cards: Afterroot 28, Momentum 28; then nine at exactly 25
(Called from Afar, Fruiting, Lingering Splash, Loose Stones, Hunt's Rush II, Refrain, Rooted Nightmares,
Shared Fever, Thousand Cuts).

---

## 5. Number mismatches seen while scanning (for the owners; not this seat's call)

| Where | Text says | Other text says |
|---|---|---|
| Briar Crown | description "takes 60% of a hit" | diagram caption "takes 25% of the strongest Warden" |
| Crossroads | description "deals 100% more damage" | diagram caption "+40%" |
| Thicket (sprout_chorus) | description "Sprouts {touching} 2 or more path cells attack 20% faster" | caption "W touches another Sprout and at least 2 distinct route cells: +30% attack speed" (also a different condition) |
| Wellspring cap | Warden description "all Wellsprings together up to {dew:260}" | Codex "Harvest and interest": "at most 130 a rest for all Wellsprings together" |
| The Great Bell | card "nightmares with {f:sets_off_static_at} or more {static} stacks" | Warden "every nightmare with {static}" |
| Poison duration | icon tooltip "wears off 5 s after the last one" (pile refresh) | lesson "Each stack lasts 5 s, so keep hitting it" |
| Tidecaller push | card "pushes it back 1 {step}" | Warden "drags it back 1 cell along the path" (same thing? say it one way) |
| Hollow Ground | description "where you cleared a Mossy Boulder…" | caption "Planted in a moved hollow" |

Raw names where tokens are expected: "Phantoms / Night Hounds" (Starling Murmuration, Wren's Nest cards),
"Soak" (Frostfern Warden), "Deeply Blighted" (Sap Rising tip), "Dreamlight" (Wild Growth tip, Heartwood
Sapling), "rest" / "drifts" (Wellspring, Heartwood Sapling).
