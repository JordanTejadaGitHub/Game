# Veteran seat: gap round (2026-10-23)

Read as a theorycrafter would: stacks? per what? how often? bosses and flyers? Every number below was checked against
the .tres or the script. Default perk style is HADES (meta_run.gd:155), so for perks with a `sidegrade_description`
that text is what players see (unlock_data.gd:71-74). File:line refers to D:\Projects\Game\Project_T.

## Fact mismatches (text vs data/code)

| # | Where | Text says | Code says |
|---|---|---|---|
| M1 | callings.gd:23 (Pebbling "Lodged Stone") | stone lodges, next hit from another kind knocks it into the nightmare behind | **Nothing implements it.** No hook in callings.gd (after_hit:114 handles only nestling); no "lodge" anywhere in scripts/. A Pebbling first pick gets a Calling that does nothing (check with Roguelite Code). |
| M2 | resource/meta/grove/memory_moon_moth.tres | "Reveals every Lurker" | Reveals Hidden nightmares in its range only: Marking Wardens reveal what they have in range (resource/enemy/script/enemy_data.gd:83-84). Not "every". "Lurker" is one enemy; the status is {hidden} (icon_info.gd:29). |
| M3 | memory_moon_moth.tres | "Wardens in range attack from further away" | +1 range for Wardens within 3 cells (tower/moon_moth.tres range_aura_radius 3.0), not its 6-cell range. |
| M4 | resource/reaction/crowned/nightbloom.tres | "Triggered by Mushrooming on an {asleep} nightmare" | Fires at **full {drowsy}** (reactions.gd:1158 `stacks(DROWSY) >= normal_cap`), same trigger Fever Dream words as "{full} {drowsy}". The cloud lasts 4 s (NIGHTBLOOM_TIME, reactions.gd:146); "doesn't run out" is only while inside; bosses keep full Drowsy but never sleep (crowned_ground.gd:7-8, 147-150). |
| M5 | crowned/tempest.tres | "Needs 6 {spored} on a Thunderclap" | Also fires from Ignite's numbers: Soaked + 8 Charged + 12 Spored on a Warden's own landing is a Tempest at 8 Charged, not 10 (reactions.gd:324-330, 995). Never a boss that way. |
| M6 | crowned/still_pool.tres | "(bosses are slowed 30% inside)" | Also every nightmare that can't be Held is slowed instead (crowned_ground.gd:95). |
| M7 | crowned/changeling.tres | "Never bosses." | Also never flyers, leaping, dragged, Rooted or sleepwalking partners; 3 cells is *route* cells ahead on its own path (reactions.gd:149-153, 1381-1395). |
| M8 | crowned/fever_dream.tres | "It falls {asleep} for 2 s" | Not if it is a boss (reactions.gd:601). Boss neighbours' Drowsy capped at 12 (reactions.gd:121, 614). |
| M9 | crowned/fairy_circle.tres | "gets 2 {spored} and {damp}" | 1 {damp} (crowned_ground.gd:172). Rings go on path cells among the 8 around it (reactions.gd:1189-1195). |
| M10 | callings.gd:21 (Acorn "Volley") | "Every 5th acorn, all Wardens next to the {warden:acorn}" | Every 5th attack of **any Acorn-line aura Warden** (Acorn, Elder Stump, Grove Heart, Grandmother Oak), and every attacking Warden **within its aura reach**, not "next to" (callings.gd:203-222). |
| M11 | callings.gd:25 (Whirligig "Tailwind") | "shots fly on to a second nightmare" | At 60% of the shot, to the nearest nightmare within 2 cells of where it landed (callings.gd:46-47, 285-296). Numbers missing. |
| M12 | callings.gd:33 (Bellflower small print) | "After a {toll} the rings start over" | Start over at 0, while new nightmares start at 2 (keeping_time.gd:13-14). "Start over" reads as "back to 2". |
| M13 | callings.gd:31 (Sporeling small print) | "40 at most" | Over 40 the oldest goes, not "no more grow" (spore_print.gd:15). |
| M14 | callings.gd:30 (Firefly small print) | (silent) | Bosses take half of any fork; another family's fork is capped at 3 s of the lighting Firefly's damage (firefly_lights.gd:27-28). |
| M15 | grove/wider_roots.tres | "Adding another {branch} costs 4 {dreamlight}." | A downside: normal call-back is 3 (dream_state.gd:1257 vs 1425), and only for that first family. Reads as a perk. |
| M16 | grove/early_bloom.tres (sidegrade) | drift 25 pick "shows one fewer {family}" | Never below 2 (family_pick_screen.gd:158): without Wider Choice carried the cost is nothing. |
| M17 | grove/kindling.tres (sidegrade) | "your first {dream} offers only 2 cards" | Overrides Wider Dreams' 4 too (dream_state.gd:3390-3391). |
| M18 | grove/leaf_or_dew.tres | "trade up to 3 {leaves}" | Always keeps at least 1 leaf; Dew side never below 0 (meta_run.gd:116-122). |

