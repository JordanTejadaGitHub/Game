# Scan reader: full round 2026-10-26

Seat: scan reader (mid-fight, on a phone). Read in full: corpus_resources.txt (656 resource texts), corpus_ui.txt
and corpus_short.txt (UI strings; noise skipped), icon_info.gd's names, wording_council_review.md section 5 (rules
1-17) and the R2/R3/RR/F/N rulings, and the templates T1-T9 (wording_council/scan_reader.md section 3, round2 T7,
round3 T8, roguelite T9). "Works for / Safe / A bet" tip lines are a kept convention: left alone, and kept in every
rewrite.

**How words are counted:** a `{token}` is 1 word (`{dew:{grow_cost:x}}` too), a `%d` is 1 word, punctuation is not a
word. A Dream "face" is the description; a face with a cost line is counted both ways. The counting script is in
D:\Projects\logs\wording_council\work_scan\stats.js (output: stats_out.txt).

---

## 1. Length stats for the whole game

| Kind | Items | Limit | Over | Mean | Median | Longest |
|---|---|---|---|---|---|---|
| Dream card faces (all) | 341 | 25 | **50** | 19.7 | - | 45 |
| - plain cards | 225 | 25 | 5 | 17.1 | - | 30 |
| - form unlock cards ("can now {grow} into", "can ascend") | 116 | 25 | **45** | 24.7 | - | 45 |
| - Ascension unlock cards only | 9 | 25 | 9 | 36.8 | - | 45 |
| Dream face + cost line | 27 | 25 | 7 | 22.9 | - | 36 |
| Tips (Dream 161, Calling rows 129, Calling rules 13) | 303 | 40 | **24** | 20.5 | 18 | 59 |
| Warden texts | 122 | 25 | **35** | 22.1 | 22 | 45 |
| Reactions (13 base + 10 Crowned) | 23 | 25 | **20** | 35.8 | 34 | 59 |
| Calling rows | 137 | 30 | 1 | 21.8 | 22 | 32 |
| Grove nodes | 94 | 25 | **15** | 17.8 | 14 | 43 |
| Buttons | 106 | 4 words | **11** | 2.5 | 2 | 12 |
| Omens (for reference) | 27 | 25 | 1 | 15.2 | 15 | 26 |
| Codex entries (for reference) | 122 | 40 | 13 | 22.6 | 20 | 55 |

Headline: plain Dream cards are in good shape (5 of 225 over). Length now sits in four places: **form unlock cards**
(45 over, all the 15 longest faces), **Reactions** (20 of 23 over), **Warden texts** (35 over), and the **Ascension /
Memory Warden Grove nodes** (12 of the 15 over). Calling rows hold to their limit (1 over).

### 15 longest of each kind

**Dream card faces** (all unlock cards): Old Mountain 45 · The Great Bell 41 · Mother Log 40 · Midsummer 38 ·
Whirligig 38 · Beacon 37 · Tidecaller 37 · World Root 37 · Great Dreamcatcher 36 · Pebbling 36 · Sporemother 36 ·
The Whirlwind 36 · Dawnwing 35 · Acorn 34 · Boulderback 33.
**Plain Dream cards over 25:** Lingering Splash 30 · Afterroot 28 · Momentum 28 · Fruiting 26 · Refrain 26 (then at 25:
Breathe It In, Heartwood's Reach, Mixed Company, Nod Off, Hunt's Rush II, Rooted Nightmares, Shared Training, Slow
Burn, Sparks Fly, Thousand Cuts).
**Face + cost over 25:** Spent Light 36 · Afterglow 33 · Conductive Soil 32 · Deep Sleep 27 · Double or Nothing 27 ·
Briar Trap 27 · Waking Dreams 26.

