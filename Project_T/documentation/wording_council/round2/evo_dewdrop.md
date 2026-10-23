Numbers: 14 of 53 match a constant; 4 contradict one; 35 have no constant yet (all 35 match the paper values in evo_fixed_dewdrop.md)

# Puddles (Dewdrop) Calling evolutions: wording check (2026-10-23)

Source: uncommitted `scripts/combat/calling_paths.gd:306-375` (21 live `dw_*` rows; 11 retired rows skipped). Read-only.

## Numbers

**`puddles.gd` has not been rebuilt.** It still runs the old rows: the Stream crowd bonus (`STREAM_CROWD` / `STREAM_BONUS`,
puddles.gd:178-179, branch at :523), the pond slow and bonus (`POND_SLOW` / `POND_BONUS`, :175-177), with a pond defined as
water touching `POND_DEWDROPS` 2 (:174, but the Black Pond text says "your highest-rank Dewdrop's water"), and Riverside's
`SIDE_SPROUT_BONUS` (:181). None of the new constants exist yet (STREAM_SLOW, SPILL_*, WAVE_*, CHURN_*, MUD_GAP, LOW_TIDE_*,
OUTFLOW_*, ...). So most numbers have no constant to check. They were checked against the paper table in
`D:\Projects\logs\dream_council\evo_fixed_dewdrop.md`, and all of them match it.

Match a live constant (14): Stream 4 {steps} = `FLOW_STEPS` 4 (puddles.gd:158). Flash Flood 24 {steps} = `FLOOD_STEPS` 24
(:163), {damp} 4 {steps} = `RIPPLE_STEPS` 4 (:15), once a second = `RIPPLE_EVERY` 1.0 (:16). Riverside / Open Water 2 s =
`SIDE_SECONDS` 2.0 (:203). The 4 s / {static} 2 s room on Riverside, Open Water, Still Water and Wet Footprints =
`CALLING_LINGER_MAX` 4.0 / `CALLING_LINGER_MAX_STATIC` 2.0 (enemy_statuses.gd:1086-1087). Still Water's bosses half =
`STILL_BOSS_SHARE` 0.5 (puddles.gd:195). Deep End's sum is right (0.25 + 0.03 x 7 = 0.46).

**Mismatches (4):**
1. **Wet Footprints "For 2 s"** vs `WET_SECONDS := 3.0` (puddles.gd:216; the old code). The design says 2 s.
2-4. **"Bosses half" on Stream (tip), Long Current (tip) and Mudflats (tip)** vs `class_kit._apply_calling_slows`
   (class_kit.gd:490-491). For a boss, `top = CALLING_SLOW_MAX * 0.5` = 0.175 and `amount = min(snap5(sum), top)`. It halves
   the **cap**, not the slow. So a boss in Stream water gets the full 15%, and Mudflats' 30% gives a boss 17.5%, not 15%.
   Either the row code must halve its request before `calling_slow`, or the tips must change. **Owner: Roguelite Code.**
   (Flash Flood's and Sinking Mud's "bosses half" are timed `add_slow` calls on paper with no code yet: unchecked.)

Also, `calling_slow` **adds** the requests that rows make in one poll (class_kit.gd:466-479: "rows raise it within the cap").
On paper, Mudflats' 30% replaces Stream's 15%. If both rows call it on one nightmare, that nightmare gets 45%, capped at
35%. That also makes Stream's tip "Slows don't add" untrue for the Calling's own rows (check).

## Thick Haze

This is not a Dewdrop row. `sp_thick_haze` (calling_paths.gd:38, Sporeling, DEEPEN) is still **live**, with its old text,
although the owner sent it back to the designer for a new place (dream_council_review.md 33, rulings 2026-10-23). It should
be marked retired or held until the designer's new row arrives. It is not reworded here.

## Rows with a problem

