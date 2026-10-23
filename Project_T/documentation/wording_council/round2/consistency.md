# Consistency seat: round 2 (2026-10-23)

Read-only. Repo `D:\Projects\Game\Project_T` as of HEAD c9ab1c79 + working tree. Paths below are relative to `Project_T/`.
Rulings applied: `documentation/wording_council_review.md` §3 (rulings), §5 (phrasing rules), §6 (one name each).

**Counts (section A, 32 items): DONE 28 · PARTIAL 3 · MISSING 0 · WRONG 1.**

---

## A. Round 1 fix checklist

| # | Item | Verdict | Evidence (file:line) | Fix still needed |
|---|---|---|---|---|
| D1 | Sleep → Drowsy | **PARTIAL** | `scripts/ui/icon_info.gd:20` "Drowsy" ✓; `scripts/run/dream_keywords.gd:57` "Drowsy" ✓. **Left:** `scripts/combat/support_log.gd:181` `"Sleep applied: %d"` and `:209` `"%s applied %d Sleep"` (Honeysuckle wall rows of the support log, player-visible) | `:181` → `"%s applied: %d" % [IconInfo.status_name(EnemyStatuses.DROWSY), …]`; `:209` → `"%s applied %d %s" % [row.name, n, IconInfo.status_name(EnemyStatuses.DROWSY)]` (as the `control` row at `:183` already does for Root) |
| D2 | Reroll | DONE | `icon_info.gd:290` new_cards = "Reroll"; `codex_data.gd:143` "Reroll"; `dream_state.gd:3141-3145` "Reroll · N left this run", tip has no "Dream again" | nit: see B (Second Thoughts / Wandering Mind say plain "reroll", Let Go uses the `{banish}` token) |
| D3 | Banish | DONE | `dream_state.gd:3147-3160` "Banish · …", "Banishes don't refill", "Banishes left: %d"; Grove node "Let Go" kept (`resource/meta/grove/let_go.tres:8`), which the ruling allows | — |
| D4 | UK spelling | DONE | No US spelling left in any player string in scripts/, resource/, scenes/ (only BBCode `[color]`/`[center]` tags and dict keys). `settings_panel.gd:30-31` "Centre on …" ✓; codex "neighbours" ✓ | — |
| M1 | Wellspring cap 260 | DONE | `codex_data.gd:52` "at most 260"; `dew_catch.gd:12` INTEREST_CAP 260 | (could read the constant like `lesson_demo.gd:93` does, so it never drifts again) |
| M2 | Perfect block 20 | DONE | `codex_data.gd:23` `{dew:+20}`; `drift_director.gd:148` 10 × `trial_dew_multiplier` 2.0 (`:163`) | — |
| M3 | Family picks after 1, 10, 35, 60 | **WRONG** (data moved after the fix) | Boss `codex_data.gd:26` ✓, Dreamlight `:14` ✓. **Family pick `:27`** "After drifts 1, 10, 35 and 60: choose a new Warden family" — but since 2fcae6f4 / section 31 drift 60 is a **deepen** pick, not a new family (`drift_director.gd:49-56` `family_pick_kind` → &"deepen"; `family_pick_screen.gd:149` "Choose a family to deepen") | `:27` → "After drifts 1, 10 and 35: choose a new Warden family for this run. After drift 60: choose one of yours to deepen. With none left, the Heartwood gives Dreamlight instead." (Main) |
| M4 | Set Off 12 / 16 | DONE | `codex_data.gd:167` uses `{field:chime_stone.sets_off_static_at}` / `{field:lullaby_bell…}`; data `chime_stone.tres:26` 12, `lullaby_bell.tres:28` 16 | — |
| M5 | Night Chimes 12 | DONE | `codex_data.gd:279` "at 12 stacks"; `tower.gd:239` RESONANT_CHARGES 12, used at `:3546` | — |
| M6 | Arc 4.5 | DONE | `codex_data.gd:90` `{field:jarlink.special_params.link_range:cells}`; `jarlink.tres:27` 4.5 | same entry still says "Phantoms" (see B) |
| M7 | Swift +15% | DONE | `icon_info.gd:45` "+15%"; `tower.gd:427` FOCUS_SWIFT 0.15 | — |
| M8 | Rank adds range | DONE | `codex_data.gd:48`, `icon_info.gd:42` "0.1 cells of range" | — |
| M9 | Poison lesson one clock | DONE | `lesson_card.gd:222` "The whole pile wears off 5 s after the last stack" | — |
| M10 | Reaction lesson | DONE | `lesson_card.gd:216` "When two statuses on one nightmare each reach enough stacks, they trigger a {reaction}" | the six status lines right under it (`:220-225`) still say "set off {reactions}": one lesson, two verbs (rule 10) |
| M11 | Never slowed without Soak | DONE | `nightmare_icons.gd:47` "{drowsy} and slowing auras don't slow it." | — |
| M12 | Dreamlight sources match | DONE | `codex_data.gd:14` "every family pick and every boss rest, and from some Wardens' shards" = `remember_screen.gd:1131` "every family pick and every boss rest"; code: `dream_state.gd:913/915` (picks), `:1194` (deepen pick), `:2999` (boss) | — |
| M13 | codex 180 / 576 "falls {asleep}" | DONE | `codex_data.gd:180` and `:576` | nit: `:165` says Asleep lasts "3 s", `:180`/`:576` "for a moment" |
| R1 | dream_state.gd mojibake | DONE | no "Â" / "Ã" in scripts/, resource/, scenes/ | — |
| R2 | Captions | DONE | Crossroads `crossroads.tres:17` +100% ✓; Briar Crown `briar_crown.tres:17` 60% ✓; Thicket `sprout_chorus.tres:18` +20%, no old rule ✓; Bitter Hedges `bitter_hedges.tres:18` 8% / 2 s / +40% ✓ | nits: Bitter Hedges caption drops "from hits"; Briar Crown caption drops "attacking" |
| R3 | Soak chip | DONE | `dream_keywords.gd:56` "water hits deal 20% more damage" = `icon_info.gd:19` | — |
| R4 | Hunter's Patience flyers | DONE | `hunters_patience.tres:9` "…and 40% more to flyers." | — |
| R5 | Thorncoil / Bellflower "every second" | **PARTIAL** | Thorncoil ✓ (`thorncoil.tres:16`, `dream_thorncoil.tres:10`: "each second" here really means per second); Bellflower card ✓ (`dream_bellflower.tres:10` "every 2nd pulse"). **Left:** the Warden text `resource/tower/bellflower.tres:17` "Every second ring on a nightmare gives it {drowsy}." | → "Every 2nd ring on a nightmare gives it {drowsy}." Also align the card: "every 2nd pulse gives the nightmares around it" (per pulse) vs Warden "every 2nd ring on a nightmare" (per nightmare); one of them is wrong (check `status_every`) |
| R6 | Lent cards use `{family:}` | **PARTIAL** | Most lent cards ✓ (99 "{family:x} Warden(s)" in live cards). **Left:** `seeping_in.tres:9` (Settling Spores) "after a Sporeling hits"; `spore_ring.tres:9` (Spore Huddle) "A Sporeling's hits … each other Sporeling"; `spore_ring.tres:10` "Sporelings packed together"; `rude_awakening.tres:10` "Each bell once a second". Code: both are `is_own()` = any Sporeling-family Warden (`spore_print.gd:384, 1106`) | "a {family:sporeling} Warden hits…"; "A {family:sporeling} Warden's hits add 1 more {stack} of {spored} for each other {family:sporeling} Warden {touching} it, up to 3 more."; tip "…{family:sporeling} Wardens packed together"; "Each {family:bellflower} Warden once a second." |
| T1 | Grandmother Oak Dew 30 | DONE | `tower/grandmother_oak.tres:11` and `dream_grandmother_oak.tres:10` read `dew_per_drift` = 30 | — |
| T2 | Sapling 16 / +8 | DONE | `heartwood_sapling.tres:13` fields; data `dew_per_drift` 16, `dew_per_rank` 8 (`:23`) | — |
| T3 | Honeysuckle card 12 | DONE | `dream_honeysuckle.tres:10` "up to 12 {stacks} from walls alone"; `tower.gd:100` WALL_DROWSY_CAP 12 | — |
| T4 | Honeysuckle {asleep} | DONE | `tower/honeysuckle.tres:11` | — |
| T5 | "full {marked}" | DONE | `mossback.tres:15`, `boulderback.tres:14`, both dream cards, codex `:168` | token nit: "full {marked}" here vs "{full} {marked}" on Beacon / the glossary (see D) |
| T6 | Great Bell 4+ | DONE | `great_bell.tres:11` and `dream_great_bell.tres:10` read `sets_off_static_at` = 4 | **but** the Grove node disagrees (B1) |
| T7 | Thorncoil every second | DONE | `thorncoil.tres:16` | rule 13 nit: "while one with {held} is in its range, it takes…" (two "it"s, Warden and nightmare) |
| T8 | 10 Root Wardens | DONE | "It damages every nightmare in range." on deeproot, earthbind, groundroot, heartroot, long_way_home, rootcurl, rootling, snugroot, tangleroot, thorncoil | the card `dream_rootling.tres:10` still says "Its roots nip at everything in range." |
| T9 | Thunderclap / Lightning Rod tokens | DONE | `thunderclap.tres:10` `{stacks:need_damp}` + `{stacks:clap_static}`; `lightning_rod.tres:10` `{stacks:need_marked}` + `{stacks:clap_static}` | — |