**Tips over 40 (all 24):** Wild Growth 59 · Second Verse 58 · Undiluted 55 · Thunderstruck 54 · Hailfall 49 · Flashover
48 · Gone to Seed 48 · Witching Bend 48 · Breathe It In 47 · Homesick 46 · The Walking Wood 46 · Firefly Calling rule
(callings.gd:30) 46 · Nothing Wasted 45 · Heartwood's Reach 44 · Last Drop 44 · The Tallest Tree 44 · Brushfire 43 ·
Ebb 42 · Hammerfall 42 · Waymark 42 · Headlong 41 · Knell 41 · Mixed Company 41 · Sap Rising 41.
(No Calling row tip is over 40; the longest is Moth to Flame's at 38.)

**Warden texts:** Dream Oak 45 · Heartwood Sapling 44 · Wellspring 43 · Great Dreamcatcher 39 · Quaker 39 · Seedbearer
38 · Mother Log 37 · Old Mountain 35 · Acorn 31 · Rampart 31 · Earthbind 30 · Rockslide 30 · Beacon 29 · The Great Bell
29 · Grove Heart 29.

**Reactions:** Sleepwalk 59 · Night Terror 51 · Pinned 45 · Tempest (Crowned) 45 · Still Pool (Crowned) 44 ·
Mushrooming 43 · Avalanche (Crowned) 41 · Fairy Circle (Crowned) 39 · Changeling (Crowned) 37 · Nightbloom (Crowned) 37
· Brittle 34 · Starfall (Crowned) 34 · Thunderclap 33 · Ignite 32 · Fever Dream (Crowned) 31. Under 25: Shatter,
Lightning Rod, Wide Awake only.

**Calling rows** (line = calling_paths.gd text line): Three Springs :415 32 · Down the Line :257 30 · Rot Ground :60 28 ·
Churning Water :412 27 · Wet Footprints :446 27 · Outflow :453 27 · Far Lights :166 26 · Flash Flood :360 26 · Windblown
:31 25 · Shared Caps :88 25 · Feeding Ground :92 25 · Rotburst :125 25 · Lantern Alley :157 25 · Lantern Parade :160 25
· Marsh Lights :175 25.

**Grove nodes:** Memory Warden: The Pond Keeper 43 · Memory Warden: The White Stag 43 · Ascension: Tidecaller 42 ·
Memory Warden: The Moon Moth 42 · Ascension: Grandmother Oak 38 · Ascension: Old Mountain 38 · Ascension: The Great Bell
37 · Ascension: Sporemother 37 · Ascension: The Whirlwind 37 · Ascension: World Root 36 · Ascension: Stormheart 33 ·
Ascension: Dawnwing 33 · Leaf or Dew 28 · Grove branch: Samara 27 · Bellflower family 26.

**Buttons over 4 words (all 11):** "Make this the Eldest? Only one Warden can grow past rank V" (warden_panel.gd:443) 12 ·
"No save yet (one is written at each rest)" (pause_menu.gd:527) 9 · "Save copied (%d KB): paste it in a message"
(pause_menu.gd:530) 9 · "Permanent: the Sapling can't be sold or moved" (warden_panel.gd:525) 8 · "Add to this run,
free (Borrowed Branch)" (remember_screen.gd:1016) 7 · "Plant Sprout (%d) · at the next rest" (warden_panel.gd:2132) 7 ·
"Start over as a new profile" (settings_panel.gd:408) 6 · "Swap places: again in %d s" (warden_panel.gd:1448) 6 · "Call
drift %d early, %s" (drift_panel.gd:274) 5 · "Yes: make it the Eldest" (warden_panel.gd:444) 5 · "Sell %d Wardens? Press
again" (warden_panel.gd:688) 5. Then at 4: "Peek at the map", "Start boss drift %d", "Rest after drift %d", "Confirm your
Wardens first".

---

## 2. The 20 hardest texts to scan, ranked, with rewrites

Every rewrite keeps every mechanic, number and token. "(check)" = the mechanic needs a code look before the text lands.

| # | Where | Now | Problem | Rewrite |
|---|---|---|---|---|
| 1 | Reaction **Sleepwalk** (59) | "It turns and walks back up the path for 2 s at half speed (bosses 1 s), and every nightmare it bumps into turns round too for 0.5 s (never bosses). Needs {stacks:need_spored} {spored} + {full} {drowsy}. Uses up the {drowsy}. Twice per nightmare at most (bosses once). Waits while it is {asleep} or near a {warden:dreamcatcher}. Never flyers." | Six sentences; the old "Needs" shape; bosses three ways in one card; "near" is the 2-cell {near} word used loosely. | "It walks back up the path at half speed for 2 s (bosses 1 s); nightmares it bumps turn back for 0.5 s (not bosses). Triggered by {stacks:need_spored} {spored} + {full} {drowsy}. Uses up the {drowsy}. Twice per nightmare (bosses once). Waits while it is {asleep} or {caught}. Not flyers." ({caught} = asleep or full Drowsy near a Dreamcatcher: check it is the same test) |
| 2 | Reaction **Night Terror** (51) | "It wakes screaming: its {static} fires at once as a bolt, and every nightmare within 2 cells can't move for 1 s (bosses 0.5 s) and gains 2 {held}. Needs … Uses up the {static} and the {drowsy}. Waits while it is {asleep} or near a {warden:dreamcatcher}." | Effect is after a flavour clause; "can't move for 1 s … and gains 2 {held}" is the long form rule 11 retired, in reverse order. | "Its {static} fires at once as a bolt, and nightmares within 2 cells gain 2 {held} for 1 s (bosses 0.5 s). Triggered by {stacks:need_static} {static} + {full} {drowsy}. Uses up both. Waits while it is {asleep} or {caught}." |
| 3 | Reaction **Pinned** (45) | "… Needs {stacks:need_marked} {marked}, plus {stacks:need_held} {held}, {full} {drowsy} or {asleep}. Uses up the {marked}, and the {drowsy} when that set it off." | "plus A, B or C" reads as a list of all three; "set off" (rule 10); "that" has no clear antecedent. | "Its next hit is a crit for ×3 damage that pierces: nightmares in a 3-cell line behind it take half. Triggered by {stacks:need_marked} {marked} + one of: {stacks:need_held} {held}, {full} {drowsy}, {asleep}. Uses up the {marked} (and the {drowsy} if it was the trigger)." |
| 4 | Crowned **Tempest** (45) | "The {combo:thunderclap}'s arcs trigger {combo:ignite} on nightmares with … and their burning spores spread {static}. Triggered by a {combo:thunderclap} on a nightmare with {stacks:crown_spored} {spored}, or by an {combo:ignite} on one with {stacks:need_damp} {damp}. …" | Two triggers; when an Ignite triggers it, there are no "Thunderclap's arcs" for the first sentence to refer to. (check what happens then) | "Its arcs trigger {combo:ignite} on nightmares with {stacks:need_spored} {spored}, and the burning spores spread {static}. Triggered by a {combo:thunderclap} on {stacks:crown_spored} {spored}, or an {combo:ignite} on {stacks:need_damp} {damp}. Each nightmare once every 2 s. Bosses: no {combo:ignite}." (+ say what "its arcs" are on the Ignite path) |
| 5 | Dream **Undiluted** tip (55) | "Nightmares with {damp} take 25% more from all hits. At {full} {drowsy}, a nightmare falls {asleep} for 2 s; bosses never do. {marked} works from 5 stacks (10 with Brimming). When {held} ends, half the damage taken while {held} hits again. Cards that only work through {reactions} are no longer offered, and {named_combo:lightning_rod} doesn't trigger." | A list of telegrams (F.3) with the status in a different place each time; raw "Brimming", raw "stacks". | Status first, one line each: "{damp}: +25% damage from all hits. {full} {drowsy}: {asleep} for 2 s (not bosses). {marked}: works from 5 {stacks} (10 with {card:brimming}). {held}: when it ends, half the damage taken during it hits again. Cards that only work through {reactions} stop being offered; {named_combo:lightning_rod} never triggers." |
| 6 | Dream **Second Verse** tip (58) | "Another Warden: any but that {family:bellflower} Warden; other {family:bellflower} Wardens count. Same {stacks} as before. Doesn't add {held} or {frost}. It never starts a status or goes past {full}; {static} stops 1 short of a bolt. Once for each … Works for: … A bet: …" | Half the tip is the extra-stacks boilerplate that ~12 tips repeat in 9 wordings (section 3, S15). | "Another Warden: not that {family:bellflower} Warden (other {family:bellflower} Wardens count). Same {stacks} as before; {extra_stacks}. Once for each {family:bellflower} Warden and nightmare. Works for: status Wardens before a {family:bellflower} Warden. A bet: needs a second status Warden." (≈36; needs the new glossary entry, rule P4) |
| 7 | Dream **Wild Growth** tip (59) | "… You pick the form; branches still need Dreamlight, and Nurture {rank}s still pay their difference. Not Thornwalls, the Sapling or Ascended forms. Can't be taken with {card:clean_night}. Works for: … A bet: where nightmares die." | Longest tip; raw "Dreamlight", "Ascended"; "die" (rule 17). | "A dispel counts for the Warden that lands it and the 2 nearest other Wardens with it in range. You pick the form. {branches} still need {dreamlight}; Nurture {rank}s still pay their difference. Not Thornwalls, the Sapling or {ascended} forms. Not with {card:clean_night}. Works for: Sprouts and every family. A bet: where nightmares are dispelled." |
| 8 | Dream **Hailfall** tip (49) | "Every attacking Warden then counts as an area attacker: area cards work on it, single-target cards don't. A Warden with its own splash keeps it, at least 40% within 1 cell, on every nightmare there. …" | "Every attacking Warden" contradicts the face ("Wardens without a splash gain one"); singular "it" for a plural; three rules, no anchor. | "Wardens it gives a splash count as area attackers: area cards work on them, single-target cards don't. A Warden with its own splash keeps it (at least 40%, within 1 cell). Against nightmares that resist area attacks, the direct hit still deals full damage." (check F.3: only Wardens without a splash) |
| 9 | **Ascension unlock cards** (9 cards, mean 37; Old Mountain 45) | "Any {family:pebbling}-{family} final form can ascend into {warden:old_mountain} ({dew:{grow_cost:old_mountain}}, one per run): every 3 s it drops a boulder that hurts nearby nightmares; the one hit gains 1 {held} and can't move for 0.5 s. It always crits on nightmares with {held} or {drowsy}." | 14 words of unlock before the effect; "{family}-{family}" glued tokens; raw "final form" / "ascend" where {final_form} / {ascended} exist; colon + semicolon + "the one hit" (F.3) + long Root form. | Unlock as a header row (T10): **"{family:pebbling} {final_form} → {warden:old_mountain} · {dew:{grow_cost:old_mountain}} · one per run"**, body = the Warden text: "Every 3 s it drops a boulder on nightmares within {field:old_mountain.splash_radius:cells}; the nightmare it hits gains 1 {held} for 0.5 s. It always crits on nightmares with {held} or {drowsy}." Text-only fallback: "Any {family:pebbling} {final_form} can become {warden:old_mountain} (… , one per run). Every 3 s …" |
| 10 | Dream **Mother Log** (40) | "{warden:nurse_log}s can now {grow} into {warden:mother_log}s (…): Wardens {touching} it pay {field…:pct} less to Nurture, and a Warden sold there leaves its Nurture {rank}s in the log for the next one planted on that cell this {rest}." | "sold there", "the log", "the next one", "that cell": four references to keep in your head. | "…: Wardens {touching} it pay {field:mother_log.special_params.nurture_discount:pct} less to Nurture. Sell one, and the next Warden planted on its cell this {rest} keeps its Nurture {rank}s." |
| 11 | Calling row **Moth to Flame** (calling_paths.gd:188) | "A Firefly's hit on gold path saves a crit on that nightmare for the Warden with most gold dispels this block. 4 more hits: +50%." | "saves a crit … for" is a new verb; "4 more hits: +50%" has no subject (whose hits? +50% of what?). | "A Firefly's hit on gold path readies a crit on that nightmare for this block's top gold-dispel Warden. After 4 more of its direct hits, that crit deals 50% more." (check) |
| 12 | Warden **Dream Oak** (45) | "Pulses damage to every nightmare in range. It also makes {dreamlight} slowly, faster with more {families} near it: 1 shard each {drift}, +1 for each different {family} among Wardens within … (up to +…). 10 shards make 1 Dreamlight (up to … a run)." | "slowly, faster with more families near it" says the numbers twice, once vaguely; "near" (a defined word) for a different reach; raw "Dreamlight". | "Pulses damage to every nightmare in range. Makes {dreamlight} shards: 1 each {drift}, +1 for each different {family} among Wardens within {field:…family_reach:cells} (up to +{field:…family_max:count}). 10 shards make 1 {dreamlight}, up to {field:…dreamlight_max:count} a run." (≈33) |
| 13 | Warden **Wellspring** (43) | "… At every rest it also pays {field…:pct} of your banked Dew (up to {dew:…}; all Wellsprings together up to {dew:260}), and {dew:…} each {drift}." | Raw "rest", "Dew" beside the tokens; a parenthesis with a semicolon inside; the per-drift income hangs off the interest sentence. | "Pulses damage to every nightmare in range. Nightmares dispelled within X drop Y more {dew}, paid at the {rest}. At each {rest}: Z of your banked {dew}, up to {dew:A} ({dew:260} for all Wellsprings). Also {dew:B} each {drift}." |
| 14 | Warden **Heartwood Sapling** (44) | "… Gives {dew:…} after every {drift} and 1 {dreamlight} every 10 drifts. Each Nurture {rank} adds {dew:…}; from rank III, Dreamlight every 8 drifts. Each {leaf} lost withers the yield 5% until the next {rest}." | Bare "rank III" (N1); raw "drifts", "Dreamlight"; "withers the yield". | "A seedling of the Heartwood, 2×2 and rooted for good. After every {drift}: {dew:X}, +{dew:Y} per Nurture {rank}. 1 {dreamlight} every 10 {drifts} (every 8 from Nurture {rank} III). Each {leaf} lost cuts its yield 5% until the next {rest}." |
| 15 | Dream **Breathe It In** face (25) + tip (47) | Face: "… get 1 more {stack}, 3 if it is {asleep} or {held}. Once a second per Warden." Tip: "… Only stacks a Warden's own attack adds count, not stacks added by other cards or your Calling. …" | "it" = the nightmare, two nouns back; limiter not subject-first (rule 3); the tip says the same exclusion twice. | Face: "Statuses added to nightmares in a {family:sporeling} Warden's range get 1 more {stack} (3 more on nightmares {asleep} or {held}). Each Warden once a second." Tip: "Any family's statuses, {spored} too ({drowsy}: only 1 more). Only stacks from a Warden's own attack, not from cards or your Calling. Never adds {held}; never past {full}. Works for: … Safe." |
| 16 | Dream **Flashover** tip (48) | "Half of the most it dealt to one nightmare. Once per attack. Not {family:firefly_jar} Wardens, except {warden:sparkler} and {warden:starburst} {near} another one. …" | Opens with an orphan fragment; "another one" = another Sparkler? another Firefly? | "Half: of the most the attack dealt to one nightmare. Once per attack; at most 3 s of the {family:firefly_jar} Warden's damage. {family:firefly_jar} Wardens don't count, except a {warden:sparkler} or {warden:starburst} {near} another {family:firefly_jar} Warden. Works for: … A bet: …" |
| 17 | Dream **Thunderstruck** tip (54) | "… Each {jump} adds 1 {stack} of {static} from the {family:firefly_jar} Warden; bosses get none. Once per attack. At most 1.5 s of the {family:firefly_jar} Warden's damage in all. …" | Firefly token four times; two limiters as two sentences. | "Only nightmares a Warden hit in the last 2 s. {family:firefly_jar} Wardens' own {heavy} forms count. Each {jump} adds 1 {static} (bosses none). Once per attack; at most 1.5 s of that {family:firefly_jar} Warden's damage in all. Works for: … Safe." |
| 18 | Reaction **Mushrooming** (43) | "A spore cloud grows on its cell and the next path cell for 4 s: nightmares inside take 30% more effect damage (statuses, bolts and most {reactions}), until 1 s after they leave. …" | Parenthetical definition mid-sentence; "until 1 s after they leave" lands after it, far from "inside". | "A spore cloud covers its cell and the next for 4 s: nightmares in it take 30% more effect damage, until 1 s after they leave. Triggered by {stacks:need_spored} {spored} + {stacks:need_damp} {damp}. Uses up the {damp}." ("effect damage" via the Codex Effect entry, check it lists bolts and most Reactions) |
| 19 | Dream **Bearing Down** | "Single-target Wardens' direct hits deal 4% more damage for each attack in a row on one nightmare, up to +10% per Nurture {rank}." | The cap is a formula: "+10% per Nurture rank" reads as a second bonus. | "Single-target Wardens' direct hits deal 4% more damage for each attack in a row on one nightmare, up to +10% for each Nurture {rank} the Warden has." (check the cap really scales with rank) |
| 20 | Grove **Memory Warden** nodes (3, all 42-43) | "Every 4 s its tongue drags the nightmare furthest along the path back beside its pond, and gives it {damp}. Grows the first time you dispel the Mire Hag. After that, it can be offered as a reward when you dispel that boss." | 19-word unlock tail; "Grows" for a Grove node (N1 keeps grow for forms); "the nightmare furthest along the path" (rule 11). | "Every 4 s its tongue drags the leader back beside its pond and gives it {damp}. Unlocks when you first dispel the Mire Hag; after that, dispelling her can offer it." (≈28) |

---

## 3. Sibling sets that don't share a shape

**S1 · Reactions (23): two shapes in one list.** The 10 old base Reactions say "Needs A + B." (Drown, Ignite, Lightning
Rod, Mushrooming, Night Terror, Pinned, Shatter, Sleepwalk, Smother, Thunderclap); the 3 Frost Reactions and all 10 Crowned
say "Triggered by …" (F.2 ruling). Inside the old ten: Drown and Thunderclap put the numbers after "Needs"; Lightning Rod,
Shatter and Smother have no "Uses up" line (check: nothing used up, or just unsaid); bosses appear six ways ("(bosses 1 s)",
"(never bosses)", "Bosses: slowed only", "Bosses: the same", "Bosses: never", "Bosses: no sleep"); flyers "Never flyers" vs
"Not flyers". Shape **T11**: "[Effect with numbers (bosses N)]. Triggered by [A + B]. Uses up [X]. [Limit.] [Not flyers.]"
Models: Brittle, Flash Freeze, Wide Awake. Rewrites for the old ones:
- Drown: "It is pulled under for 3 s: 60% slower (bosses 30%), taking more damage each second. Triggered by
  {stacks:need_damp} {damp} + {full} {drowsy}. Uses up the {drowsy}."
- Thunderclap: "It takes ×12 damage and arcs to nightmares with {damp} in range for ×6, each arc adding 1 {static}.
  Triggered by {stacks:need_damp} {damp} + {stacks:clap_static} {static} ({stacks:bossclap_static} on bosses)." (rule 5:
  ×12 of what? name the base; check)