| # | Row | Problem | Rewrite |
|---|---|---|---|
| 1 | Stream (tip) | "Slows don't add: the strongest counts" is only true for timed slows. {drowsy} and the stag aura add on top (`get_speed_multiplier`), and the Calling's own rows add within the cap (see Numbers). "Bosses are slowed half as much" is wrong in the current code (mismatch 2). | Tip: "Bosses are slowed half as much. Flyers never walk in {water}. Timed slows don't add: the strongest counts. {drowsy} still adds." (check: the helper must halve the boss slow) |
| 2 | Reed Bed | "along path beside Thornwalls and Sprouts next to it": the article is missing, and there are two "beside / next to" relations plus an unclear "it" (the water? the path?). | "From each end of a {water}, {water} spreads along path with a Thornwall or Sprout beside it, up to 12 more {steps} for each {water}." (check: it spreads from the water's ends only, per the design's "flood fill from water ends") |
| 3 | Flash Flood | "A Dewdrop's" means any form (R2.3). The boss amount is not given right after the number (rule 9), and the tip doesn't say what a second splash does (rule 2). | "A {family:dewdrop} Warden's {dew_splash} runs down its whole {water}, up to 24 {steps} each way: nightmares it reaches walk 30% slower (bosses 15%) for 2 s." Tip: "{damp} still reaches only 4 {steps}. Another splash restarts the 2 s. Each nightmare once a second." |
| 4 | Long Current (tip) | "Bosses half" after "as slow as they were" reads as halving a second time. | Tip: "Bosses keep their halved slow. Never flyers." (check, mismatch 3) |
| 5 | Backwaters | "the same Dewdrop" means any form (R2.3). "Bends back past" and "its two waters" (one Warden having two waters) are never explained. | "Where the path passes the same {family:dewdrop} Warden twice, making two {waters}, path up to 6 {steps} long between them is {water} too." |
| 6 | Mudflats | It doesn't say that 30% replaces Stream's 15%, so it reads as adding (45%). The boss amount is in the tip, not after the number (rule 9). "Mud never covers more path than your water does" doesn't say what happens when it would. | "Path between two {waters} up to 4 {steps} apart turns to mud. In {water} and on mud, nightmares walk 30% slower (bosses 15%), not 15%." Tip: "Mud isn't {water}. Mud never covers more {steps} than all your {water}: the shortest gaps turn first. Never flyers." (check: the bosses figure, mismatch 4) |
| 7 | Sinking Mud | The boss amount is in the tip (rule 9). | "Flyers crossing mud or {water} are slowed too: 30% (bosses 15%) for 2 s." Tip: none. |
| 8 | Black Pond | "Dewdrop" means any form (R2.3). "For 25%" leaves out "of what" (rule 1). "Spill" is used by Deep End and Twin Springs but never set up here. The tie rule is missing. | "The pond is your highest-{rank} {family:dewdrop} Warden's {water}. That Warden's direct hits in the pond also spill 25% of their damage onto up to 4 other nightmares there." Tip: "Damage only: no statuses. Once per attack. Ties: the higher form, then the first planted. The pond is drawn darker." (check: the tie rule is from evo_fixed_dewdrop.md) |
| 9 | Deep End | "Spill" is undefined until row 8 is fixed. "Its Dewdrop" means any form. "25%" leaves out "of what". | "The pond's spill is 25% of the damage, +3% for each {rank} of the pond's Warden (46% at {rank} VII)." |
| 10 | Breaking Wave | "From {rank} V" doesn't say whose rank. "The pond's Dewdrop" means any form. "In full" is vague. The tip doesn't put the subject first (rule 3). | "When 4 or more nightmares are in the pond and its Warden is {rank} V or higher, a wave breaks: that Warden hits each of them for full damage." Tip: "Damage only. The pond breaks at most once every 4 s, on up to 6 nightmares." |
| 11 | King Tide | "Pass the {dread_shell}" is an idiom; other text says "ignore the {dread_shell}". "Counts as 4 nightmares" doesn't say for what. "Breaking waves" is a plural of a row name. | "A boss in the pond counts as 4 nightmares for Breaking Wave. Breaking Wave ignores the {dread_shell} of every nightmare except bosses." |
| 12 | Twin Springs | "Dewdrop" appears twice and means any form. There are three referents for "it / its" ("joins it: its water ... its direct hits"). "Spill" is undefined (see row 8). The tip doesn't say which one joins. | "One other {family:dewdrop} Warden {touching} the pond's Warden joins the pond: its {water} becomes pond too, and its direct hits there spill as well." Tip: "Only one joins: the highest-{rank} one {touching}." |
| 13 | Churning Water | "2 Dewdrops" means any form. "For half" leaves out "of what". | "While 2 {family:dewdrop} Wardens share the pond, it churns every 3 s: between them, they hit up to 4 nightmares in the pond for half their damage." |
| 14 | Three Springs | "Dewdrop(s)" means any form. "Joins it" has an unclear "it". "Its hits" should be "direct hits", as in Twin Springs. "The two highest-rank" has no noun. | "A third {family:dewdrop} Warden {touching} either pond Warden joins the pond: its {water} becomes pond too and its direct hits there spill. Churns still come from the two highest-{rank} only." |
| 15 | Riverside | The noun stack reads as a garden path ("Statuses other families' Wardens touching water put on nightmares in it last..."). "+1 s to each" doesn't say each what. In the tip, "Not Dewdrops" is a fragment that means any form, and the Sprout rate limit (once a second per Sprout per nightmare, in the design) is missing. | "Statuses that other families' Wardens {touching} {water} put on nightmares in that {water} last 2 s longer. A Sprout's hit there adds 1 s to each status." Tip: "Sprouts count as another family; {family:dewdrop} Wardens don't. Each Sprout once a second per nightmare. Up to 4 s past landing in all ({static} 2 s). Never {drowsy} or {held}." (check: the rate limit) |
| 16 | Open Water | It has the same garden-path noun stack as Riverside. Its tip drops the {static} 2 s and the {drowsy} / {held} exclusions that Riverside's has, although it uses the same room. | "Statuses that other families' Wardens put on nightmares in {water} last 2 s longer, wherever the Warden stands." Tip: "Up to 4 s past landing in all ({static} 2 s). Never {drowsy} or {held}." |
| 17 | Still Water | "3 or more other Wardens" doesn't say other than what (it means other families: Sprouts count, Dewdrops don't). "Stop running down" is an idiom, and Wet Footprints and Low Tide use the same phrase (see 18-19). | "While 3 or more other-family Wardens are {touching} a {water}, statuses from other families on nightmares in it stop wearing off, up to 4 s past landing ({static} 2 s)." Tip: "Sprouts count; {family:dewdrop} Wardens don't. Never {drowsy} or {held}. Bosses' statuses wear off at half speed." |
| 18 | Wide Banks | "Its bank" is undefined: every other row says {touching} {water}. "Up to 2 cells from" should be "within N cells" (rule 7). It doesn't say which rows it changes (Support only, per the design). | "Wardens within 2 cells of a {water} count as {touching} it for Riverside and Still Water." (check: those are the only Support rows that read touching) |
| 19 | Wet Footprints | "2 s" contradicts `WET_SECONDS` 3.0 (mismatch 1). "Don't run down" is an idiom (see 17). In the tip, "the water's limit" is undefined. Because the 2 s share the 4 s room (owner ruling), the face is not always true. The tip has to say so plainly. | "For 2 s after a nightmare leaves {water}, its statuses from other families don't wear off." Tip: "These 2 s count toward the same limit: up to 4 s past landing in all ({static} 2 s)." |
| 20 | Low Tide | It doesn't follow rule 15 ("Wardens' direct hits deal N% more damage"). "The water" is a raw word where the {water} token exists. In the tip, "stops or slows its running down" is an idiom with an unclear "it". "Dew-light" is a palette name, not a player word (check). | "Other families' Wardens' direct hits deal 10% more damage for each status the {water} is keeping on the nightmare, up to +30%." Tip: "Kept: a status the {water} stops or slows from wearing off, or one past its normal time. Its time bar turns Dew-light." |
| 21 | Outflow | "From another family" should be "another family's Warden". "Deals 20% more" leaves out "damage" (rule 1). "The water is keeping" doesn't fit a nightmare that has already left the water. The tip doesn't say that it replaces Low Tide on that hit (the design says never both; stacking line, rule 16). | "After a nightmare leaves {water}, the first direct hit on it from another family's Warden deals 20% more damage for each status still kept, up to +60%." Tip: "Each nightmare once for each {water} it leaves. On that hit, it replaces Low Tide's bonus." |

No text is over 30 words and no tip is over 40. The longest are Three Springs at 28 and Still Water at 29. Rows without a
problem in their own words: none. Each row has at least one point above, though rows 4 and 7 are minor.
