# Veteran seat: Roguelite round (2026-10-24)

Corpus: corpus_cards.txt (NEW texts) and corpus_scripts_diff.txt ("+" strings). Every NEW text was checked against its
.tres and the rule code (scripts/tower/tower.gd, scripts/run/dream_state.gd, dream_hit_cards.gd, dream_role_cards.gd,
scripts/combat/firefly_lights.gd, spore_print.gd, keeping_time.gd, class_kit.gd, scripts/enemy/enemy_statuses.gd).
Read as a theorycrafter: what counts, per what, stacking, caps, bosses, Sprouts. Retired cards (bad_dreams, bright_marks,
called_shot, crosswind, dew_trail, dream_residue, encore, heavy_seed, ill_wind, long_light, long_shadows, lullaby,
many_threads, ring_dance, seed_storm, sharp_beaks, shiny_things, static_bloom, windborne_rain): noted, not reviewed.

Numbers that match code (no action): Bearing Down 4% / 10% per rank; Finishing Blow 40% / a third / rank II; Open Road
25% / 4 cells; Clean Strike 25% / 50% at tier 3+; Nowhere to Run 5% / 40%; Standing Tall 15% x3; Trophies 10 / 5 / 4% /
40%; Deep Frost 45%; Hairpin Winds 6 / 30%; Spinning Corners 35%; Patient Aim 15% / 45%; Starlit Aim +25%; Chain Bloom
x1.5; Conductive Soil 4 / 2 cells / once a second; Guiding Light 1 / 2 cells, half; Needle Point / Loose Stones every 3rd;
Loose Stones 35% x3; the three status feeders 1 stack, once a second per nightmare per Warden; Gathering Storm 25% / +200%
/ 2 s; Struck Twice 30% / 2 s; Tallest Tree 20% / 40 / 6; Lantern Alley 4 steps / 25% / 150%; Moth to Flame 4 / +50%;
Pyre 50 / 2nd / boss 3rd; Banked Fire 3rd / 4th; Constellation 3 / 2 s / 3 / 4 s; Retinue 2; Clump 3 / 3 / 4.

---

## 1. Top 10 problems (ranked)

### 1. "{full}" means two different things (Starlit Aim, Guiding Light, Guiding Light II)
- **Now:** Starlit Aim "on nightmares with a {full} status"; Guiding Light "at {full} {static}".
- **Problem:** the Codex "Full" entry (codex_data.gd:138) says "A status at its most stacks ... Brimming doubles them", and
  the dot fills at the most. The code calls a status full at **75% of its base cap**, before Brimming and the elite raise
  (enemy_statuses.gd:533-548 FULL_SHARE 0.75, base_cap; dream_role_cards.gd:608-614; firefly_lights.gd:1546). So Charge
  is "full" at 15 of 20 (bosses 23 of 30), Soak at 6 of 8, Exposure at 8 of 10 (before Exposure even works). A reader who
  trusts the Codex thinks Guiding Light needs 20 Charge, which bolts at once, so the card looks dead; with Brimming they
  think the bar doubles and it doesn't.
- **Rewrite:** either change the code to the Codex meaning, or give the 75% its own word. Card text:
  "A {family:firefly_jar} Warden's direct hit on a nightmare with 15+ {static} (bosses 23+) also {jumps} for half to every
  nightmare within 1 cell." Starlit Aim: "Heavy Wardens get +25% crit chance on nightmares with a status at 3/4 of its
  usual most or more." (check: owner/Balancing pick which side moves). Do not keep the {full} token for 75%.

### 2. Starlit Aim's tip says "Not {static} or {held}", the code counts both
- **Now:** tip "Heavy: the Warden header's Heavy tag. Not {static} or {held}. Direct hits only."
- **Problem:** the crit bonus reads `enemy.statuses.any_full()` (dream_state.gd:1900-1902) and so does the spend
  (tower.gd:3509-3511); `any_full` loops over ALL statuses including Charge and Root (enemy_statuses.gd:24, :544-548).
  Only DreamRoleCards.full_status skips Charge, and Starlit Aim doesn't use it. `spend_half` skips Root and Drowsy
  (enemy_statuses.gd:553-554), so a nightmare at 3 Root gives +25% crit forever at no cost; and when Root is the first
  full id found, nothing is spent even if Poison is also full.