- Ignite: "Its {spored} burns 4 times as fast for 3 s, and each second 1 {stack} spreads to the nightmares beside it.
  Triggered by {stacks:need_spored} {spored} + {stacks:need_static} {static}. Uses up the {static}."
- Smother: "While its {held} lasts, its {spored} stops hurting and builds; when {held} ends, it all bursts at once for
  double. Triggered by {stacks:need_held} {held} + {stacks:need_spored} {spored}."
- Shatter / Lightning Rod: swap "Needs" for "Triggered by"; nothing else.
Display idea (UI's call): print "Triggered by … Uses up …" as a second, smaller line; the first line is then 11-25 words
on every Reaction.

**S2 · Form unlock cards (116): four shapes, and the body never matches the Warden text.**
(a) "{warden:X}s can now {grow} into {warden:Y}s (cost): clause." (b) Family cards: "Sprouts can now {grow} into … , or
plant one directly (cost). Sentence." (c) Ascension: "Any {family:X}-{family} final form can ascend into … (cost, one per
run): …" (d) Walls: "(+{dew:…} each)". Plurals bypass the token: "Crowns of Thorns", "Hatcheries", "Magpie Perches" (×2),
"Rain Lilies", "Nimbuses", "Silence"; {warden:long_way_home} has no "s"; `{warden:x}s` glued plurals everywhere
(localisation, G.2). The body is a second, shorter or different description of the same Warden:
| Warden | Unlock card says | Warden text says |
|---|---|---|
| Frostfern | "When a nightmare's {frost} is full it bursts, hurting it and those beside it." | "At {full} {frost} a nightmare bursts, hurting it and up to 4 others within 1 cell." |
| Sunpetal | "a beam that gets stronger …" | "A beam that grows stronger …" (N1: gets) |
| Hoarfrost / Rain Lily | "to the nightmare hit" / "the nightmare hit gains" | "the nightmare it hits gains" (F.3) |
| Dewdrop / Puffball / Old Mountain | "only the one hit gains {damp}" / "the one hit gains" | "the nightmare it hits gains" |
| Old Mountain | "hurts nearby nightmares; … gains 1 {held} and can't move for 0.5 s" | "within {field} cells …" (same long Root form) |
| Great Bell | "releases its bolt at half strength" | "is struck by its bolt for half damage" (Grove: "take its bolt at half damage") |
| Tidecaller | "pushes it back 1 {step}" | "drags nightmares back 1 cell" (check: step or cell?) |
| Boulderback / Mossback | "full {marked}" | "full {marked}" (raw "full"; use {full}) |
| Stormcap | "lightning that {jumps} from nightmare to nightmare" | "Lightning that chains to 4 nightmares; jumps further …" (raw chain / jump) |
Shape **T10**: the unlock as a header row ("{warden:A} → {warden:B} · {dew:cost}", Ascension adds "· one per run"), the body
= the Warden text word for word. This was round 1's finding 2 and is still the biggest single length win: it takes 10-14
words off 116 cards and ends the drift between card and Warden.

**S3 · The Ascension trio (Dream card, Grove node, Warden text) for 9 Wardens: three texts each.** Sporemother: card
"{field} {spored} per second to everything in range", Warden "Every second she breathes spores over everything in range (2
{spored} each)", Grove "everything in range gains 2 {spored} a second". World Root: card uses fields, Warden and Grove type
"5 s", "1 s", "30%". Grove's fixed tail "In a run, from {drift} 51: 3 {dreamlight} unlocks it, then 600 {dew} grows a
{final_form} into it." is 17 words on every node; as amount chips: "From {drift} 51 · {dreamlight:3} to unlock · {dew:600}
to grow". One source text for all three.