---

## B. Leftovers found by grep (scripts/ + live resource/)

Live = Dream cards without `retired = true` (384 of 576), plus every Warden / nightmare / Reaction / Omen / Grove .tres.

**B1. Fact mismatch (fix first).** `resource/meta/grove/bellflower_ascension.tres:9` "Its toll puts every nightmare to sleep and **sets off all their {static}**." The Great Bell (`great_bell.tres:11`, data `sets_off_static_at = 4`) only strikes nightmares with 4+ {static}, **at half damage**. Rewrite: "Every 8 s its toll makes every nightmare fall {asleep} and strikes each with {field:great_bell.sets_off_static_at} or more {static} with its bolt at half damage." (Meta owner)

**B2. Section 4 rows not on the checklist and still wrong:**
| Where | Now | Data | Rewrite |
|---|---|---|---|
| `dream/dream_beacon.tres:10` | "take +{pct:beacon.marked_bonus} damage **on top of** what {marked} gives" | `enemy_statuses.gd:414/671` `maxf(MARKED_EXTRA, marked_extra)`: 50% **replaces** 25%; the Warden text `tower/beacon.tres` says "stronger: +50% damage taken" | "…and its {full} {marked} is stronger: +{pct:beacon.marked_bonus} damage taken instead of 25%." |
| `dream/restless_dreams.tres` (Waking Dreams) cost | "can't be let pass" | — | "can't be skipped" (or "has no Let it pass") |
| `dream/static_bloom.tres` | name "Charged Bloom", effect adds {drowsy} | — | owner call (rename) |