- **Rewrite (if the code is right):** tip "Heavy: the Warden header's Heavy tag. {held} and {drowsy} count but are never
  used up. Direct hits only." Better: fix the code to skip Charge and Root (use full_status minus HELD), then keep the tip.

### 3. Eddy copies to one nightmare, not "ahead and behind"
- **Now:** "{family:whirligig} Wardens' hits copy half the target's statuses to the next nightmare ahead and behind. Each
  Warden once a second."
- **Problem:** `_eddy_copy` takes the nightmares on the path cells 1 step either side, sorts by distance and copies to
  `near[0]` only (tower.gd:5360-5367). Also "half the target's statuses" reads as "half of its statuses (2 of 4)"; the code
  copies every status at half its stacks, rounded up, at least 1 (tower.gd:5373). Gust/Zephyr (spread kind) don't use
  this path at all: their spread copies to every nightmare on those cells, with no once-a-second limit
  (tower.gd:5247-5250, :5309).
- **Rewrite:** "{family:whirligig} Wardens' hits copy each of the target's statuses, at half its {stacks}, to the nearest
  nightmare 1 {step} ahead or behind. Each Warden once a second." Tip: "{warden:gust} and {warden:zephyr} copy to every
  nightmare 1 {step} either side of their targets instead. Never copies {held}. Copies trigger no {reactions}. Works for:
  ..." (check the Reaction line: copy_quiet, enemy_statuses.gd:522-531).

### 4. Loose Stones never fires for the lobbing Pebbling forms
- **Now:** "Every 3rd hit from a {family:pebbling} Warden breaks into 3 stones, each hitting a nearby cell for 35% of the
  hit." Tip "Direct hits only: the stones never break again."
- **Problem:** the count is `family_original`, which skips area hits (tower.gd:3465). Cairn, Rockslide and Old Mountain hit
  only by splash (cairn.tres:27-28 splash_radius 1.0, lob, splash_share 1.0 default, so every hit goes through `_splash`
  with is_area true: tower.gd:3936, :3983-3989). The card that used to be *for* Cairn and Rockslide now does nothing on
  them. By the Codex, a splash *is* a direct hit ("A Warden's own attack landing"), so "Direct hits only" doesn't warn.
  Also "breaks into" reads as the hit being replaced; the code lands the full hit **and** adds 3 pieces.
- **Rewrite (code fix preferred: count the splash's target):** "Every 3rd direct hit from each {family:pebbling} Warden
  also drops 3 stones on nearby cells, each dealing 35% of its hit." Tip: "Single-target hits only, not splashes. Stones
  never drop more stones. Nearby: within 1 cell, corners too." (check: if the code is changed, drop "not splashes".)
  The "within 1 cell" is also loose: pieces land 0.5-1.5 cells away at random, snapped to a cell centre, so they can hit
  the target's own cell or one 2 cells off (tower.gd:5347-5351). Say "within 1.5 cells" or fix the code.

### 5. Conductive Soil's jumps are not {jumps} for any other card
- **Now:** "A {family:firefly_jar} Warden's hit on a {damp} nightmare also {jumps} to up to 4 {damp} nightmares within 2
  cells. Once a second per Warden."
- **Problem:** `_conductive_jumps` calls `hit(other, 0.5, ..., &"conducted")` directly (tower.gd:5326-5331); it never goes
  through `DreamState.note_jump` (dream_state.gd:2614), so Gathering Storm, Struck Twice and Shared Spark never see it,
  though Gathering Storm's tip says "Any card or Warden's {jump} counts" and dream_state.gd:3343 lists conductive_soil as a
  jump source for offers. The comment at dream_state.gd:2605-2606 ("chain hops ... covers Conductive Soil") is stale.
  The card also never says how much a jump deals (50%, CONDUCTIVE_SHARE tower.gd:2711), where the 2 cells are measured
  from (the hit nightmare), that the nearest go first, that area hits (Sparkler / Starburst) don't count (tower.gd:3465,
  :5305), and that jumps can't crit (NO_CRIT).
