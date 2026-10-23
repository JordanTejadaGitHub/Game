Numbers: 59 of 59 match (no mismatch)

# Wording review: Spore Print (Sporeling) Calling evolutions, rebuilt 2026-10-23

Source: uncommitted `scripts/combat/calling_paths.gd:29-95` (21 live rows; 9 retired rows skipped) against
`scripts/combat/spore_print.gd` (EVO_* block :110-194, code :305-1330, :1462-1496) and `class_kit.gd`. Read-only;
nothing run. Tokens checked against `scripts/ui/icon_info.gd` TERMS: {sprout}, {final_form}, {flyer}, {warden},
{nightmare}, {drift}, {rest}, {rank} are also auto-linked as plain words (`status_links.gd:108-118`), so raw "Sprout",
"final form", "flyers" are fine. {held} renders "Root" (`icon_info.gd:24`), matching `_stackable` (never HELD).

## (a) Numbers vs constants (all match)

| Row | Number in text / tip | Constant |
|---|---|---|
| Windblown | 3 steps; +1 per dose; up to 6 | SEED_STEPS 3 (:111); DOSE + taken (:732); GROWS_MAX 6 (:29) |
| Drifting Spores | 3 steps; 1 per 2 steps; 40 to 80 | SEED_STEPS 3; route/4 points (:428); DRIFT_MAX_LOW 40, DRIFT_MAX_HIGH 80 (:113-114) |
| Spore Season | 15; 1%; +60%; bosses +30% | SEASON_AT 15, SEASON_PER_STEP 0.01, SEASON_MAX 0.60, SEASON_BOSS_MAX 0.30 (:119-122) |
| Thick Haze | 1 s; 10 steps; +30% bosses; half | HAZE_SECONDS 1.0, HAZE_EVERY_POINTS 20 (=10 steps), SEASON_BOSS_MAX, HAZE_BOSS 0.5 (:127-129) |
| Fairy Path | 10 s | FAIRY_EVERY 10.0 (:132) |
| Deathcap | 2 s; once a second; half | DEATHCAP_SECONDS 2.0, DEATHCAP_EVERY 1.0, DEATHCAP_BOSS 0.5 (:134-136) |
| Rot Ground | 2 s; once a second; half | same (shared via `_deathcap`, :940-957) |
| Clump | 4; 3 steps; 3 Wardens; once a second; half | CLUMP_MAX 4, CLUMP_STEPS 3, CLUMP_WARDENS 3 (:142-144); `_focus_take` limit 1 (:1024); FOCUS_BOSS 0.5 |
| Trampled Ground | III+; 2; half; 2 a second | TRAMPLE_RANK 3, TRAMPLE_HITS 2, TRAMPLE_SECOND 0.5 (:148-150) |
| Pile-On | 2 steps; III+; 2 a second; half | PILE_POINTS 4 (=2 steps), PILE_RANK 3 (:154-155); `_focus_take` (:1107) |
| Trodden Path | step just before/after; 1 a second | TRODDEN_POINTS 2 (=1 step), TRODDEN_EVERY 1.0 (:159-160) |
| Toadstool Throne | up to 4 | CLUMP_MAX 4 |
| Elder Cap | per attack, not once a second; half | ATTACK_META (:157, :1052-1055); FOCUS_BOSS |
| Retinue | 2; V+; half hit; bosses half | RETINUE_MAX 2, RETINUE_RANK 5, RETINUE_SHARE 0.5 (:164-166); FOCUS_BOSS |
| Shared Caps | 2; Charged/Exposed 1 | SHARED_STACKS 2, SHARED_SMALL 1 (:175-176) |
| Feeding Ground | 6 steps; 8 s; 1; Sprout 1; 1 a second; at most 2 | FEED_POINTS 12, FEED_SECONDS 8.0, FEED_STACKS 1 (:178-180); SUPPORT_SMALL 1 / _EVERY 1.0, SUPPORT_MAX 2 (:168-170) |
| Sporefall | 3 steps | SPOREFALL_POINTS 6 (:192) |
| Host Trees | 8 s; 1; Sprout 1; at most 2 | HOST_LINGER 8.0, HOST_STACKS 1 (:183-184); SUPPORT_MAX 2 |
| Host Grove | 3; 30% | HOST_GROVE_AT 3, HOST_GROVE_POTENCY 1.30 (:187-188) |