**B3. "Sleep" as a status name / plain "sleep" in rules text** (ruling §3.1)
- `combat/support_log.gd:181, :209` (D1 above).
- `meta/grove/bellflower.tres:9` "gives nightmares {drowsy} until they fall asleep" → "…until they fall {asleep}".
- `meta/grove/bellflower_ascension.tres:9` "puts every nightmare to sleep" (B1).
- `dream/sitting_ducks.tres:9` (live) "Needs a way to put nightmares to sleep or {held}" → "Needs a way to make nightmares {asleep} or {held}".
- `enemy/watcher.tres:18` hint "don't count on sleep to stop the others" → "…on {asleep} to stop the others" (also strategy advice; low).
- OK as is: "Deep Sleep" (card name), "Sleepwalk", "Sleep No More", flavour lines, "puts to sleep" in role lines (linked to Asleep by `status_links.gd:245`).

**B4. "Dream again" / "New cards" / "Let go" / "let-go":** none in player text (only code comments: `dreams_row.gd:248`, `dream_screen.gd:276, 325`, `keeping_time.gd:139`). Token use is uneven: `grove/let_go.tres:9` uses `{banish}`, but `grove/second_thoughts.tres:9` "+1 {dream} reroll" and `dream/wandering_mind.tres:9` "Gain 2 Dream rerolls." are plain. → "+1 {new_cards} per run…", "Gain 2 {new_cards}." (token renders "Reroll"/"rerolls").

**B5. US spellings:** none. **Mojibake:** none.

**B6. Other §6 terms still leaking** (player-visible strings):
| Where | Now | Rewrite |
|---|---|---|
| `combat/support_log.gd:179` | "Adds %d path tiles" | "Adds %d path cells" |
| `ui/results_screen.gd:354` | "Longest path: %d tiles" | "%d cells" |
| `meta/meta_run.gd:23` | milestone "Build a 130-tile path" | "Build a 130-cell path" |
| `tower/tower_placer.gd:1938` | "Grow into %s: pick a square (Esc to cancel)" | "pick a Warden" (it picks a Warden to grow, check) |
| `ui/rest_report.gd:253` | "%d leak(s)" | "%d {leaves} lost" / "%d got through" |
| `run/dream_batch_rules.gd:626` | "Gauntlet path on your route now: %d steps." | "Gauntlet path now: %d {steps}." |
| `ui/codex_data.gd:90` (Arc), `dream/dream_lightning_fence.tres:10`, `dream_nestling.tres:10`, `dream_wrens_nest.tres:10`, `dream_starling_murmuration.tres:10` | plain "Phantoms" | the Wardens already say `{nightmare:dandelion_seed}s`; use the same token on the cards and in the Codex |
| `ui/warden_panel.gd` (new) | "Reactions: set off %d · fed %d" | "Reactions: triggered %d · fed %d" (rule 10) |