## 1. Top 10 problems

1. **callings.gd:23 Lodged Stone** — text for a rule with no code (M1). Hide the Pebbling Calling or build it; don't ship the line. (check)
2. **The Crowned Reaction rules are nowhere in player text.** Glossary (codex_data.gd:135) says only "a stronger Reaction ... third status". Players can't tell it replaces the base, shares its cooldown, counts as 2 chain links, or that a late crown is once per nightmare (bosses once per 25% health) and each kind once every 6 s on the field (reactions.gd:108-111, 189-197). Rewrite: "A stronger Reaction that replaces its base one when the nightmare also carries a third status. It shares the base's cooldown and counts as 2 links in a {chain}."
3. **nightbloom.tres** — wrong trigger and no duration (M4). Rewrite: "The spore cloud glows violet for 4 s: nightmares {asleep} inside don't wake from hits, and their sleep doesn't run out while inside (bosses: their {drowsy} stays {full}). Triggered by {combo:mushrooming} on a nightmare at {full} {drowsy}."
4. **memory_moon_moth.tres** — "every Lurker", "in range" (M2, M3). Rewrite: "Grows the first time you dispel the Moth Queen. After that it can be your reward for dispelling that boss. Reveals {hidden} nightmares in its range, and Wardens within 3 cells get +1 range."
5. **callings.gd:21 Volley** — wrong group and wrong trigger (M10). Rewrite: "Every 5th attack of an Acorn-line Warden makes every Warden in its aura attack its target at once."
6. **tempest.tres** — trigger incomplete, cooldown worded as small print (M5). Rewrite: "Each arc triggers {combo:ignite} on nightmares with {spored}, and Ignite's spreading spores also spread {static}, so more Thunderclaps follow. Triggered by a {combo:thunderclap} on a nightmare with 6 {spored}, or by {combo:ignite} on a {soaked} nightmare. Not again on the same nightmare for 2 s." (check token for Soaked)
7. **heartwoods_crown.tres** "Every other {node} is Grown." — reads as "every second node". It is a requirement (heartwood_memory.gd:437). Rewrite: "Needs every other {node} fully Grown. Adds a sixth {perk} slot: carry 6 {perks} into a run."
8. **callings.gd:25 Tailwind** — no numbers (M11). Rewrite: "Attacks that pass through a {warden:whirligig}'s range go further: a shot flies on to the nearest nightmare within 2 cells for 60% damage, and pulses and splashes spread 1 cell wider."
9. **wider_roots.tres** — cost hidden as a feature (M15). Rewrite: "While carried: your first {family} offers 3 {branches} instead of 2. Costs: adding another {branch} of it costs 4 {dreamlight} instead of 3."
10. **Crowned boss/flyer lines are inconsistent**: Avalanche "(bosses: slowed only)", Still Pool "(bosses are slowed 30% inside)", Changeling "Never bosses.", Starfall/Prismstorm/Wide Awake/Fairy Circle say nothing, Fever Dream silent though it never sleeps a boss (M6-M8). Use one closing sentence: "Bosses: ...". Fever Dream: "...Bosses don't fall asleep." Still Pool: "Bosses, and nightmares that can't be {held}, are slowed 30% inside instead."

## 2. Other flagged strings