## (b)-(d) Rows with a problem

No row is over 30 words (text) or 40 (tip); longest are Fairy Path's tip (35) and Clump's tip (37).
Deathcap, Feeding Ground and Spreading Caps read clean.

| # | Row | Problem | Rewrite |
|---|---|---|---|
| 1 | Windblown | Two effects in the wrong order in one sentence; "3 {steps} on" is an idiom ("on" = further along); "the nightmare's last" (last what?). "plants" also means planting a Warden. Tip: "when there are too many" never says too many of what; "the {spored} limit" is the 4th "limit" in this Calling (mushroom limit, Season's +60%, Drowsy's). | "Each {dose} is 1 {stack} bigger than the last {dose} that nightmare took, up to 6, and grows a new {mushroom} 3 {steps} further down the path." Tip: "{Mushrooms} grown this way don't grow more, and are the first to go when the {mushroom} limit is reached. A {dose} never takes {spored} past its most {stacks}." |
| 2 | Drifting Spores | "A {mushroom} a {dose} planted plants one more, 3 {steps} on" is the hardest line in the set (double relative, idiom). "Up to 1 per 2 {steps} of path can grow" hides that this raises the {mushroom} limit (40). Tip "Its plantings": unclear "it". Sporefall's mushrooms grow again too (gen PLANTED, `:851`), Windfall's do not ("crop"): neither is said. | "A {mushroom} grown by a {dose} grows one more, 3 {steps} further down the path. The {mushroom} limit becomes 1 per 2 {steps} of path, from 40 up to 80." Tip: "Those {mushrooms} go first when the limit is reached. Sporefall's {mushrooms} grow one more too; Windfall's don't. (check)" |
| 3 | Spore Season | Rule 1: "deals 1% more" drops "damage". | "While 15 or more {mushrooms} grow, a nightmare's {spored} deals 1% more damage for each {step} it has walked since its first {dose}, up to +60%." |
| 4 | Thick Haze | "Spore Season's limit" is overloaded (mushroom limit, {spored} limit). | "Once Spore Season's bonus on a nightmare reaches +60%, every 10 {steps} it walks after that deals 1 s of its {spored} damage at once." Tip: "Bosses once theirs reaches +30%, and they take half. Its {spored} keeps ticking. Damage only: no {stacks}." |
| 5 | Fairy Path | "after it is used": every other row says "eaten". Tip: "it" means the Sprout, then the {mushroom} in the next sentence; "The clock" is never introduced. | "Each Sprout grows a {mushroom} on the nearest {step} {touching} it, and grows it again 10 s after it is eaten." Tip: "Only while that Warden stays a Sprout. The {dose} comes from your nearest {family:sporeling} Warden; with none left, the {mushroom} withers. The 10 s only count during a {drift}; these {mushrooms} are all back when a {rest} starts." |
| 6 | Rot Ground | "A Sprout bed" is never defined (Fairy Path's text has no "bed"); "bursts for Deathcap" is opaque. | "A Fairy Path {step} whose {mushroom} is regrowing still bursts: a nightmare with {spored} stepping there takes Deathcap's 2 s of its {spored} damage at once. No {dose}." Tip: "Shares Deathcap's once a second for each nightmare. Only while that Warden stays a Sprout. Bosses take half." |
| 7 | Clump | "clumps of 4" reads as exactly 4 (code: up to CLUMP_MAX). "stepping on one ... {touching} it": "one" and "it" both mean the clump, never named. Tip "Each step on a clump" uses the noun "step" (a {step} token elsewhere) for a footfall; "eats one" (one what?); "joins one" (one what?). | "{Mushrooms} gather in clumps of up to 4. A nightmare stepping on a clump takes a {free_hit} from each attacking Warden {touching} that clump." Tip: "A new {mushroom} joins the nearest clump with room within 3 {steps}. Each nightmare stepping on a clump eats 1 {mushroom}. At most 3 Wardens, the strongest first, each once a second. Bosses take half. Damage only: no status. The {dose} still lands." |
| 8 | Trampled Ground | Tip "Up to 2 a second" (2 what?). | Tip: "Each such Warden gives up to 2 {free_hits} a second." |
| 9 | Pile-On | Rule 14: "each hit" must be a direct hit (code: never from a free hit, `:1092-1093`); "{touching} it" (it = the clump, after "a Warden"). | "Each direct hit by a {rank} III+ Warden on a nightmare within 2 {steps} of a clump that Warden is {touching} calls a {free_hit} from each other {rank} III+ Warden {touching} that clump." (30 words.) Tip unchanged. |
| 10 | Trodden Path | "with 1 more {free_hit} a second for each Warden" does not say who gives it or where. Missing limit: each side of each clump counts once per nightmare (TRODDEN_SEEN_META, `:1077-1090`). | "Stepping on the {step} just before or after a clump counts as stepping on the clump. There, each Warden {touching} it also gives 1 more {free_hit}, once a second." Tip: "No {mushroom} is eaten and no {dose} lands there. Each side of a clump counts once for each nightmare." |
| 11 | Toadstool Throne | Text says every clump touching a final form is a throne; tip says one per final form (code: the fullest it touches, then the nearest, `:1128-1148`). | "Each {final_form} makes one clump it is {touching} a throne: the throne's last {mushroom} is never eaten." Tip: "The fullest clump, then the nearest. A throne still takes new {mushrooms}, up to 4." |
| 12 | Elder Cap | "gives a {free_hit} there for each of its own attacks" reads as every attack hitting something; code: each attack readies one {free_hit} for the next nightmare stepping on the throne (ATTACK_META). Tip repeats "not once a second". | "A throne's {final_form} gives its {free_hit} to a nightmare stepping on that throne once for each of its own attacks, not once a second." Tip: "Bosses take half." |
| 13 | Retinue | "other" Wardens: code excludes every {final_form}, not just the throne's (`:1066`). "there" is vague. | "Up to 2 {rank} V+ Wardens that aren't {final_forms}, {touching} a throne, give a nightmare stepping on it a {free_hit} at half their hit, once for each of their own attacks." Tip unchanged. |
| 14 | Shared Caps | "that {mushroom}": no mushroom was named before it; the 20-word clause "the status the highest-rank other-family Warden ... already put on the nightmare" needs a re-read. Tip "for a Sprout, the {spored} the {dose} just put on" is a fragment. | "When a nightmare takes a {dose}, the highest-rank Warden of another family {touching} that {mushroom} adds 2 {stacks} to the status it already put on that nightmare." Tip: "Sprouts count; theirs adds to the {spored} the {dose} just put on. {static} and {marked}: 1. Never {held}. {drowsy} stays within its limit." |
| 15 | Windfall | Tip "Its cap is pale": "cap" is Host Trees' word for what a Warden wears (same Support line; both are owned after the Finale pick). "goes first when there are too many" as row 1. | Tip: "It counts toward the {mushroom} limit and goes first when the limit is reached. It looks pale." |
| 16 | Sporefall | "fills" is undefined here ({full} token exists). Rule 8: Sprouts count (code `is_other`, `:1207`) but the tip doesn't say. | "When another family's Warden makes a status {full} on a nightmare on fed ground, a {mushroom} grows 3 {steps} ahead of that nightmare." Tip: "Sprouts count. Once for each status on each nightmare. It counts toward the {mushroom} limit and goes first when the limit is reached." |
| 17 | Host Trees | "until 8 s after the last one goes": "one" = the last {mushroom} it touches, "goes" vague. | "A Warden of another family {touching} a {mushroom} wears a cap until 8 s after it stops touching any. Its status hits add 1 more {stack}." Tip unchanged. |
| 18 | Host Grove | Only Poisoned ticks and Charged bolts get the 30% (HOST_GROVE_TAGS, `:189`); "their statuses deal" reads as all statuses, as Undiluted did (R2.2 row 1). | Tip: "Sprouts count. Only {spored} and {static} damage. Never {reaction} damage; doesn't add with Undiluted: the larger counts. Doesn't make statuses last longer." |

## Notes for the owner
- Extra stacks from Shared Caps / Feeding Ground / Host Trees never complete a Charged bolt (`_feed`, `:591-593`);
  no tip says so. Fine if the glossary's {static} entry covers it.
- "plant(s)" for mushrooms also means planting a Warden: rows 1, 2, 16 use "grows" instead.