**B7. Rule 10 ("trigger", never set off / go off) is not applied yet.** About 62 strings say "set(s) off" and 22 "go(es) off" (scripts + resources, some retired); "trigger" appears 5 times. Biggest clusters: `codex_data.gd` (10), `icon_info.gd` (6, every status tip ends "set off {reactions}"), `lesson_card.gd` (5), the 8 "can go off only half as often" Crowned cost lines, the Crowned Reactions' "Set off by …" lines. Since §5 waits on the owner, I list it as a pattern, not a checklist failure, but the Reaction lesson now mixes both verbs in one panel.

---

## C. Term map (new / changed text)

| Thing | Names in use (count, live text) | One name |
|---|---|---|
| Any Warden of a family | `{family:x} Warden` (99 on cards) · "Firefly / Fireflies", "Dewdrop(s)", "Sporeling", "bell(s)" (Callings + evolutions, now defined in `callings.gd:30-33` "A Firefly is any Firefly Jar form") · "spore Warden" (code comments, old tips) · "a Sporeling" (2 lent cards, R6) | Cards: `{family:x} Warden`. Callings may keep the short word since it is defined, **but** "Dewdrop" / "Bellflower" are also the base Warden's name (`{warden:dewdrop}`): the evolution texts changed `{warden:dewdrop}s` → "Dewdrops" this round (`calling_paths.gd:165-208`), so "Dewdrops" now means two different sets in one game. Prefer `{family:dewdrop} Warden` there too, or a short family token |
| A hit that is not a status tick | "direct hit(s)" (14 cards, 11 of them new) · "hit(s)" (older cards) · glossary: none | Add "direct hit" to the glossary (= a Warden's attack landing; not status, cloud, bolt or {reaction} damage) and use it everywhere, or drop "direct" |
| "Hits only" tip | "Hits only." (7) · "Hits only, not status damage." (4) · "Hits only: never statuses or {reaction} damage." (2) · "Hits only, not statuses." (1) · "Hits don't count." (1) | One: "Hits only: not status or {reaction} damage." |
| The dispelling hit | "killing blows" (Trophies, new) · "dispels" + "the one whose hit brings a nightmare to 0 health" (Hard-Won Rings) · `{dispel}` (Tallest Tree) | "dispels" (`{dispel}`): "A Warden that {dispel}s 10 nightmares in one {drift}…" |
| Damage carried past the target | "carries on to the next 2 nightmares behind" (Run Through, new) · "pierces" (Pinned) · "{jumps}" (Firefly cards) | Run Through is a pierce, not a jump: "…pierces: the next 2 nightmares behind its target take half" (same verb as Pinned) |
| Selling / growing a Warden with a counter | "Selling resets the count; growing keeps it." (Hard-Won Rings) · "Kept when it grows, lost if sold." (Trophies) · "Sold: choose again." (Tallest Tree) | "Growing keeps it; selling loses it." on all three |
| Not in this run (branches) | "Not in this run" (Codex `:70`, Remember `remember_screen.gd:583, 986`) · **"Not in this dream"** (new deepen screen `family_pick_screen.gd:982`) | "Not in this run" |
| Rank-gated cards | "Wardens at {rank} II or higher" (Finishing Blow) · "From {rank} III" (Measured Blow) · "Offered once a {final_form} reaches {rank} IV" (Towering) | "From {rank} II" style, one form |

## D. Phrase map (new cards vs §5 rules and the older cards)

- **Rule 1 "deals N% more damage":** 39 live cards say "deal(s) N% more damage", 17 drop "damage", including 8 of the 11 new ones (Bearing Down, Clean Strike, Finishing Blow, Nowhere to Run, Open Road, Standing Tall, Trophies, plus Towering). Fix: add "damage" ("deal 25% more damage to nightmares…").
- **Ruling §3.3 (Adds to / Multiplies with your other Dream damage):** only 3 tips say it (Gauntlet, Passing Thread, Struck Twice); none of the 11 new damage cards; no "Dream damage" / "Dream speed" Codex entry exists (`codex_data.gd` has none). The new cards are exactly the ones the ruling targets.
- **Rule 10:** Undiluted (`undiluted.tres:9`) "No {reaction} ever goes off" → "No {reaction} ever triggers". Its tip names "Lightning Rod" plain while Never Quite Dry uses `{named_combo:lightning_rod}`: use the token.
- **No hand-holding:** Finishing Blow tip (`finishing_blow.tres:10`) "Best on the Wardens near the Heartwood." is strategy advice: cut it.
- **Card shape:** the 11 new cards have no "Works for: … Safe / A bet" line; 75 older live tips do. Either is fine, but sibling cards should share one shape (owner call; the no-hand-holding rule leans toward dropping "Works for" everywhere).
- **"your" vs "its":** Clean Strike description "no other family's status" (other than the Warden's) but tip "Your own family's statuses don't count": the player owns several families. → "The Warden's own family's statuses don't count…".
- **Nowhere to Run** tip "Leaving its range starts the count again": code restarts after a 1.5 s gap between its hits (`dream_hit_cards.gd:46`), not on leaving range (check).
- **Calling evolutions:** "Never {held}" → "Doesn't add {held}" this round matches the cards ("Doesn't add {held}; never past {full}") ✓. "at half" → "at half damage" ✓ (`calling_paths.gd:109`). "Fireflies deal 5% more" / "deal 25% more there" drop "damage" (rule 1).

## E. Fact checks on the new text (numbers vs code)

All match: Bearing Down 4% / 10% per rank (`dream_hit_cards.gd:38-39`); Clean Strike 25% / 50% (`:42-43`); Finishing Blow 40%, a third, rank II (`:35-37`); Open Road 25%, 4 cells (`:40-41`); Nowhere to Run 5% / 40% (`:44-45`); Standing Tall 15% × 3 = 45% (`:47-48`); Trophies 10 / ×5 / 4% / 40% (`:49-52`); Run Through half, 2, 2 cells (`:53-55`); Measured Blow 1% per rank from III, cap 10%, not bosses (`:56-58`); Tallest Tree a fifth / 6× / 40 (`:59-61`); Towering 10% per rank above II, V +30%, VII +50%, offered at final rank IV (`dream_role_cards.gd:71-75`); Hard-Won Rings 40 / rank V (`dream_batch_rules.gd:21-22`).

Other mismatches found:
- **Jarlink vs Lightning Fence vs Codex Arc:** `jarlink.tres:17` "Flyers take 3 {static} at once"; `lightning_fence.tres:17` "strikes Phantoms gliding through it, which a Jarlink's link can't touch"; Codex `:90` "a flyer crossing it takes 3 {static}… catches Phantoms". Code (`branch_kit.gd:521, 558`): every flyer gets the 3 {static}; only the Fence deals damage to them. "can't touch" is wrong → "…which a {warden:jarlink}'s link only Charges." and use "flyers" if it is every flyer (check).
- **Bellflower per pulse vs per nightmare** (R5 note).
- **Codex Asleep duration:** `:165` "for 3 s" vs `:180` / `:576` "for a moment" (Still Pool's sleep may really be shorter; the combo line `:576` is the same Asleep as `:165`).

## F. Capitalisation / token breaks

- "full {marked}" (Mossback, Boulderback, Exposed Blow, Codex `:168`) vs "{full} {marked}" (Beacon, Night Chimes, glossary): use `{full}` everywhere.
- Grandmother Oak: card `{field:…:pct}` vs Warden `{pct:…}` for the same value: harmless on screen, but two token forms.
- `waystone.gd:13` "Old Waystone: +1 Dew per dispel" hard-codes the 1 and plain "Dew": `"Old Waystone: +%d Dew per dispel" % DEW_PER_DISPEL` (and the `{dew}` icon if the panel renders tokens).
- "Spore Huddle" (display name, `spore_ring.tres`) — no stale "Spore Ring" in player text ✓. "Settling Spores" — no stale "Seeping In" ✓.
- `dream_rootling.tres:10` "Its roots nip" (Root as flavour on a rules line, ruling §3.8).

## G. What already works

The decision renames landed cleanly (no "Dream again", "Let go", "Sleep" status chip, US spelling or mojibake anywhere a player reads, apart from the support-log rows). Codex numbers now read from data fields (`{field:…}`) so they track balance changes. The new cards' numbers all match their constants. The Calling evolutions moved to the cards' "Doesn't add {held}" phrasing.