- **Rewrite:** "A {family:firefly_jar} Warden's direct hit on a nightmare with {damp} also {jumps} for half to the 4
  nearest other nightmares with {damp} within 2 cells of it. Each Warden once a second." Tip: "Not splashes. Jumps never
  jump on and never crit. Works for: ...". Code: route the jump through note_jump, or the tip must say "Counts as a
  {jump} for no other card."

### 6. Grandfather Stump: "touching" and "up to 45%" don't match
- **Now:** "{family:acorn} Wardens' speed auras grow 4% for each Warden {touching} them, up to 45%."
- **Problem:** the count is attacking Wardens inside the aura's reach (tower.gd:2495-2496 `distance <= my_reach and
  data.can_attack`), which is 1.5 cells for Elder Stump and 2.5 for Grove Heart (elder_stump.tres:26, grove_heart.tres:27),
  not {touching} (1 cell). "Up to 45%" is the aura's **total** (GRANDFATHER_MAX - base, tower.gd:2290): Elder Stump's 30%
  grows at most +15% (4 Wardens). And it doesn't add to Grove Heart's own per-Warden growth: the larger wins (`maxf`).
  Walls don't count; Sprouts do (can_attack).
- **Rewrite:** "{family:acorn} Wardens' speed auras are +4% stronger for each attacking Warden inside them, up to 45% in
  all." Tip: "Only auras that make Wardens attack faster. Doesn't add to {warden:grove_heart}'s own growth: the larger
  counts. Sprouts count; walls don't." (check the warden token id.)

### 7. "Gold dispels" counts two different ways (Moth to Flame vs Pyre / Banked Fire)
- **Now:** Moth to Flame tip "Gold dispels: nightmares a Warden dispelled on gold path this block." Pyre "a Warden with
  50+ gold dispels crits on every 2nd direct hit"; tip "Gold dispels count while the Warden stands".
- **Problem:** two counters, `gold_dispels_block` and `gold_dispels_total` (firefly_lights.gd:787-790; Pyre uses total,
  :1807). Same words, two meanings; a reader of Moth to Flame first thinks Pyre needs 50 in one block.
- **Rewrite:** Pyre / Banked Fire: "a Warden with 50+ gold dispels in all"; Moth to Flame: "your top gold-dispel Warden this
  block". Keep "Gold dispels: nightmares a Warden dispelled on gold or white path" as the one definition, then add "this
  block" or "in all" each time.

### 8. Moth to Flame: the crit doesn't wait for 4 hits; only the +50% does
- **Now:** "...saves a crit on that nightmare for your top gold-dispel Warden: +50% after 4 more direct hits."
- **Problem:** the holder's next direct hit on that nightmare always crits (firefly_lights.gd:1786-1788); the +50% is added
  only if 4+ other direct hits landed on it first (MOTH_HITS, :203, :1838-1842). Read as written, the crit is locked for 4
  hits. "+50%" also doesn't say of what (the crit deals 50% more).
- **Rewrite:** "A Firefly's direct hit on gold path saves a crit on that nightmare for your top gold-dispel Warden this
  block. Its crit deals 50% more damage if 4 other direct hits land on the nightmare first."

### 9. Host Trees promises Potency, delivers effect damage only
- **Now (calling_paths.gd:101):** "Shared Caps' Warden at each {mushroom} wears a cap: +15% {potency}. Without a damaging
  status, its direct hits on {spored} nightmares deal 15% more damage."
- **Problem (R3.3 #7, still open):** the {potency} glossary (icon_info.gd:41; codex_data.gd:136) says stronger slows,
  bigger Soak / Exposure bonus, longer Root. The code raises only effect damage tags (spore_print.gd:1478-1481
  host_potency, Reactions.is_effect) and the tip already says "Never {reaction} damage", against the Codex's "more damage
  from ... {reactions}". "Damaging status" = Poison or Charge (spore_print.gd:1469-1471), never named. Sprouts never get
  the direct-hit part (:1470), though the tip just says "Sprouts count".
- **Rewrite:** "Shared Caps' Warden at each {mushroom} wears a cap: its effect damage is 15% higher. If its status is not
  {spored} or {static}, its direct hits on nightmares with {spored} deal 15% more damage instead." Tip: "...Sprouts count
  (their {spored} damage only)."

### 10. "Toll" means two things (Codex vs Last Bell / Halfway Bell)
- **Now:** Last Bell (calling_paths.gd:271) "gives each nightmare one {toll}: the bell's damage, +7% for each {ring}...";
  Halfway Bell (:277) "also gives each nightmare one {toll}, at half Last Bell's bonus".
- **Problem:** the Codex "Toll" (codex_data.gd:81) is "Every 4th ring on a nightmare: the ring lands again at half damage."
  Last Bell's toll is a different hit: full bell damage plus the bonus, once per nightmare, not a 4th ring. A theorycrafter
  asks: does Last Bell's toll reset the 4-ring count, feed Crescendo, count toward Allegro's once a second? The text can't
  say, because it reuses the word. Same for Codex "Ring": "A hit from a bell" (:82), while Accompaniment's tip says a
  joined Warden's hit rings (R3.3 #7, still open), and Codex "Repeat" "lands again on that nightmare" (:85) while Coda
  repeats "on any nightmare".
- **Rewrite:** give Last Bell's hit its own name ("a closing {toll}") and list it in the Toll entry: "Toll: every 4th ring
  on a nightmare lands again at half damage. Some evolutions add other Tolls; each says how much." Codex Ring: "A hit from
  a bell, or from a Warden that joined one, on a nightmare." Repeat: "...lands again, often at half damage".

---

## 2. Every other flagged string

| Where | Now | Problem | Rewrite |
|---|---|---|---|
| carried_on_the_wind.tres:9 | "{family:whirligig} Wardens copy all of a status's {stacks} instead of half." | Whirligig Wardens don't copy unless Gust / Zephyr or Eddy; offered with only `requires whirligig` (:14), so it can do nothing. "a status's" vs every status. | "{family:whirligig} Wardens' copies take every {stack} of each status, not half." Tip: "Works for: {warden:gust}, {warden:zephyr}, or {card:eddy}." (check gating) |
| chain_bloom.tres:9 | "An Area Warden's splash on a nightmare with 2 or more statuses spreads half again as wide." | Only landing splashes (projectile_landed, tower.gd:3905-3907), not the Area role's spreads, beams-of-light, patrols, cones, rain or Sparkler bursts (Sparkler returns first, :3893-3895), yet the gate is the Area role (warden_roles.gd:21-23, :40-41). "On a nightmare" = the aimed target. "Half again" is an idiom. | "A splash that lands on a nightmare with 2+ statuses is 50% wider." Tip: "Splashes only: lobs, puffs and other landing attacks. Safe." |
| charged_feathers.tres:9 / pollen_beaks.tres:9 | "Each hit from a {family:nestling} Warden adds 1 {stack} of {static}." | "Each hit" vs the tip's once a second per nightmare: the cap belongs on the card, it is the whole rate. | "A {family:nestling} Warden's direct hits add 1 {stack} of {static}. Each nightmare once a second for each Warden." Tip keeps Works for. |
| resonance.tres:9 | "{family:bellflower} Wardens' hits add 1 {stack} of {static}." | Same. Also says nothing of the Reaction pool (code: no share, tower.gd:2703); fine to leave. | "{family:bellflower} Wardens' direct hits add 1 {stack} of {static}. Each nightmare once a second for each Warden." |
| needle_point.tres:9 | "Every 3rd hit from a {family:nestling} Warden ignores the {dread_shell}." | Per Warden or across the family? The count is each Warden's own original single-target hits, on any nightmare (tower.gd:2714, :3466-3470), so the 3rd can land on an unshelled one and be wasted. No tip. | "Each {family:nestling} Warden's every 3rd direct hit ignores the {dread_shell}." Tip: "Counts every hit, shelled or not. Not splashes." |
| conductive_soil.tres:10 | "Every nightmare it {jumps} to loses its {damp}." | "it" = the card or the Warden (rule 13). | "Every nightmare a {jump} reaches loses its {damp}." |
| deep_frost.tres:9 | "{family:dewdrop} Wardens' hits deal 45% more damage to nightmares with {held}." | "hits" vs every sibling's "direct hits" (rule 14/15). Also it **adds** to the other on-hit cards (dream_state.gd:4810-4836, `bonus +=`), while dream_hit_cards multiply: no card says which. | "{family:dewdrop} Wardens' direct hits deal 45% more damage to nightmares with {held}." |
| deep_frost.tres:17 | "Any {held}, from any Warden." | Fine. | (keep) |
| eddy.tres:16 | "Never copies {held}, sleep or {caught}." | "sleep" raw word for {asleep}; sleep and Caught aren't statuses, so they never copy anyway (tower.gd:5370). {drowsy} does copy. Charge is copied one short of its bolt (enemy_statuses.gd:523-524), unsaid. | "Never copies {held}. {static} stops 1 short of its bolt." |
| grandfather_stump.tres:17 | "Only auras that make Wardens attack faster, not damage auras." | Fine; see #6 for the main line. | (keep) |
| guiding_light*.tres:9 | "...also {jumps} for half to every nightmare within 1 cell." | Bosses take half of every Firefly jump (firefly_lights.gd:2642-2643), unsaid; "every" has a per-event cap (EVENT_MAX, :2592). | Add to tip: "Bosses take half." (check EVENT_MAX value) |
| loose_stones.tres:18 | "Nearby: within 1 cell, corners too." | See #4: pieces land up to 1.5 cells out, snapped. | "Nearby: within 1.5 cells." or fix code. |
| starlit_aim.tres:10 | "A crit uses up half of that status's {stacks}." | "that status" when two are full: the first found (active_ids order), not chosen. Rounded up. Root / Drowsy never spent (see #2). | "A crit uses up half (rounded up) of one full status's {stacks}." |
| starlit_aim.tres:9 | "Heavy Wardens get +25% crit chance on nightmares with a {full} status." | Header tag "Heavy" vs Codex "Heavy Warden" examples (codex_data.gd:89) that are by attack speed; the code reads attack_data.heavy only. Tip covers it. | (see #1) |
| struck_twice.tres:9 | "...the next hit on it from {family:firefly_jar} Wardens or Wardens {near} them deals 30% more damage." | "next hit": tip clarifies Direct hits only; ok. Conductive Soil jumps don't arm it (see #5). | (keep; fix #5) |
| gathering_storm.tres:10 | "Bosses take half." | Half of what: the bonus or the jump? Code halves the whole jump on bosses (firefly_lights.gd:2642-2643). | "Bosses take half of each {jump}." |
| gathering_storm.tres:10 / struck_twice.tres:10 | "Any card or Warden's {jump} counts, except a Calling evolution's." | Not true for Conductive Soil (see #5). | Fix code, or add "and Conductive Soil's". |
| unfettered.tres:9 | "Calling hits deal the Warden's full damage, even from Wardens that attack less than once a second." | The cap is attacks/s x the output's clock (class_kit.gd:408-421): 3 s for churn / Midnight, 4 s for Breaking Wave, so "less than once a second" is wrong for those rows; per-attack rows have no cap at all. The base free hit and On the Beat are never lifted (class_kit.gd:410-411, :445), unsaid. | "Calling hits are never cut for slow Wardens: they always deal the Warden's full damage." Tip: "Not the plain {free_hit} or {card:on_the_beat}. Each still comes only as often as its row allows. Bosses still take less. The x4 card cap still applies." |
| the_tallest_tree.tres:9 | "...spends up to 6 of its own hits' worth." | OK now; "of its hits" in "up to 40 of its hits" means "40 times its hit", not the last 40 hits. | "...stored damage, up to 40 times its own hit. Each of its attacks adds up to 6 times its own hit." |
| clean_strike.tres:9-10 | (only "damage" added) | Owner 2026-10-24 ruled new conditions for Clean Strike (dream_council_review.md 33, l.3164); code (dream_hit_cards.gd:229-237) and text are unchanged. "Walls and Sprouts never count": their statuses are ignored, and their hits get no bonus; say both. Each status keeps one source, the last to add it (check). | "Walls' and Sprouts' statuses are ignored, and their hits get no bonus. ..." Flag the owner ruling to Roguelite Code. |
| trophies.tres:9 | "Each {drift} a Warden {dispels} 10 nightmares, its direct hits deal 4% more damage for the rest of the run, up to +40%." | It's kept by cell (dream_hit_cards.gd:373), so moving a Warden loses it too; only "sold" is in the tip. Dispels by direct hits only (:369). | Tip: "...Kept when it grows; lost if moved or sold. Direct-hit dispels only." (check move behaviour) |
| open_road.tres:10 | "Flyers don't count." | True to code (dream_hit_cards.gd:136 `not is_flying()`), but the Calling rows now say "Flyers over the path count; the Phantom never". Two rules for flyers side by side. | "No flyers, even those over the path." |
| hairpin_winds.tres:17 | "Works for: ... wrapped in a tight bend. A bet: needs the path folded around them." | Fine. | (keep) |
| afterroot.tres:16 | "Works for: Wardens that add {held}, with a second Warden." | Fine. | (keep) |
| patient_aim.tres:16 | "Works for: Wardens that attack slowly." | Fine. Code counts time since its last attack (tower.gd:2661): every Warden gets some. | (keep) |
| calling_paths.gd:104 Host Grove | "While 3+ other families' Wardens wear caps" | Unchanged, but reads "Wardens of 3 families"; code counts 3 capped Wardens (spore_print.gd:1454, capped_count). | "While 3+ Wardens of other families wear caps". |
| calling_paths.gd:155 Lantern Alley | "...within 4 {steps} of its last takes a {flare}: 25% of the Firefly's damage per streak glow" | "its last" = its last glow (now parses). "the Firefly" = the glow's own Firefly. OK; per-streak-glow fine. | "...a glow within 4 {steps} of its last glow takes a {flare} from that glow's Firefly: 25% of its damage per glow in the streak, up to 150%." |
| calling_paths.gd:32 etc. | "Flyers over the path count; the Phantom never." | "the Phantom" names one nightmare (dandelion_seed.tres:9), right, but the house rule bans "Phantoms" for flyers; fine here because it is the name. Open Road contradicts (above). | (keep) |
| calling_paths.gd:302 Accompaniment tip | "A joined Warden's hit rings the nightmare, once a second, Sprouts too." | Codex Ring says only bells ring (codex_data.gd:82): see #10. | Fix the Codex entry. |
| calling_paths.gd:313 Coda | "...has its next hit within 4 s, on any nightmare, repeat at half damage." | Codex Repeat says "on that nightmare" (codex_data.gd:85). | Fix the Codex entry. |
| callings.gd:30 | "A crit this Calling saves or forces counts as a crit for nothing else." | Good, one line for all rows. "for nothing else" = for no other card. | "...counts as a crit for no other card." |
| dream_reaction_cards.gd:203 | "Reactions triggered: %d this run (you: %d)" | Reads as "5 Reactions have been triggered". :200 uses "(you: %d)", :204 "(yours: %d)". | "Needs %d Reactions triggered this run (you: %d)"; one of "you" / "yours" everywhere. |
| dream_hit_cards.gd:445 | "The Tallest Tree: %d stored damage" | Fine (R6 done). | (keep) |

---

## 3. Patterns

- **Card says "hit", code counts single-target only.** Loose Stones, Needle Point, Conductive Soil count `family_original`
  (no area hits); Charged Feathers / Pollen Beaks / Thunder Chimes count area hits too. Fix: "direct hits" = Codex meaning
  everywhere, and add "Not splashes." where area hits are skipped.
- **Rate limits in the tip, not the card.** The once-a-second cap is the card's real rate (feeders, Eddy, Conductive Soil):
  it belongs in the main line ("Each nightmare once a second for each Warden").
- **Per Warden or per family?** "Every 3rd hit from a family Warden" hides that each Warden counts its own. Fix: "Each
  X Warden's every 3rd direct hit".
- **Keyword reused with a new meaning.** {full} (75%), Toll (Last Bell), gold dispels (block vs all), Potency (damage only),
  Ring (joined Wardens). Fix: one meaning per keyword, or a new word.
- **Stacking unsaid.** Hit cards multiply (dream_hit_cards.gd:122-158), on-hit cards like Deep Frost add (dream_state.gd:4810-),
  both inside the x4 cap. Only Struck Twice says it. Fix: the Card bonuses Codex entry (rule 16) states it once; tips that
  differ say so.
- **Boss shares missing on jump cards.** Every Firefly jump halves on bosses; Guiding Light doesn't say it, Gathering
  Storm says "half" with no noun. Fix: "Bosses take half of each {jump}."
- **Owner rulings not yet in the text.** Clean Strike (and Solitude, The Old Ones, Monoculture: not in this corpus) still
  carry the old conditions.

## 4. Conventions (fixed phrasings)

| Idea | Use |
|---|---|
| Who counts | "{family:x} Wardens' direct hits ..." / "Each {family:x} Warden's every 3rd direct hit ..." |
| Area hits skipped | "Not splashes." (tip) |
| Rate | "Each nightmare once a second for each Warden." / "Each Warden once a second." (main line) |
| Status threshold | a number: "15+ {static}"; {full} only for the most stacks, as the Codex says |
| Status copy | "copies each status at half its {stacks}" (never "half the statuses") |
| Copy target | "the nearest nightmare 1 {step} ahead or behind" vs "every nightmare 1 {step} either side" |
| Jump size | "{jumps} for half" / "for 50% of the hit": always give it |
| Jump origin | "within N cells of it" (the hit nightmare) vs "of the Warden" |
| Extra effect | "also" ("also drops 3 stones"), never "breaks into" when the hit still lands |
| Totals | "up to N% in all" for a total, "up to +N%" for a bonus |
| Boss share | "Bosses take half of each {jump}" / "(bosses N%)" |
| Sprouts / walls | "Sprouts count; walls don't." Sporeling lines only for Warden counts (owner 2026-10-24) |
| Lasting counters | "this block" / "in all" after every count word (gold dispels, dispels) |
| Needs lines | "Needs N ... this run (you: M)" |

## 5. What already works

- The hit-card shape (rule 15) is now on all 8 hit cards with "damage", and "Direct hits only." is one wording.
- Family tokens replaced branch names cleanly; every "Works for:" tip now names families, not single forms.
- Costs are concrete ("Taking it removes {card:pollen_beaks} from this run"; "Every nightmare it jumps to loses its {damp}").
- Calling rows: Steady Beat / Last Bell no longer use {tolls} as a verb; "stretch of {water}" is used throughout; Toadstool
  Throne and Constellation now read once; Retinue's "At most 2 other Wardens" matches RETINUE_MAX 2.
- "Flyers over the path count; the Phantom never." is a precise, testable flyer rule (on_route, enemy.gd:2301-2302).
