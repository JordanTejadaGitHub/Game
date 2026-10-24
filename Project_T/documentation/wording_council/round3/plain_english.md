# Wording Council round 3 (2026-10-24): plain_english seat

Seat: second-language readers and future translators. Read: corpus_resources.txt, corpus_ui_diff.txt ("+" lines),
calling_rows_now.txt (live rows only; retired rows skipped), icon_info.gd TERMS, wording_council_review.md rules 1-17,
plain_english.md section 3. I also looked at three uncommitted UI files the diff points to but doesn't contain
(`shape_rows.gd`, `rest_report.gd`, `dreams_block_panel.gd`) because they show the drift-shape names; marked "(uncommitted)".

## 1. Top 10 problems

| # | Where | Now | Problem | Rewrite |
|---|---|---|---|---|
| 1 | `drift_shapes.gd:22` NAMES; Dewdrop `dw_stream`; Lantern Alley "streak"; `gathering_storm.tres`, `struck_twice.tres` tips | Shape names "Stream", "Packs", "Single file", "Few and tough" | **Stream** now names two things the player sees on the same screen: a drift shape and the Dewdrop style "Stream" (a Dewdrop player reads "This block: Stream, Stream, Packs" as their evolution). **Packs**: Gathering Storm ("hit one pack") and Struck Twice ("in a pack") now read as "only in Packs drifts". **Single file** is an idiom many learners don't know. | Rename the default shape: **"Steady"** (or "Even"; owner picks). Keep "Packs" as the shape and take plain "pack" out of card tips: Gathering Storm "…when several {jump} cards hit nightmares close together"; Struck Twice "…against tough nightmares in a group". **"Single file"** → **"In a line"** (shape_rows "last in line" already uses this). "Few and tough" is fine. |
| 2 | icon_info.gd:330 `{water}` TERMS (plural = "water") | Mudflats "Path between two {waters} up to 4 {steps} apart"; "a {water}", "each {water}", "a {water}'s last 3 {steps}", "that {water}" (Riverside, Still Water, Wide Banks, Floodgate tip, River Mouth, Delta, Rapids) | "water" is uncountable in English. On screen: "between two water", "a water", "each water". Learners can't tell whether "a water" is one patch, one cell or any water. Translators will need a count noun anyway. | Give the token a count noun: TERMS `["water", "water pools", "Water", "pools"]`? Simpler: card text says **"a stretch of {water}"** / "two stretches of {water}" / "each stretch of {water}". Mudflats: "Path between two stretches of {water} up to 4 {steps} apart turns to mud." |
| 3 | `kt_evo_steady_beat` text | "A nightmare rung by only one bell since its last {toll} {tolls} every 3rd {ring}, in full, not every 4th at half." | On screen: "since its last Toll Tolls every 3rd ring". Noun and verb collide; readers stop and re-read (round 2b's rewrite was shortened into this). | "If only one bell has rung a nightmare since its last {toll}, its {toll} comes every 3rd {ring}, in full, instead of every 4th at half." |
| 4 | `lf_lantern_alley` text | "A glow entered within 4 {steps} of the last {flares} the nightmare: 25% of its Firefly's damage for each glow in the streak, up to 150%." | Garbled: "the last flares the nightmare" reads as "the last flares" (noun) + missing verb. Subject never stated. | "When a nightmare enters a glow within 4 {steps} of its last one, that glow's Firefly {flares} it: 25% of the Firefly's damage for each glow in the streak, up to 150%." |
| 5 | `unfettered.tres` + Codex "Calling hit" (`codex_data.gd`) | "Bonus hits from your Calling deal full damage, even from slow Wardens." Tip: "Still once per its own clock. Bosses still take their share." Codex: "Deals the Warden's damage, scaled; a Warden slower than the hit's clock deals a share." | Three names for one thing (bonus hits / Calling hit / free hits, flares, tolls…). "once per its own clock", "the hit's clock", "a share", "their share" are undefined. Every evolution's "Slower Wardens deal less." leans on this entry, so the entry must say slower than what. | Card: "{calling_hit}s deal full damage, even from Wardens slower than the hit's limit." (link the Codex entry). Tip: "Each one still has its own once-every-N-s limit. Bosses still take half." (check). Codex: "Deals the Warden's damage. A Warden that attacks less often than the hit can happen deals less, in step with its speed." (check) |
| 6 | `heartwoods_crown.tres` | "Grows when every other {node} is at its top level." | G1 fix is half-done: "every other" still reads as "every 2nd" to learners (rule 4). The Grove chip already says it right ("All other nodes at their top level", `grove_screen.gd`). | "Grows when all other {nodes} are at their top level. Adds a sixth {perk} slot: carry 6 {perks} into a run." |
| 7 | `sp_throne` (Toadstool Throne) text | "A Warden at a clump planted 10+ {drifts} ago makes it a throne: its last {mushroom} is never eaten, so its {free_hits} go on." | "planted 10+ drifts ago" can attach to the clump or the Warden; "it"/"its" ×3 point to different things; "go on" is a phrasal verb. | "If a Warden at a clump was planted 10+ {drifts} ago, the clump becomes a throne: its last {mushroom} is never eaten, so its {free_hits} keep coming." |
| 8 | `wider_roots.tres` | "The cost: calling back one of its {branches} costs 4 {dreamlight} instead of 3." | "calling back" is a phrasal verb and collides with the Calling term (avoid list: "Calling / call"). "The cost: … costs" doubles. | "The cost: getting back one of its {branches} costs 4 {dreamlight} instead of 3." (use the button's own verb if it has one, check) |
| 9 | Dream tips: `gathering_storm`, `heavy_going`, `on_the_beat`, `struck_twice` | "Works for: … Safe." / "A bet: pays when several {jump} cards hit one pack." | Avoid-list idioms ("Safe.", "A bet:", "pays") and strategy advice, which breaks the owner's no-hand-holding rule. | Delete the "Works for:", "Safe." and "A bet:" sentences. Keep only rules. |
| 10 | `lf_moth_to_flame` text | "A Firefly's direct hit on gold path saves a crit for the Warden with most gold dispels this block: +50% once 4 other hits land." | Too compressed: "+50%" of what? "once 4 other hits land" (on that nightmare? anywhere?). | "A Firefly's direct hit on gold path saves a crit for the Warden with the most gold dispels this block. After 4 more hits land on that nightmare (check), that Warden's next hit on it crits with +50% crit damage (check)." |

## 2. Every other flagged string

| Where | Now | Problem | Rewrite |
|---|---|---|---|
| `clean_strike.tres` | "Direct hits deal 25% more to nightmares…" / tip "…A family that puts no status never gets it. Hits only." | Rule 1 (missing "damage"); double negative + unclear "it"; rule 14 ("Direct hits only"). | "Direct hits deal 25% more damage to…" Tip: "Walls and Sprouts never count. A family whose Wardens put no status can't get this bonus. Direct hits only." |
| `heavy_going.tres` | "…deal 25% more to nightmares walking slowed." Tip "…and the Calling's own…" "A slowed nightmare drips while it counts." | Rule 1; "walking slowed" odd; "the Calling's own" (own what?); flavour line reads as a rule. | "…deal 25% more damage to slowed nightmares." Tip: "Any slow counts except {drowsy}'s and your Calling's slows. {held} and {asleep} nightmares stand still, so they don't count. Direct hits only." Drop "drips" or make it "(it drips to show this)". |
| `on_the_beat.tres` | "…each Warden {touching} it hits that nightmare again… Each once every 3 s." | "again" is wrong (they hadn't hit it); rule 3 subject missing. | "…each Warden {touching} the bell also hits that nightmare for its own damage. Each Warden once every 3 s." |
| `shattering_blow.tres` | "50% of its damage splashes onto nightmares within 1 cell." | Phrasal "splashes onto"; "splash" is also {dew_splash}. | "50% of its damage also hits nightmares within 1 cell." |
| `struck_twice.tres` tip | "Hits only, not {jumps} or bolts." | Rule 14. | "Direct hits only: not {jumps} or bolts." |
| `sunlit_rest.tres` tip | "A Warden at its highest {rank} passes it to the next." | "passes it to the next" (next what?). | "If that Warden is at its highest {rank}, the next Warden in this order gets it." |
| `the_old_ones.tres` | "…count as 2 {ranks} higher for every {rank} check… It never chains." | "check" is jargon; "chains" collides with Chain (Reactions). | "…count as 2 {ranks} higher wherever a card asks for a {rank}, Callings included." Tip: "…Never past {rank} VII. Only Wardens touching the {rank} V+ Warden itself." |
| `giants_walk.tres` | "Each one that reaches the Heartwood takes 1 more {leaf}." | "takes" (avoid). | "Each one that reaches the Heartwood costs 1 more {leaf}." |
| `swarming_night.tres` flavour | "They come in a rush, thin as moths." | "in a rush" idiom; "Rush" is also a card (Hunt's Rush). Flavour, low. | "They come all at once, thin as moths." |
| `swarm.tres` drift template | "Swarm" | Next to Omen "Swarming Night"; the rest report used to list template names. If templates still show anywhere, two near-names. | Keep only if no longer shown; else "Crowd". (check) |
| Codex "Deeply Blighted" (`codex_data.gd`) | "…and it takes two leaves. A Deeply Blighted counts as 3 toward dispel counts." | "takes" (avoid); "counts … counts"; adjective used as noun. | "…costs 2 leaves if it reaches the Heartwood. Each one counts as 3 dispels for cards." |
| Codex "Free hit" | "…never more than a second of its damage." | "a second" (time vs ordinal for learners). | "…never more than 1 s of its damage." |
| Codex "Repeat" | "…often at half damage." | "often" is vague for a rule. | "…at half damage unless the card says otherwise." |
| Codex "Spill" vs `dw_black_pond` | Card: "spill onto up to 4 others" | Avoid list ("spill onto"); the Codex term exists but the card doesn't link it. | "its direct hits in the pond also hit up to 4 other nightmares in it for 25% of the hit ({spill})." |
| `callings.gd` rootling | "Every Warden in range turns to face a nightmare with {held}, and its hits on it add twice as much status." | Rule 13: "its … it". | "…turns to face a nightmare with {held}, and that Warden's hits on the nightmare add twice as much status." |
| `callings.gd` whirligig | "Attacks through a {warden:whirligig}'s range go further." | "go further" vague. | (check) "Attacks that pass through a {warden:whirligig}'s range reach further:" then the two facts. |
| `callings.gd` dewdrop DETAILS | "…and hits nightmares with {damp} harder." | No number (check). | "…and deals N% more damage to nightmares with {damp}." |
| `callings.gd` firefly DETAILS | "…wider as its range grows." | "grows" = change form (avoid). | "…wider when its range increases." |
| `acorn_hidden.tres` | "…it copies the attack of its strongest neighbour." | Unlinked "neighbour" ({touching}/{near}). | "…it copies the attack of the strongest Warden {touching} it." (check) |
| `dewdrop_hidden.tres` | "it freezes nightmares that have {damp}" | Raw verb beside the {frozen} status. | "it makes nightmares with {damp} {frozen}." |
| `firefly_jar_hidden.tres` | "a beam that grows stronger the longer it stays…" | grow (avoid). | "a beam that gets stronger the longer it stays on one nightmare." |
| `firefly_jar_ascension.tres` | "Its lightning jumps to every nightmare in range (−15% per jump)" | "jump" as a plain verb (rule list) beside the {jump} term. | "Its lightning {jumps} to every nightmare in range (−15% for each {jump})…" |
| `whirligig_ascension.tres` | "…carrying the statuses it touches on to the rest." | "the rest" + "carry on" (avoid). | "…and spreads the statuses on nightmares it hits to the other nightmares it hits." (check) |
| `sporeling_ascension.tres` | "{spored} never wears off while…" | Phrasal "wears off". | "{spored} doesn't run out while a nightmare is in its range." |
| `memory_pond_keeper.tres` | "drags the nightmare furthest along the path back beside its pond" | Rule 11 short form. | "drags the leader back beside its pond" (once "the leader" is in the glossary). |
| `memory_white_stag.tres` | "Wardens in it crit more often" | No number. | "Wardens in it get +N% crit chance." (check) |
| `quickening.tres` | "…upgrades the start pool's {card:quickening}, offered once you hold it." | "start pool" jargon. | "…upgrades {card:quickening}. It can be offered once you hold {card:quickening}." |
| `sporeling_hidden.tres` / Crowned `fairy_circle.tres` | Warden "Fairy Ring"; Reaction "Fairy Circle": "Mushroom rings sprout…" | Two near-names; "rings" is now Bellflower's {ring}. | Fairy Circle: "Circles of mushrooms sprout on the path cells around the nightmare…" |
| Crowned `tempest.tres` | "…and their burning spores spread {static}." | "their" (arcs? nightmares?). | "…and those nightmares' burning spores spread {static}." |
| Crowned `still_pool.tres` | "still pool" | Pool vs Black Pond "pond" vs {water}: three water words. Low. | Keep; just never call {water} a "pool". |
| `sp_windblown` tip | "Planted {mushrooms} don't plant again, and go first when there are more than 40." | "go first" = "are removed first". | "…and are removed first when there are more than 40." Same in Windfall and Sporefall tips ("goes first"). |
| `sp_drifting`, `sp_deathcap_field` tips | "starts its route again" | "route" (avoid; = path). | "…starts its path again" or "…goes back to the start of the path". |
| `sp_deathcap_field` | "The first 3 {mushrooms} each nightmare steps on burst: each deals 2 s worth of its {spored} damage at once." Tip "Counts again after the Waymark…" | "each … each … its"; "Counts again" (what counts?). | "When a nightmare steps on one of its first 3 {mushrooms}, the {mushroom} bursts: it deals 2 s of that nightmare's {spored} damage at once." Tip: "The count of 3 starts again after the Waymark and when…" |
| `sp_season` | "While 15+ {mushrooms} grow, …" | "grow" = exist here. | "While 15+ {mushrooms} are on the map, …" |
| `sp_heavy_air` | "…without eating the {mushrooms}. A {mushroom} doses each nightmare once." Tip "A {mushroom} it leaves plants no new one." | Invented verbs "eat", "doses"; "it leaves" (leave = avoid; "it" unclear). | "…gets its {doses} without using up the {mushrooms}. Each {mushroom} gives each nightmare one {dose}." Tip: "A {mushroom} that nightmare doesn't use up plants no new one." |
| `sp_clump` tip | "Each step on a clump eats one." | Plain "step" next to {step} (path cell); "eats". | "Each time a nightmare walks onto a clump, one {mushroom} is used up." |
| `sp_pile_on` | "…each direct hit by a {rank} III+ Warden there calls a {free_hit}…" | "calls" (Calling term); "there" ×2. | "…gives a {free_hit} from each other {rank} III+ Warden at that clump." Tip: "A {free_hit} never gives another." |
| `sp_trodden` | "Stepping on the {step} just before or after a clump counts as stepping on it" | Verb "step" and noun {step} in one sentence. | "Walking onto the {step} just before or after a clump counts as walking onto the clump…" |
| `sp_throne` tip | "A throne still takes new {mushrooms}, up to 4." | "takes" (avoid). | "A throne still gathers new {mushrooms}, up to 4." |
| `sp_borrowed` tip | "…for a Sprout, the {spored} the {dose} just put on." | Fragment, hard to parse. | "For a Sprout, the {dose} adds the stacks to the {spored} it just put on." |
| `sp_host_trees` | "At each {mushroom}, the Warden Shared Caps picks wears a cap…" | Garden-path: card name as subject inside a relative clause. | "At each {mushroom}, the Warden chosen by Shared Caps wears a cap…" |
| `sp_spreading_caps`, `lf_flint_and_steel` | "Caps passed this way don't pass on." / "A passed crit never passes on." | Phrasal "pass on". | "…can't be passed again." / "A passed crit can't be passed again." |
| `sp_windfall` | "…leaves a {mushroom} where it fell" | leave (avoid). | "…a {mushroom} grows where it fell…" |
| `sp_sprout_beds` tip | "Only while it stays a Sprout… with none left, it withers." | Two "it"s, different things. | "Only while that Warden stays a Sprout… With no {family:sporeling} Warden left, the {mushroom} withers." |
| `lf_early_lamps` tip | "Halfway along the path it walks; flyers, their flight." | Elliptical; learners can't rebuild it. | "\"First half\": the first half of the nightmare's walk; for flyers, of their flight." |
| `lf_passed_torch` | "…takes over its streak." | Phrasal "take over". | "…gets its streak." |
| `lf_pyre` | "…from a Warden with 50 dispels on gold path…" | 50 exactly vs 50+. | "…with 50+ dispels on gold path…" (same in Banked Fire) |
| `lf_spreading_flame` | "…that stretch grows 1 {step} at each end… Another one grows it 1 more…" | grow = change form (avoid). | "…that stretch gets 1 {step} longer at each end… Another one adds 1 more…" |
| `lf_borrowed_light` tip | "It and another card's {jump} from one hit go to different nightmares." | "It" opens the sentence. | "If one hit makes this {jump} and another card's {jump}, they go to different nightmares." |
| `lf_show_the_way` | "Each Borrowed Light {jump} goes on to one more {lit} nightmare…" | Phrasal "go on". | "Each Borrowed Light {jump} also {jumps} to one more {lit} nightmare…" |
| `lf_sightline` | "Direct hits there send half as a {jump}…" | "send half as" compressed. | "Half of each direct hit there {jumps} to the healthiest other {lit} nightmare." |
| `lf_constellation` | "A star lights over a nightmare 3 different Wardens hit on pale path within 2 s…" | Missing "that"; hard parse. | "When 3 different Wardens hit a nightmare on pale path within 2 s, a star lights over it: the next 3 hits on it {jump} in full." |
| `lf_north_star` | "…when 2 different Wardens hit it within 2 s." | Fine, but put the condition first like Constellation. | "When 2 different Wardens hit a boss or a {deeply_blighted} nightmare on any {lit} path within 2 s, a star lights over it too." |
| `kt_evo_carrying_tune` | "each {ring} also rings nightmares…" | Token noun + plain verb (ring/rings) side by side. | "each {ring} also reaches nightmares up to 6 {steps} further along the path." |
| `kt_evo_hand_to_hand` tip | "{Rings} stay between bells." | Unclear (stay where?). | "A nightmare keeps its {rings} when it moves on to another bell." |
| `kt_evo_last_bell` | "Your last bell before the Heartwood {tolls} each once for its own damage…" | {toll} as a verb ("Tolls each once"). | "Your last bell before the Heartwood gives each nightmare one {toll} for the bell's own damage…" |
| `kt_evo_curfew` tip | "The count empties when the {drift} ends." | "empties" odd. | "The count resets when the {drift} ends." |
| `kt_evo_crescendo` tip | "Each nightmare keeps its own swell. Its {rings} grow bigger and brighter." | "swell" (avoid list); grow. | "Each nightmare has its own bonus. Its {rings} look bigger and brighter." |
| `kt_evo_midnight_bell` | "the bell hits it for 3 times its damage" | "its" = bell. | "the bell hits that nightmare for 3 times the bell's damage." |
| `kt_evo_twelfth_hour` | "When Midnight strikes, … strike their own Midnight too." | Idiom (clock "strikes"). | "When a Midnight {toll} lands, up to 3 other nightmares in that bell's range with 6+ {rings} also take a Midnight {toll}." |
| `kt_evo_double_time` | "…leaves the nightmare 2 {rings} into its next {toll}, not back at the start." | Idiomatic; "leaves" (avoid). | "After a {toll} from a {rank} IV+ bell, the nightmare's {rings} go back to 2, not 0." |
| `kt_evo_allegro` | "…each {toll} stopped by the once-a-second limit…" / tip "Each nightmare can {toll} once a second." | {toll} as verb. | Tip: "Each nightmare can take one {toll} a second." |
| `kt_evo_accompaniment` | "Wardens {touching} a bell, bells too, join it and ring." | "join it" undefined; "bells too" interrupts. | "Wardens {touching} a bell, other bells included, join that bell: their hits ring nightmares." |
| `kt_evo_counterpoint` / Symphony | "Each kind of joined Warden" / "4 different kinds of Warden" | "kind" undefined (form? family?). | Say "form" or "family" (check which). |
| `kt_evo_tenor_bell` tip | "Its form's speed: Dreams that quicken it don't take this away." | "quicken" rare; "take away" phrasal. | "Uses the form's own speed: Dreams that make it faster don't remove this." |
| `kt_evo_ensemble` | "…their repeats repeat once more 1 s later" | "repeats repeat". | "…each repeat lands once more 1 s later, at half damage." |
| `dw_stream` | name "Stream" | See top 1. | Rename the drift shape, not this card. |
| `dw_mudflats` tip | "the shortest gaps turn first" | "turn" = become mud. | "the shortest gaps become mud first." |
| `dw_sinking_mud` tip | "Back in mud or {water}, the trail starts again when it leaves." | "trail" undefined; "it". | "If the nightmare goes back into mud or {water}, the 4 {steps} start again when it comes out." |
| `dw_spate` | "…runs 12 {steps} on down the path…" | "on down" phrasal. | "…also runs 12 {steps} further along the path…" |
| `dw_fathoms` | "…a nightmare has waded the pond…" / tip "Leaving the pond starts it again." | "waded" rare; "it". | "…for each second a nightmare has spent in the pond…" Tip: "The count starts again when the nightmare leaves the pond." |
| `dw_crushing_depth` | "…direct hits pass the {dread_shell}…" | "pass" = ignore? | "…direct hits ignore the {dread_shell}…" (check) |
| `dw_riverside`, `dw_open_water` tips | "Up to 4 s past landing in all" | "in all" (avoid). | "Up to 4 s after landing in total ({static} 2 s)." |
| `dw_still_water` | "…stop wearing off ({lingering})…" / tip "wear off at half speed" | Phrasal "wear off". | "…don't run down ({lingering})…" / "Bosses' statuses run down at half speed." |
| `dream_state.gd:4376` sunlit_line | "Next rest: your %s" | "by the Heartwood" was dropped; the line no longer says what happens at the next rest. | "Next rest: free Nurture {rank} for your %s" (check) |
| `shape_rows.gd:84` (uncommitted) | "Stream: %d" | Number with no noun. | "Steady: %d nightmares" |
| `shape_rows.gd:79` (uncommitted) | "Packs: %d × %d, %d s apart" | "4 × 7" reads as maths. | "Packs: %d packs of %d, %d s apart" |
| `support_log.gd:179` | "Adds %d path cells" | Plural for 1 ("Adds 1 path cells"). | Plural-safe helper. |

## 3. Patterns

- **Token nouns used as verbs** ({toll}/tolls, {flare}/flares, {jump}/jumps, {ring}/rings, {step}/step on): keep the token a noun; the verb becomes "gives a {toll}", "{flares}" only where unavoidable. One noun + plain verb per sentence, never both forms side by side.
- **Uncountable {water}**: "a water", "two water". Use "stretch of {water}" or give the token a count noun.
- **Pack / Stream / Single file**: new drift-shape names clash with older card words; rename the shape, keep "pack" out of other text.
- **Phrasal verbs are back** in the new rows: go on, pass on, take over, wear off, on down, carry on to. Avoid-list replacements in plain_english.md section 3.
- **Invented mushroom verbs** (eat, dose as verbs): use "uses up", "gives a {dose}".
- **"Slower Wardens deal less" / "share" / "clock"**: one Codex entry must define the speed rule; then the tag line can link it.
- **"Works for: … Safe." / "A bet:"** still on 4 Dream tips: cut (no-hand-holding + idiom).
- **"grow" for "increase"** (Spreading Flame, Sunpetal, glow range, Crescendo): grow is the form-change word.
- **Garden-path sentences** with a card name as subject in a relative clause (Host Trees, Constellation): put the condition first, "When …, …".

### Words to avoid in rules text (additions this round)

| Avoid | Use instead |
|---|---|
| eat / eaten / eating (mushrooms) | use up / used up |
| doses (verb) | gives a {dose} |
| calls (a hit), calling back | gives; getting back |
| swell, waded, quicken | bonus; spent in; make faster |
| strikes (Midnight) | lands |
| go first (removal) | are removed first |
| go on / goes on to | keep coming / also {jumps} to |
| pass on, take over, take away | be passed again, get, remove |
| wear off / wearing off | run down / run out |
| Single file, Stream (drift shape) | In a line, Steady |
| a / each / two {water}(s) | a stretch / each stretch / two stretches of {water} |

## 4. Localisation risks (new code-built sentences in this diff)

| File:line | String | Risk |
|---|---|---|
| `dream_state.gd:4376` (diff 815) | `"Next rest: your %s" % " and ".join(names)` | English list join ("and"), possessive + list. |
| `boss_dossier.gd` (diff 877) | `"Hunt %s" % IconInfo.the_name(...)` | Code inserts the article "the". |
| `warden_panel.gd` (diff 984) | `"Grow into %s"` | Fine in English; other languages inflect the name. |
| `warden_panel.gd` (diff 996) | `"Close the Nurture choices%s." % (" (%s)" % key)` | Nested fragment. |
| `warden_panel.gd` (diff 1000) | `"Not enough Dew: need %s."`; earlier code compared on-screen text | Keep the comparison on ids, not text. |
| `support_log.gd:172, :179` | `"Dew caught this run: %d"`, `"Adds %d path cells"` | No plural handling. |
| `tower_seller.gd` (diff 867) | `"+%d Dew"` | Order of number and currency. |
| `touch_build.gd` (diff 980) | `"Plant %d"` | Number-verb order. |
| `drift_panel.gd:349` | phone_short table keyed on full English strings ("Choose an Omen" → "Omen") | Breaks when translated; key on ids. |
| `shape_rows.gd:67, :79, :81, :83, :84` (uncommitted) | `"Drift %d · %s"`, `"Packs: %d × %d, %d s apart"`, `"Single file: %d, %.1f s apart"`, `"Few and tough: %d, %d Deeply Blighted"`, `"Stream: %d"` | Fragments; `%.1f` decimal point; no plurals. |
| `rest_report.gd:346, :363` (uncommitted) | `"This block: " + ", ".join(names)`, `"Leaves lost by shape this act: " + ", ".join(parts)` | English list join. |
| `dreams_block_panel.gd:111` (uncommitted) | `"%s · on %d Warden%s%s"` with `"" if n == 1 else "s"` | English-only plural helper. |
| `icon_info.gd:330, :336` TERMS | `{water}` and `{lingering}` plural = singular | Plural slot holds the same word; card text relies on it ("two {waters}"). |

## 5. What already works

- Grove Ascension nodes now lead with the effect and end with one fixed route line (G1 done); no glued "s" on tokens.
- Buttons are consistent: Close / Next / Continue / Start run / Carry perk / Auto-drift / Title screen / Map seed / Use this map / Choose an Omen.
- "Can't be sold" replaced "Rooted"; "Boosts" replaced "Buffs"; "path cells" replaced "path tiles".
- Crowned Reactions all end with "Triggered by …" and say bosses/flyers in one place; the new Codex entry says what a Crowned Reaction is.
- Dewdrop boss numbers are now explicit ("bosses 7.5%", "bosses 17.5%") instead of "Bosses half".
- Thick Haze is retired; the Codex now defines Toll, Ring, Free hit, Flare, Repeat, Spill, Lingering.
- Many Calling rows are short and plain (Rot Bloom, Deep End, Wide Banks, Sounding Board, Full Glow).

Flagged: 10 top + 78 table rows = 88 strings, plus 13 localisation risks.
