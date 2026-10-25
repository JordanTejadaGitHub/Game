# Scan reader: round 2026-10-25

Seat: mid-fight, on a phone. Effect in the first words, one condition, numbers findable, siblings in one shape.
Read: corpus_resources.txt (NEW only, RETIRED skipped), corpus_ui_diff.txt ("+" lines), frost_draft.md §4-5,
frost_review_player.md §6, the live Reaction / Crowned texts (resource/reaction), icon_info.gd, codex_data.gd and the
Frost Warden .tres files as they stand in the working tree now (another chat has already put draft Frost text into
frostfern / hoarfrost / tidecaller / windmill .tres, icon_info.gd:29 and codex_data.gd:127-130; quoted as "live").
Word counts: a token counts as one word (nested `{dew:{grow_cost:x}}` = one).

## 1. Top 10

| # | Where | Now | Problem | Rewrite |
|---|---|---|---|---|
| 1 | **Frost Reactions** (draft §4, player §6): Brittle, Frostbite, Rime / Blizzard | "A Frostburst on a nightmare with 10 {marked} spends it: for 4 s it resists nothing (bosses 2 s)." / "A Frostburst on a nightmare with 12 {spored} spends half of it and deals 3% …" / "A Frostburst on a nightmare with 8 {damp} spends it: the burst reaches 2 cells …" | The three share a shape with each other, but with **no** existing Reaction. All 11 base Reactions open with the effect and then "Needs A + B. Uses up the X."; all 10 Crowned open with the effect and then "Triggered by a {combo:X} on a nightmare with N Y." The drafts open with the trigger (rule 12 broken), say "spends" (house: "Uses up"), hard-code 10 / 12 / 8 (house: `{stacks:need_*}`, round 2 T9), and Brittle's "spends it: … it resists" has two "it"s for two things (rule 13). Use the **Crowned shape**: a Frost Reaction is set off by an event (the burst) plus one status, exactly like Prismstorm "Triggered by a {combo:shatter} on a nightmare with …". It also avoids writing a Frost number, which differs for bosses (15) and Brimming (20, the Reaction still at 10). | **Brittle:** "For 4 s the nightmare has no resistances and no blight coat (elites 3 s, bosses 2 s). Triggered by a {frostburst} on a nightmare with {stacks:need_marked} {marked}. Uses up the {marked}." (27) · **Frostbite:** "Deals 3% of the nightmare's max health (elites 2%, bosses 1%). Triggered by a {frostburst} on a nightmare with {stacks:need_spored} {spored}. Uses up half the {spored}." (25) · **Rime / Blizzard:** "The {frostburst} reaches 2 cells, hits up to 6 and gives each 2 {frost}. Triggered by a {frostburst} on a nightmare with {stacks:need_damp} {damp}. Uses up the {damp}." (27) · Optional fixed last line on all three: "Each nightmare once every 6 s." (rule 3). |
| 2 | **{frozen}** glossary (icon_info.gd:27), Codex `{frozen}` (codex_data.gd:127), Hoar Fog Kinship line (codex_data.gd:306) | "Frozen: Frost stops it for a moment." / "Frost's {held}: a Dewdrop-family Warden's freeze adds 1 {held} …" / "a nightmare that stays 2 s in Mistveil's fog is {frozen}: it gains 1 {held} (0.75 s)" | Once Frost is a status, "Frost stops it" contradicts the one rule players must learn ("Frost stops nothing", player §1). The Codex entry still describes the retired Dewdrop freeze; Hoar Fog still describes the old freeze. {frozen} is still used by Still Target I/II, dewdrop_ascension and dream_keywords.gd: a player sees "Frozen" and "Frost" side by side and reads them as one. | Retire {frozen} on screen; where those texts mean Root say "1 {held} for N s" (rule 11). Hoar Fog: "The fog gives 1 {frost} a second to nightmares inside, stopping 1 short of {full}." (check: draft §2 Hoar Fog numbers). |
| 3 | **Splash Wardens' status line** (siblings): rain_lily, puffball, hoarfrost (live), dewdrop (tower), the four unlock cards | Rain Lily "The nightmare it hits takes N {damp}" · Puffball "The nightmare it hits takes N {spored}" · Hoarfrost (live) "give N {frost} to the nightmare hit" · unlocks "only the one hit gains {damp}" / "the one hit gains N {spored}" / "the nightmare hit gains N {damp}" · **Dewdrop tower** "A small splash that hits a few nightmares and gives them {damp}." | Four wordings for one rule (section 37: only the nightmare hit gets the status). "Takes N {damp}" reads as damage taken. The Dewdrop tower text still says every splashed nightmare gets {damp}: wrong after section 37 (check; dewdrop.tres is not in the changed list). | One phrase, card and Warden alike: **"The nightmare it hits gains N {status}."** Dewdrop: "A small splash. The nightmare it hits gains {damp}. Nightmares with {damp} take 20% more damage from water hits." Hoarfrost: "A splash of frost shards. The nightmare it hits gains {field:hoarfrost.status_stacks:count} {frost}. +20% crit chance on nightmares with 5+ {frost}." (21) |
| 4 | **dream_hoarfrost** (40 words), **dream_old_mountain** (44) | Hoarfrost: "…splashing frost shards; the nightmare hit gains {damp}, up to N {stacks}; at N {stacks} it is {frozen}: it gains 1 {held} and can't move for N. More crits on nightmares with {held}." | The two longest card texts in the round (cap 25). Hoarfrost's unlock also now contradicts its live Warden text (Frost, crit vs 5+ Frost, no {damp}, no freeze): wrong once Frost lands. Old Mountain keeps the long form rule 11 replaced. Both have two colons (T5: one clause after the colon). | Hoarfrost: "{warden:frostfern}s can now {grow} into {warden:hoarfrost}s ({dew:{grow_cost:hoarfrost}}): frost-shard splashes; the nightmare hit gains {field:hoarfrost.status_stacks:count} {frost}." (14) · Old Mountain: "Any {family:pebbling}-{family} final form can ascend into {warden:old_mountain} ({dew:{grow_cost:old_mountain}}, one per run): a boulder every 3 s; the nightmare hit gains 1 {held} for 0.5 s. Always crits on {held} or {drowsy}." (31; check "on {held}" = nightmares with) |
| 5 | **Frost thresholds** "At 10" (player §6 Codex Frost, Frostfern) and Frostfern (live) | "At 10 {frost} a nightmare bursts …" / live: "When a nightmare's {frost} is full it bursts, …" | "10" is false on bosses (15) and with Brimming (20). The live text has the right idea but a raw "full" and a "When…" opening that delays the number. Charge's glossary already models the fix: "At {stacks:cap_static} stacks ({stacks:bosscap_static} on bosses)". | Frostfern: "Each hit gives {field:frostfern.status_stacks:count} {frost}. At {full} {frost} a nightmare bursts, hurting it and the nightmares beside it." (18) · glossary: "At {stacks:cap_frost} stacks ({stacks:bosscap_frost} on bosses) …" (new stack kinds, check). |
| 6 | **"set off"** is back (rule 10): afterglow / spent_light cost, Spattered tip, Long Winter | "The {stacks} it gives can't set off a {reaction} for 2 s." · "Their {stacks} set off a {reaction} on a nightmare at most once every 2 s." · "Frostbursts can set off one more burst in a row." | Avoid-list word in three new texts, all in one round. | "The {stacks} it gives can't trigger a {reaction} for 2 s." · "Their {stacks} trigger a {reaction} on each nightmare at most once every 2 s." · Long Winter: "One more {frostburst} can follow in a row." (check the chain count) |
| 7 | **Windmill** (live), draft and player § | live "Every other spin gives 1 {frost} to each nightmare there." · draft "Every second spin …" | Rule 4: "every 2nd", never "every second" (draft) nor a third form "every other" (live, player). Bellflower and Thorncoil were fixed to "every 2nd" in round 2. Live line also says "+35% damage for each path cell" where T2 prefers "per". | "Bigger, faster blades: +35% damage per path cell past 2 among the 8 around it. Every 2nd spin gives 1 {frost} to each nightmare there." (24) |
| 8 | **Headlong** description (27 words) | "Before any {drift} but a boss {drift}, you may Rush it: it arrives in a third of its time and pays all its {dew} as it starts." | Over 25; opens with a condition and an "any … but" exception; the Rush button's tooltip (drift_panel.gd) already says it better and in effect-first order. | "Rush a {drift}: it arrives in a third of its time and pays all its {dew} as it starts. Not boss {drifts}." (21; word for word with the button tooltip) |
| 9 | **Undiluted** description (24 words, 6 fragments) | "No {reactions}. {spored} and {static} deal double. {damp}: all hits +25%. Full {drowsy}: {asleep} 2 s. {marked} from 5 stacks. {held} ending: 50% again." | Under the cap but unscannable: six rules, three shapes ("deal double", "X: effect", "from N"), a raw "Full" (should be {full}), "50% again" only defined in the tip (36 words). | "No {reactions}. Instead: {spored}, {static}: double damage. {damp}: hits +25%. {full} {drowsy}: 2 s {asleep}. {marked}: works from 5 stacks. {held}: repeats 50% as it ends." (one "X: effect." shape per status; tip keeps the "50% again" definition) |
| 10 | **Cold Snap** (codex_data.gd:130, draft §4) and Frost glossary (icon_info.gd:29) | "After a {frostburst}, the nightmare's other statuses stop wearing off for 1.5 s (bosses 0.5 s)." · draft "… for 2 s (bosses 1 s)" · Frost: "…it bursts in a {frostburst}: damage around it, 1 Frost to the nightmares beside it, and a {cold_snap}." | Numbers differ between draft and Codex (check which is current). "Stop wearing off" vs "don't run down" (this round's Still Water fix, calling_paths.gd:424): one idea, two phrases. Frost glossary's "damage around it" hides that the bursting nightmare is hit too (player §6 point), and it lacks the "can trigger {reactions}" line every sibling status glossary ends with. | Cold Snap: "For 1.5 s after a {frostburst} (bosses 0.5 s), the nightmare's other statuses don't run down." (T3 window form; check numbers) · Frost: "Builds up on a nightmare. At {full} it bursts in a {frostburst}, hurting it and the nightmares beside it. Its {frostburst} can trigger {reactions}." (22) |

## 2. Other flagged strings

| Where | Now | Problem | Rewrite |
|---|---|---|---|
| Brittle (both drafts) | "(bosses 2 s)" | Elites' 3 s (draft §3) missing from both texts. | "(elites 3 s, bosses 2 s)" as in #1 |
| Brittle | "resists nothing" / "no resistances or blight coat" | "blight coat" appears nowhere on screen (not in icon_info or Codex). | Use the on-screen name for the coat, or add a glossary term (check) |
| Rime / Blizzard (player) | "… reaches 2 cells, hits up to 6, gives 2 {frost}." | Three-item list without "and"; reads as a fragment. | "… reaches 2 cells, hits up to 6 and gives each 2 {frost}." |
| Deep Frost (draft / player) | "Frostbursts deal 50% more and Cold Snap lasts 1 s longer." / "…statuses pause 1 s longer after one." | Draft lacks "damage" (rule 1); player's "after one" is a dangling "one". Both terms exist as tokens; use them. | "{frostbursts} deal 50% more damage, and each {cold_snap} lasts 1 s longer." (12) |
| Deep Frost (tree now) | "{family:dewdrop} Wardens' hits deal 45% more damage to nightmares with {held}." | Will be replaced by the Frost text; until then "hits" (T7 says "direct hits"). | Replace with the Frost text above |
| Codex Frostburst (codex_data.gd:129) | "… Up to 3 bursts in a chain." | Draft: link 3 is the last after the first burst, i.e. 4 bursts (check off-by-one). "chain" as a word players see (avoid list for verbs; noun OK). | "… Up to N {frostbursts} in a row." with the checked N |
| Hoar Fog (player) | "… up to 9." | 9 is cap - 1 only for normal nightmares (bosses 14, Brimming 19). | "… stopping 1 short of {full}." |
| Gust / Zephyr / Samara / spread cards | (no text) | Copied Frost stops at cap - 1 (draft §1): invisible rule, "why is it stuck at 9?" (player §2). | Tip line on each: "{frost}: never the last {stack}." |
| First Frost card | tree: display_name "First Grip"; draft: "First Chill" | Two new names for one card. | Pick one (consistency seat; check with the owner) |
| Hoarfrost (live) | "…against nightmares with 5 {frost} or more." | Starlit Aim / Patient Aim say "on nightmares with"; "5 or more" = "5+" (Rootbound pattern "3 or more"). | "+20% crit chance on nightmares with 5 or more {frost}." |
| Tidecaller (live) | "Every 6 s a great wave gives {damp}, drags nightmares back 1 cell and gives N {frost} to those with {frost}." | Fine (T4); "gives … gives" twice. | "Every 6 s a great wave gives {damp} and drags nightmares back 1 cell; those with {frost} gain N more." |
| Codex "Nearly full" (codex_data.gd:138) | "Starlit Aim, Called Shot and Guiding Light use it." | Called Shot is RETIRED in this corpus. | "Starlit Aim and Guiding Light use it." |
| Tangled Lightning | "{family:firefly_jar} attacks also {jump} to 1 nightmare carrying {static}, spending 3 of that nightmare's {static}." | Off its siblings' shape (Conductive Soil, Guiding Light: "A … Warden's direct hit on …"); "carrying" vs "with", "spending" vs "uses up". | "A {family:firefly_jar} Warden's attack also {jumps} to 1 nightmare with {static}, using up 3 of its {static}." (check "attack" vs direct hit) |
| Eddy | "…copy half of each of the target's statuses' {stacks} to the nearest other nightmare." | Triple possessive; hard to parse at speed. | "{family:whirligig} Wardens' hits copy half the {stacks} of each status on the target to the nearest other nightmare. Each Warden once a second." |
| Conductive Soil | limit "Each Warden once a second." only in tip | T9 / R12: the limiter goes on the card face (Charged Feathers, Pollen Beaks, Resonance do it). | Move "Each Warden once a second." to the description (24 -> 29; drop "for half" to the tip if needed) |
| Chain Bloom | "…are ×1.5 as wide." | "×1.5 as wide" is a mixed form (rule 5). | "…are 50% wider." |
| Grandfather Stump | "…up to +45% faster in all." | "+" and "faster" both carry the increase. | "…up to 45% faster in all." |
| Sweet Harmony | "{harmonies} (both kin hit one nightmare within 1 s) deal 50% more and can come every 1.5 s, not 2 s." | Parenthetical repeats the tappable token's glossary; "50% more" without "damage" (rule 1). | "{harmonies} deal 50% more damage and can come every 1.5 s, not 2 s." (14) |
| Puffball (tower, 28 words) | "Its puffs burst over a tile. …" | Over 25; "tile" is on the avoid list (cells). | "Its puffs burst over a cell. The nightmare it hits gains N {spored} and can hold up to N; the others nearby take its damage." (check) |
| dream_puffball (26) | "…hurting every nightmare there; the one hit gains N {spored} and can hold N." | One over; same rule as #3. | "…: its puff bursts over N, hurting every nightmare there; the nightmare hit gains N {spored}, up to N." |
| Heartwood's Reach | "Opens clearing, and your next 5 clears are free." | "Opens clearing" is jargon; the old "You can clear obstacles" was plainer. | "You can clear obstacles, and your next 5 clears are free. …" |
| Slow Burn (25) | "{spored} ticks deal 30% more on a nightmare that has carried {spored} for 4 s, and {static} bolts once its {static} is 1.5 s old." | Two conditions, two shapes; "carried" needs the tip. | "{spored} ticks deal 30% more damage once {spored} has been on for 4 s; {static} bolts, once {static} has been on for 1.5 s." (check "on with no gap") |
| Unfettered tip (30) | "…slower than a Calling hit's clock (1, 3 or 4 s) deals only a share. … take their share." | "clock" and "share" still undefined (R3.3 #8). | "Without it, a Warden that attacks less often than its Calling hit comes (every 1, 3 or 4 s) deals less. …" |
| Moth to Flame (calling_paths.gd:187) | text "A Firefly's hit … 4 more hits: +50%." / tip "4 more direct hits" | Card and tip disagree on hit kind. | "A Firefly's direct hit …" |
| Pyre / Banked Fire (calling_paths.gd:190, :194) | "…every 3rd direct hit crits from a Warden that has made 50 gold dispels." | The subject ("from a Warden …") lands after the verb. | "…every 3rd direct hit from a Warden that has made 50 gold dispels crits." |
| Hailfall tip (33) | "…Its own hit keeps its strength against nightmares that resist Area." | "its own hit" / "its strength": which Warden, which hit (rule 13). | "Against nightmares that resist Area, the Warden's own hit is not weakened." |
| Starlit Aim | "{Heavy} Wardens …" | Capitalised token; check it renders as a linked term, not raw braces. | (check) |
| Boulder prompt (boulder_placement.gd) | "Forest Floor: click open ground to place %s (Esc to look round first)." | Phones: no click, no Esc; parenthesis; "look round" idiom. | PC as is minus parens; phone: "Forest Floor: tap open ground to place %s." |
| Splash + status tip (warden_header_view.gd) | "Splash + status: hits one nightmare and splashes the ones beside it, giving them its status too (Spattered)." | Parenthesis at the end of a 17-word tip. | "…giving them its status too, from Spattered." |
| Codex Splash (codex_data.gd:133) | "Only the nightmare hit gets the Warden's status." | True only without Spattered. | "Only the nightmare hit gets the Warden's status, unless you have Spattered." |

## 3. Patterns and templates

- **Frost Reactions need one sibling shape, and it already exists:** the Crowned form (T10 below). Never trigger-first.
- **"Spends" is creeping in** (Frost drafts, Tangled Lightning "spending"): the house verb is "Uses up".
- **Splash status: one phrase** "the nightmare it hits gains N {status}" (cards and Wardens); never "takes N {status}".
- **Stack thresholds as tokens:** never "At 10" for a capped status; `{full}` or `{stacks:cap_x}` with bosses.
- **Rule 4 slips with every new Warden:** "every second / every other" -> "every 2nd".
- **One idea, one phrase for pauses:** "don't run down" (Cold Snap, Caught, Bound and Burning, Dreamcatcher still say "wear off").
- **Parenthetical definitions of tappable tokens** (Sweet Harmony): drop them; the token is the definition.

Templates (T1-T9 kept; scan_reader.md §3, round2 T7, round3 T8, roguelite T9). New this round:
- **T10 · Event-triggered Reaction** (Crowned, Frost): "[Effect with numbers] ([elites N,] bosses N). Triggered by a
  {X} on a nightmare with {stacks:need_y} {y}. Uses up the {y}." Models: Prismstorm, Wide Awake, Still Pool.
- **T11 · Splash Warden:** "[Shape, ≤ 5 words]. The nightmare it hits gains N {status}. [One extra]." Models: Rain
  Lily (after the verb fix), Hoarfrost as in #3.
- **T12 · Status giver on an existing attack:** "Every Nth [attack word], [who] gains N {status}." Model: Windmill #7,
  Needle Point / Loose Stones ("Every 3rd direct hit from a {family:x} Warden …").

Sibling check, Frost Wardens: Frostfern (single target) and Hoarfrost (splash) fit T11 / "Each hit gives N" once #3
and #5 apply; Windmill matches Pinwheel's "the 8 cells around it" and Needle Point / Loose Stones' "every 3rd"
form once #7 applies; Tidecaller is T4 and fine. Whirligig cards (Carried on the Wind, Eddy, Hairpin Winds, Spinning
Corners) all open with `{family:whirligig}` now: good.

## 4. Length stats (changed texts this round + Frost drafts)

Word counts OLD -> NEW (resources): Hoarfrost unlock 42 -> 40, Old Mountain unlock 41 -> 44, Headlong 21 -> 27 (tip 41 -> 40),
Puffball tower 22 -> 28, Puffball unlock 29 -> 26, Undiluted 12 -> 24 (tip 14 -> 36), Unfettered 17 -> 11 (tip 16 -> 30),
The Tallest Tree 38 -> 22 (tip 31 -> 26), Wide Petals 15 -> 7, Growth Rings 24 -> 18 (tip 26 -> 31), Conductive Soil 12 -> 24,
Slow Burn 17 -> 25, Sweet Harmony 14 -> 21, Clean Strike tip 17 -> 28, Heartwood's Reach tip 18 -> 27; new: Hailfall 21 / tip 33,
Spattered 18 / tip 33.

- Cards over 25: **5** (Old Mountain unlock 44, Hoarfrost unlock 40, Puffball tower 28, Headlong 27, Puffball unlock 26).
- Tips over 40: **0** (Headlong 40 sits on the cap).
- Longest 10: Old Mountain unlock 44, Hoarfrost unlock 40, Headlong tip 40, Undiluted tip 36, Hailfall tip 33, Spattered
  tip 33, Growth Rings tip 31, Unfettered tip 30, Puffball tower 28, Clean Strike / Towering / Hairpin Winds tips 28.
- Frost drafts (draft -> player): Codex Frost 24 -> 23 (live icon_info 25), Cold Snap 16, Frostfern 15 -> 17, Hoarfrost
  18 -> 17, Tidecaller 21 -> 21, Windmill 18 -> 13 (live 24), Hoar Fog 10 -> 13, Brittle 19 -> 19, Frostbite 21 -> 19,
  Rime / Blizzard 19 -> 22, Deep Frost 11 -> 13, Long Winter 10. All under 25; the T10 rewrites in #1 are 25-27 (Reaction
  texts sit with base Reactions at 20-50 words, read in the Codex, not on a card face).

## 5. What already works

- T9 landed: Charged Feathers, Pollen Beaks, Resonance share one shape with the limiter on the card face.
- "Every 3rd direct hit from a {family:x} Warden" (Needle Point, Loose Stones): one clean sibling pair.
- The Tallest Tree 38 -> 22, Wide Petals 15 -> 7, Unfettered 17 -> 11, Growth Rings 24 -> 18: shorter and effect first.
- Forest Floor's "Now: …" prefix; Rush / "Rush on" toggle says its state in words; shape rows now carry nouns
  ("Steady: 30 nightmares", "4 packs of 7"); "Needs %d Reactions triggered this run (you have %d)" reads as a need.
- Frost drafts: every text under 25, effect first on the Wardens, no hand-holding; the player seat's "hurting it and
  those beside it" fix is right. "Works for / Safe / A bet" tips kept as the house convention.

Flagged: 10 top + 28 table = **38**.