**S4 · Firefly jump cards (11): one idea, seven shapes.** Brushfire ("For 2 s after … half the status damage it takes
{jumps} to the nearest other nightmare"), Chain of Lanterns ("also {jumps}, at half damage, to the 2 nearest"), Conductive
Soil ("also {jumps} for half to up to 4 nightmares with {damp} within 2 cells"), Flashover ("half {jumps} to the nearest one
it missed"), Guiding Light I/II ("also {jumps} for half to every nightmare within 1 cell"), Hammerfall ("half {jumps} to the
nearest other nightmare"), Nothing Wasted ("Damage a {dread_shell} stops … {jumps} to the nearest nightmare without a
{dread_shell}"), Sparks Fly ("every 3rd hit another Warden lands on it within 2 s {jumps} half"), Tangled Lightning ("also
{jump} to 1 nightmare … a full hit that uses up 3 of its {static}"), Thunderstruck ("a quarter of the hit {jumps} to up to
4"). Share words: half / for half / at half damage / a quarter of the hit / a full hit. Shape **T12**: "When [who] hits
[condition], [share] of the hit {jumps} to [targets]. [Limit]." "Nearest: within 2 cells." is in 5 tips: put it in the
{jump} glossary once. Example: Conductive Soil "When a {family:firefly_jar} Warden's direct hit lands on a nightmare with
{damp}, half of the hit {jumps} to up to 4 nightmares with {damp} within 2 cells."

**S5 · Dewdrop-lent cards.** Five match: "{family:dewdrop} Wardens and Wardens {near} them" (Heavy Going, Sodden, Last
Drop, Wash Away). Breaks: High Tide ("Hits from Wardens {near} a {family:dewdrop} Warden", same set per its tip), Ebb ("in
a {family:dewdrop} Warden's range"), Never Quite Dry ("{near}"), Steeped ("{touching} … or in range of two"), Topped Up ("A
{family:dewdrop} Warden's hit"). High Tide should take the five's opening; the others are different reaches on purpose,
but the reach word should sit in the same place (after the who).

**S6 · Sporeling-lent cards (unchanged since round 1).** "in a {family:sporeling} Warden's range" (Breathe It In),
"{near}" (Gone to Seed, Mixed Company), "{touching}" (Mycelium, Pass It Round, Spore Huddle), "{family:sporeling} Wardens
and/or Wardens {near} them" (Fruiting, Parting Puff), "After a {family:sporeling} Warden hits" (Settling Spores), "A
{family:sporeling} Warden's hit" (Overnight). Same fix as S5.

**S7 · Bellflower cards.** Repeat verbs: "lands again" (Knell, In Time, Second Verse), "happens twice in a row" (Da Capo),
"lands twice" (Refrain), "hits that nightmare again" (On the Beat), "triggers again" (Reprise). Limiters: "Each nightmare
once every 6 s" (Knell), "Each Warden once every 4 s" (Refrain), "Each once every 3 s" (On the Beat: no subject). Pick
"lands again" for a repeated hit and keep the subject in every limiter. Rude Awakening's tip limits "Each
{family:bellflower} Warden once a second" while its face names no bell (code: the nearest bell's clock,
keeping_time.gd:1941; say "the nearest {family:bellflower} Warden" or drop it, check).

**S8 · Hit cards and their tips.** Faces: Finishing Blow, Nowhere to Run, Open Road, Standing Tall, Trophies, Clean
Strike follow T7. Off-shape: Fruiting, Heavy Going, High Tide, Sodden, Murmur, Opening Fracture, Sweet Harmony say "deal
N% more" with no "damage" (rule 1); Towering has no cap on its face (tip: "+50%" at VII); Trophies puts its condition first.
Tips: "Direct hits only." (7 cards) vs "Hits only, not status damage." (Fruiting, Heavy Going, High Tide, Sodden) vs "Hits
only, not statuses." (Hunter's Patience) vs "Hits only." (Shared Light). **Opening Fracture's tip contradicts the
glossary:** "Direct hits only: a hit on one nightmare, not an area attack, beam or status damage." The Codex says a direct
hit is any Warden's own attack, and Nowhere to Run's tip says "Area Wardens too. Direct hits only." Fix: "Direct hits
only, not area attacks or beams." (check what the code excludes).

**S9 · Root (Held) texts.** Long form "gains 1 {held} and can't move for X" still on Tangleroot, Snugroot, Old Mountain,
World Root, Earthbind (Warden + card), Deeproot card, Old Mountain card; short form "1 {held}: it can't move for X" on
Rootling, Deeproot Warden, Briar Trap, First Grip, Rooted Nightmares, Witch Ring; Night Terror has it backwards. "The
nightmare furthest along (the path)" is on Tangleroot, Snugroot, Rootling, Rootcurl, Long Way Home (Warden + card), The Pond
Keeper (Warden + node): 9 places. Rule 11's "the leader" never landed because the glossary entry doesn't exist yet: add
"Leader: the nightmare furthest along the path" to the Codex first, then sweep.

**S10 · Pulse openers on Warden texts.** "It damages every nightmare in range." (7 Root Wardens), "Pulses damage to every
nightmare in range." (8 Acorn-line), "Pulses damage to the nightmares in range." (Elder Stump, Grove Heart), "Rings out,
damaging every nightmare in range" (Bellflower, Hushbell). One form: "Pulses damage to every nightmare in range."

**S11 · Aura reach.** Warden texts say "Wardens in the 8 cells around it" (Acorn, Elder Stump, Nurse Log, Mother Log,
Prism Jar, Rainbow Prism); their unlock cards say "Wardens {touching} it". The glossary defines {touching} as exactly that:
use the token on both.

**S12 · Grove card nodes.** Legendary nodes (13) share one line: good. The others: "Adds the {dream} card {card:x}:
summary." (Bitter Hedges, Broad Strokes, Dead Wood, Elders, Seeping, Winding Roads) vs "Adds a {dream} card: {card:x}."
(Deep Promises) vs "Adds a {dream} card for area attacks: {card:x}." (Far Reach). Venom restates the whole card and its cost
(28 words). Family nodes end three ways: "Also adds the {card} card." / "Also adds its {dream} cards (listed below)." /
nothing. Perk nodes ("While carried: …") are the model: keep.

**S13 · Calling flares.** {flare} token on Lantern Alley and Lantern Parade; raw "flare / flares / flared" on Far Lights,
Lantern Road, Parting Light, Marsh Lights, Circling Light, Drawn In. Use the token everywhere ({free_hit} already does this
well on the Spore Print rows).

**S14 · Extra-stacks boilerplate in tips.** "Doesn't add {held} or {frost}; never past {full}; {static} stops 1 short of a
bolt" appears in 9 wordings across Gone to Seed, Mycelium, Overnight, Mixed Company, Second Verse, Ebb, Pass It Round,
Spore Huddle, Breathe It In, Millrace, Spent Light, Snare Line and the Calling rows Shared Caps / Rot. One Codex entry
("Extra stacks: cards that add stacks never start a status, never go past {full}, never add {held} or {frost}, and stop
{static} 1 short of a bolt") and a token in tips saves 12-18 words on each of ~12 tips and ends the variants.

**Shapes that already match (keep):** T9 family-stack trio (Charged Feathers, Pollen Beaks, Thunder Chimes); upgrade II
pairs (Guiding Light, Root Network, Rolling Thunder, Tender Care, Hunt's Rush, Mixed Grove); Bittersweet cost lines; all 27
Omens ("For the next 5 {drifts}: …"); Grove perk nodes; the Spore Print Calling rows' {free_hit} and "Bosses take half."

---

## 4. Every other flagged string

| Where | Now | Problem | Rewrite |
|---|---|---|---|
| Dream Nod Off tip | "… like {warden:chime_stone}, {warden:hushbell} and {warden:dreamcatcher}s, don't triggered it." | Typo. | "… don't trigger it." |
| Dream Straightaway diagram_caption | "Beside a straight stretch of 5 or more path cells: +30% and +0.5 range." | Wrong: the card is range only since 2026-10-23 (dream_state.gd:190). | "Beside a straight stretch of 5 or more path cells: +0.5 range." |
| Warden Windmill | "Every other spin gives 1 {frost} to each nightmare there." | Rule 4; the F.2 text says "Every 2nd spin". | "Every 2nd spin gives 1 {frost} to each nightmare on those cells." |
| dream_state.gd:3289 | "… More come from Let Go (Memory Grove)." | Old node name (ruling: Banish). | "… More come from Banish (Memory Grove)." |
| warden_panel.gd:443 (button) | "Make this the Eldest? Only one Warden can grow past rank V" | 12 words; "grow past rank" breaks N1. | Button "Make Eldest?"; tip "Only one Warden can go past Nurture rank V." |
| Grove Tending Hands | "the {eldest} can be nurtured to {rank} VII." | Bare {rank} (N1). | "… nurtured to Nurture {rank} VII." |
| Warden Grove Keeper | "Its Sprouts start at {rank} II." | Bare {rank}. | "Its Sprouts start at Nurture {rank} II." |
| Warden Mother Log | "… keeps its {rank}." | Bare {rank}. | "… keeps its Nurture {rank}s." |
| family_pick_screen.gd:447 | "yields %s, +%d per rank" | Bare rank. | "+%d per Nurture rank" |
| Dream Heartwood's Reach tip | "a Sprout keeps its rank when it grows" | Bare rank; raw grow. | "a Sprout keeps its Nurture {rank} when it {grow}s" |
| Grove branch: Frostfern | "… it freezes nightmares that have {damp}. Also adds the {card:deep_frost} card." | Frost doesn't freeze ({frozen} retired, F.1); Deep Frost retired from offers (F.2). (check) | "… it builds {frost} that bursts at {full}." (drop the Deep Frost line if it stays retired) |
| Warden Sunpetal; Grove branch: Sunpetal | "A beam that grows stronger …" | N1: "gets stronger" (its unlock card already does). | "A beam that gets stronger …" |
| Warden Stormcap | "Lightning that chains to 4 nightmares; jumps further and more often between those with {damp}." | Raw chain / jump (avoid list). | "Lightning that {jumps} between up to 4 nightmares, further and more often between those with {damp}." |
| Warden Thunderhead | "Chains to 4; every 3rd strike …" | Raw chain. | "{jumps} between up to 4; every 3rd strike …" |
| Warden Stormheart; Grove Ascension: Stormheart | "lightning jumps … (−15% per jump)" | Raw jump. | "its lightning {jumps} … (−15% per {jump})" |
| Dream Nestling, Wren's Nest, Starling Murmuration, Lightning Fence cards; Codex Arc | "extra damage to Phantoms", "catches Phantoms" | Raw name; the Warden texts use {nightmare:dandelion_seed}. | "{nightmare:dandelion_seed}s" |
| Warden Echo Hollow, Whispering Hollow | "echoes Reactions", "counts towards a Reaction chain" | Raw words; cards use {reactions} / {chain}. | "echoes {reactions}", "counts as a link of a {chain}" |
| Warden Torrent | "… that Soaks nightmares crossing it." | Status name as a verb. | "… that gives {damp} to nightmares crossing it." |
| Warden The Moon Moth | "Long-range shots that Expose" | Status name as a verb; its Grove node says "give {marked}". | "Long-range shots that give {marked}" |
| Warden Boulderback, Mossback (+ cards) | "nightmares with full {marked}" | Raw "full". | "with {full} {marked}" |
| Dream Momentum tip; Hunt's Rush II tip | "a kill never drops it"; "while kills keep coming" | Rule 17. | "a dispel never drops it"; "while dispels keep coming" |
| Dream Back-row Roots diagram | "The dim Warden touches the route" | "route" (avoid list). | "… touches the path" |
| Dream Hollow Ground diagram | "Planted in a moved hollow: +1 range." | "moved hollow" is a new term. | "Planted where you cleared an obstacle: +1 range." |
| Dream The Old Ones tip | "It never chains." | Raw chain. | "It never passes on." |
| Dream Gathering Storm; Overnight | "Needs another source of {jumps}. Each {jump} …"; "Needs another {family}'s status. A …" | Condition before the effect (rule 12). | Effect first; "Needs another source of {jumps}." as the last sentence. |
| Dream On the Beat | "Each once every 3 s." | Limiter with no subject (rule 3). | "Each Warden once every 3 s." |
| Dream Towering | "… deal 10% more damage for each Nurture {rank} above II." | T7: no cap on the face. | "… for each Nurture {rank} above II, up to +50%." |
| Dream Slow Burn (25) | "… and {static} bolts once its {static} is 1.5 s old." | "bolts" reads as a verb; two timers in one sentence. | "{spored} ticks deal 30% more once a nightmare has carried {spored} for 4 s; {static} bolts too, once its {static} is 1.5 s old." |
| Dream Lingering Splash (30) | "… leaves a patch for 2 s that deals 25% of that hit each second to nightmares in it. The patch gives no statuses." | Longest plain card. | "Every 3rd area attack a Warden makes leaves a 2 s patch: nightmares in it take 25% of that hit each second. No statuses." (24) |
| Dream Afterroot (28) | "When {held} ends on a nightmare, the next hit on it from another Warden within 2 s adds 5 {stacks} of {marked}." | Window mid-sentence (T3). | "For 2 s after {held} ends on a nightmare, the next hit from another Warden adds 5 {stacks} of {marked}. Each nightmare once every 4 s." |
| Dream Refrain (26) | "After a … Warden hits a nightmare, the next hit on it from another Warden within 2 s lands twice." | Same. | "For 2 s after a {family:bellflower} Warden hits a nightmare, the next hit from another Warden lands twice. Each Warden once every 4 s." |
| Dream Sparks Fly (25) | "… every 3rd hit another Warden lands on it within 2 s {jumps} half …" | Same. | "For 2 s after a {family:firefly_jar} Warden hits a nightmare, every 3rd hit another Warden lands on it {jumps} half to the nearest other nightmare." |
| Dream Momentum (28) | "A Warden attacks 6% faster for each hit in a row on the same nightmare, up to +45%. On a new nightmare, the bonus drains over 1 s." | T2 "per". | "A Warden attacks 6% faster per hit in a row on one nightmare, up to +45%. It drains over 1 s on a new target." |
| Dream Fruiting (26) | "… deal 6% more for each other Warden …" | Rule 1. | "… deal 6% more damage per other Warden …" |
| Calling Three Springs (:415, 32) | "… its {water} becomes pond too and its direct hits there spill. Churns still come from the two highest Nurture {rank} only." | Over 30; repeats Twin Springs word for word; "highest Nurture {rank} only" lacks its noun. | "A third {family:dewdrop} Warden {touching} either pond Warden joins the pond, as in Twin Springs. Churns still come from the two highest-Nurture-{rank} Wardens." |
| Calling Pile-On (:72) | "… calls a {free_hit} from each other such Warden there." | "such" sends you back up the sentence. | "… calls a {free_hit} from every other Nurture {rank} III+ Warden at that clump." |
| Calling Host Trees (:103) | "Shared Caps' Warden at each {mushroom} wears a cap: +15% {potency}. If its status deals no damage: …" | Opens with another row's name in the possessive. | "The Warden Shared Caps picks at each {mushroom} wears a cap: +15% {potency} (or, if its status deals no damage, +15% direct-hit damage on nightmares with {spored})." |
| Calling Rotburst (:125) | "… 2 {stacks} of each status the stepper had." | "stepper" is jargon. | "… of each status on the nightmare that stepped there." |
| Calling Heavy Air (:50), Fairy Path (:54), Sprout Beds (:63) | "without eating the {mushrooms}", "after it is eaten", "still eat" | "eat" (avoid list, RR.3). | "without using up …", "after it is used" |
| Calling Moth to Flame (:188) | see section 2 #11 | | |
| Codex Calling hit (:88, 55) | "… a Warden that attacks less often than that deals its attacks per second × those seconds of it (0.5 attacks a second on a 1 s hit: half). …" | A formula sentence. | "Each kind comes at most every so many seconds. A Warden slower than that deals only a share: its attacks per second × those seconds (0.5 a second on a 1 s hit: half). This is \"Slower Wardens deal less.\"" |
| icon_info.gd:35 Silenced (57) | "It can't use its abilities. A Watcher can't wake, … \nLasts while a Hushbell's song reaches it. A Silence (Hushbell's next form) or a Vespers toll keeps it 2 s longer." | Longest tooltip; "Vespers toll" names nothing the player has. (check) | Keep line 1; line 2: "Lasts while a {warden:hushbell} reaches it, +2 s from a {warden:silence}." |
| lesson_card.gd:224 | "Other statuses can set it off early as a {reaction}." | Rule 10. | "Other statuses can trigger it early in a {reaction}." |
| heartwood_gifts.gd:71 | "… lands with half again as many {stacks}." | RR.3 (half again = ×1.5). | "… lands with ×1.5 the {stacks}." (check) |
| Reaction Fever Dream | "Triggered when {combo:smother} ends on …" | The only "Triggered when". | "Triggered by a {combo:smother} ending on …" |
| Crowned Changeling | "trades places with the nightmare furthest ahead on its path within 3 {steps}" | Rule 11 (leader-type phrase) + raw "path". | "trades places with the nightmare up to 3 {steps} ahead of it, then turns and walks toward the start." |
| Grove Venom (28) | Restates the card and its cost. | The only card node that does. | "Adds the {dream} card {card:venom_bloom}: more status damage, weaker direct hits." |
| Grove Bellflower family | "Song that gives nightmares {drowsy} until they fall asleep." | Raw "asleep". | "… until they fall {asleep}." |
| Buttons pause_menu.gd:527 / :530 | "No save yet (one is written at each rest)"; "Save copied (%d KB): paste it in a message" | 9 words each. | "No save yet" / "Save copied (%d KB)"; the rest as the tooltip / toast. |
| Button warden_panel.gd:525 | "Permanent: the Sapling can't be sold or moved" | 8 words. | "Can't be sold" (G.2), tip "The Sapling is rooted for good." |
| Button warden_panel.gd:2132 | "Plant Sprout (%d) · at the next rest" | 7 words. | "Plant Sprout (%d)", sub-line "Next rest". |
| Buttons remember_screen.gd:1016, warden_panel.gd:1448 / :688, settings_panel.gd:408 | "Add to this run, free (Borrowed Branch)", "Swap places: again in %d s", "Sell %d Wardens? Press again", "Start over as a new profile" | Over 4. | "Add (free)" + tip names Borrowed Branch; "Swap in %d s"; "Sell %d? Press again"; "New profile". |

---

## 5. Patterns and rules (one line each, with the fix)

- **P1 Unlock prefixes eat the card:** 10-14 words of "can now {grow} into … ( cost ):" on 116 cards; show it as a header row (T10).
- **P2 One Warden, three texts:** unlock card, Warden text and Grove node describe the same Warden differently; one source text, copied.
- **P3 Reactions in two shapes:** finish F.2's switch to "Triggered by … Uses up …" on the 10 old ones (T11).
- **P4 Boilerplate small print:** the extra-stacks rules in 9 wordings on ~12 tips; one Codex entry + token.
- **P5 Windows mid-sentence:** "within 2 s" / "in the last 2 s" after the event (Afterroot, Refrain, Sparks Fly, Opening Fracture, Murmur, Fruiting, Chain of Lanterns); put "For N s after …" first (T3).
- **P6 "deal N% more" without "damage":** 7 cards; rule 1.
- **P7 Hits-only tips:** four wordings and one that redefines "direct hit"; use "Direct hits only." and the glossary.
- **P8 Bare {rank} / "rank" after N1:** Tending Hands, Grove Keeper, Mother Log, Heartwood Sapling, family pick screen, Heartwood's Reach tip, warden_panel.gd:443.
- **P9 Raw plurals and names bypass tokens:** Crowns of Thorns, Hatcheries, Magpie Perches, Rain Lilies, Nimbuses, Phantoms, Reactions; and `{token}s` / `{family}-{family}` glue.
- **P10 Raw mechanic words where a token exists:** chain / jump (Stormcap, Thunderhead, Stormheart, The Old Ones), flare (6 Calling rows), full, Soaks, Expose, Brimming, Dreamlight, Ascended.
- **P11 Bosses six ways:** only "(bosses N)" after the number, or "Not bosses." as its own sentence.
- **P12 Limiter subject first:** "Each Warden once a second", never "Once a second per Warden" or "Each once".
- **P13 "the nightmare furthest along the path" ×9:** add the Codex "Leader" entry, then rule 11 can land.

**Templates:** T1-T9 still hold. New:
- **T10 Unlock header:** header "{warden:A} → {warden:B} · {dew:cost}" (Ascension: "{family:X} {final_form} → {warden:B} · {dew:cost} · one per run"); body = the Warden text.
- **T11 Reaction:** "[Effect with numbers (bosses N)]. Triggered by [A + B | a {X} on a nightmare with N {Y}]. Uses up [Z]. [Limit.] [Not flyers.]" Models: Brittle, Flash Freeze, Wide Awake.
- **T12 Jump card:** "When [who] hits [condition], [share] of the hit {jumps} to [targets]. [Limit]." Model: Hammerfall.
- **T13 Grove card node:** "Adds the {dream} card {card:x}: [summary of 10 words or fewer]." Legendary: the fixed line as now.
- Best current models: T1 Spinning Corners, Rootbound; T2 Hedge Maze, Mixed Grove; T3 Hobble, Shattering Blow; T4 Needle
  Point; T7 Open Road, Finishing Blow; T8 Clump, Change Ringing; T9 Charged Feathers; Omen: Bountiful Night; perk node:
  Wider Choice.

## 6. What already works

- Plain Dream cards: 5 of 225 over 25 words, mean 17. Thirteen Grove legendary nodes, 27 Omens and the perk nodes each
  share one shape.
- Calling rows held their 30-word line: 1 over, and the Spore Print rows use {free_hit} and "Bosses take half." the same
  way throughout.
- The F.2 Frost texts landed on the Warden side (Frostfern, Hoarfrost, Tidecaller Warden texts, Brittle, Frostbite, Flash
  Freeze) and the T9 trio is word-for-word parallel.
- X1 Flashover face is in ("When a Warden {near} a {family:firefly_jar} Warden hits 2 or more nightmares with one attack,
  half {jumps} to the nearest one it missed."), and its tip names the Sparkler / Starburst exception.
- Bittersweet cost lines and upgrade II pairs make side-by-side comparison easy.

**Flagged: 20 ranked + 14 sibling sets + 51 table rows (85 items).**