| Where | Now | Problem | Rewrite |
|---|---|---|---|
| crowned/fairy_circle.tres | "...gets 2 {spored} and {damp}." | Damp count missing (M9); "around it" vague | "Mushroom rings sprout on the path cells around it (up to 8) for 6 s. The first nightmare on each ring gets 2 {spored} and 1 {damp}." |
| crowned/changeling.tres | "within 3 cells ... Never bosses." | Distance is along the path; flyers excluded (M7) | "It trades places with the nightmare furthest ahead of it within 3 {steps} of its path, then turns and walks back. Never with bosses or flyers." |
| crowned/fever_dream.tres | "the nightmares beside it" | "beside" = within 1 cell; boss rule missing | "...nightmares within 1 cell get 3 {spored} and 2 {drowsy}. A boss doesn't fall asleep." |
| crowned/starfall.tres | "takes a crit for half the hit" | Half of which hit? | "...takes a crit for half the Pinned hit's damage." |
| crowned/wide_awake.tres | "attacks 40% faster" | Additive with Dream speed? It sits outside the Dream cap (reactions.gd:156) | "...attacks 40% faster for 3 s (on top of the Dream limit)." (check owner wants it said) |
| crowned/avalanche.tres | "Triggered by a {combo:shatter} from a lobbed stone" | Fine, but it is the one Crowned without a third status: the glossary contradicts it | Glossary: "...or, for Avalanche, a Shatter from a lobbed stone." |
| crowned/prismstorm.tres | "each nightmare they hit with 8 {static}" | OK; "8" vs Thunderclap's 10/15 — say "at once, even below a Thunderclap's need"? | Keep; optional "...triggers its bolt at once." |
| callings.gd:17 Spore Print | "takes a {dose}: 3 {stacks}" | Fine | — |
| callings.gd:18 Lantern Light | "half that hit {jumps}" | For a tick or cloud dispel (allowed by :30) "that hit" is undefined | "half the dispelling damage {jumps}..." (check what a tick dispel forks) |
| callings.gd:30 | (Firefly small print) | Boss half, cross-family cap missing (M14) | append "Bosses take half. Another family's {jump} deals at most 3 s of the Firefly's damage." |
| callings.gd:31 | "40 at most. ... so it is weak against flyers" | Oldest replaced (M13); "weak against flyers" is advice (no hand-holding) | "...40 at most: a new one replaces the oldest. Flyers pass over them." |
| callings.gd:32 | "Dewdrops hit nightmares with {damp} harder." | How much harder? (check number) | "Dewdrops deal X% more to nightmares with {damp}." |
| callings.gd:33 | "After a {toll} the rings start over" | 0 or 2? (M12) | "After a {toll} the rings go back to 0." |
| callings.gd:22 Perches | "its hit adds that Warden's status" | How many stacks? | (check) "...adds 1 stack of that Warden's status." |
| callings.gd:24 Anvil | "Every Warden in range turns to a nightmare with {held}" | In whose range? Overridden by a chosen target mode (callings.gd:190-192) | "Every Warden aims first at a {held} nightmare in its range (unless you set its target), and its hits on one add twice as many {stacks} (not {held})." |
| grove/second_thoughts.tres | "Always: adds the {card:wandering_mind} card." | "Always" vs "While carried" — say why | "Once planted, carried or not: adds the {card:wandering_mind} card." |
| grove/rested_roots.tres | "+10% {rest} bonus per level" | % of the bonus, multiplicative (drift_director.gd:959) | "While carried: the {rest} bonus is 10% bigger per level, up to 20%." |
| grove/rich_dew.tres | "+5% {dew} from every {drift}" | Is it pot only, or kills/rest? Pot only (drift_director.gd:785) | "While carried: each {drift}'s {dew} is 5% bigger per level, up to 15%." |
| grove/seed_pouch.tres | "+10% {seeds} from every run" | Stacks additively with Blight's +10%/level (meta_run.gd:368, 461) | Keep; fine. |
| grove/deep_taproot.tres | description "up to +3", sidegrade "up to +2" | Two texts, mode-dependent; fine as built, but Codex/wiki screenshots will disagree | Note only. |
| grove/leaf_or_dew.tres | "trade up to 3 {leaves}" | Minimum leaf / Dew floor (M18) | "...trade up to 3 {leaves} (you keep at least 1) for 30 {dew} each, or pay 30 {dew} for each extra {leaf}." |
| grove/early_bloom.tres (sidegrade) | "shows one fewer {family}" | Never below 2 (M16) | "...shows one fewer {family} (never fewer than 2)." |
| grove/kindling.tres (sidegrade) | "your first {dream} offers only 2 cards" | Also beats Wider Dreams (M17) | "...your first {dream} offers only 2 cards, whatever else adds cards." |
| grove/chosen_hunt.tres | "when an {act} begins, choose its boss from three" | Act 4 is a choice of how the Hollow Oak wakes, not of boss | "While carried: when an {act} begins, choose its boss from three (act 4: how the Hollow Oak wakes)." |
| grove/memory_pond_keeper.tres | "pulls the nightmare furthest along the path back to its pond" | Bosses only 2 cells (pond_keeper.tres pull_boss_tiles 2; tower.gd:5318); no rate | "...Every 4 s its tongue pulls the nightmare furthest along the path back to its pond (bosses: 2 cells)." |
| grove/memory_white_stag.tres | "slower and take more damage" | Numbers exist (15%/15%) | "...Nightmares in its range are 15% slower and take 15% more damage." |
| grove/bellflower_ascension.tres | "with 4 or more: its bolt strikes for half damage" | "4 or more" what? {static} named earlier but sentence order hides it | "...and every nightmare with 4 or more {static} has its bolt struck at once, for half damage." (check) |
| grove/acorn_ascension.tres | "it earns {dew} every {drift}" | How much? | (check number) |
| grove/venom.tres vs seeping.tres | "deal double damage" / "more damage for each status" | Additive with each other? | (check) say "x2" vs "+X% per status" with numbers |
| grove/full_moon.tres | "for {critical_hits} with statuses and teamwork" | "teamwork" has no defined meaning | "...for {critical_hits} on nightmares with statuses: ..." |
| support_log.gd:179 | "Adds %d path tiles" | "tiles" is an old term | "Adds %d {steps} of path" |
| buff_sources.gd:77 | "{Kinship} Dreams %s damage" | Ungrammatical | "{Kinship} Dream cards: %s damage" |
| buff_sources.gd:133 | "Cold lantern %s attack speed" | Lower-case name, unexplained source | "Cold Lantern: %s attack speed" |
| kinships.gd:859 | "Kindred: the %s family +%d%%" | +% of what? | "Kindred: %s family +%d%% damage" (check stat) |

## 3. Patterns

- **Boss/flyer clause missing or placed differently in every Crowned text.** Fix: always end with "Bosses: ..." (and "Flyers: ..." when it differs).
- **"Near/beside/next to/around it" without a number.** Fix: "within N cells" or "within N {steps} of path".
- **Durations omitted on ground effects** (Nightbloom 4 s). Fix: every lingering effect says "for N s".
- **"Half the hit / that hit"** undefined for ticks, clouds, crits. Fix: name the hit ("the Pinned hit", "the dispelling damage").
- **Perk costs written as features** (Wider Roots). Fix: every downside sits after "Costs:".
- **"+X% thing" ambiguous between multiplier and points.** Fix: "N% bigger" for multipliers.
- **Calling rules summarised away**: the Callings without small print (Acorn, Nestling, Pebbling, Rootling, Whirligig) drop the numbers. Fix: give them DETAILS rows like the four starters.

## Conventions (fixed phrasings to use everywhere)

- Trigger line: "Triggered by {combo:X} on a nightmare with N {status}." Trigger last, effect first.
- Full Drowsy: always "at {full} {drowsy}", never "{asleep}" as a trigger.
- Distance: "within N cells" (straight line) / "within N {steps}" (along the path). Never "nearby", "beside", "next to".
- Repeat limits: "Not again on the same nightmare for N s." / "Once per nightmare." / "At most once a second."
- Bosses: one final sentence, "Bosses: <what changes>." or "Never bosses."
- Perks: "While carried: <effect>. Costs: <downside>." Planted-only effects: "Once planted, carried or not: ...". Levels: "per level, up to <max>".
- Multipliers: "deals N% more", "is N% bigger"; doubling: "deals double"; additive stacking stated once in the glossary.
- Shares: "for N% of the hit" (never "half the hit" without naming the hit).

## 4. What already works

- Crowned numbers match code: Avalanche 4 s / 30% / 0.5 s / 4, Starfall 3 cells / half, Still Pool 5 s / 1 s / 30%, Wide Awake 3 cells / 40% / 3 s, Fairy Circle 6 s, Fever Dream 2 s / 3 / 2, Changeling 3.
- Grove perk numbers and level caps match the data (Morning Stores 20x3, Rich Dew 5%x3, Rested Roots 10%x2, Second Thoughts 3, Omen Reader 2->3, Wider Dreams 3->4, Leaf or Dew 30 per leaf).
- "While carried:" prefix is consistent and answers the theorycrafter's first question.
- Starter Callings' small print (Sporeling, Firefly, Dewdrop, Bellflower) answers who counts, distances and rates; the other five should copy it.
- Family nodes' "is a choice at {family_picks} from your first run" vs "can now appear" is a clean, correct split.
