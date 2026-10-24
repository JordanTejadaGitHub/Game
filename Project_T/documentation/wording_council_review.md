# Wording Council: lead review (2026-10-22)

User, 2026-10-22: *"look for all the wording and make sure it looks right for gamers, if they can read and understand
the effect properly. Create a council just for this purpose."*

Read-only review. Nothing in the game was changed and nothing was run. The corpus was every live `.tres` text field
(378 Dream cards, 27 Omens, Wardens, nightmares, bosses, Reactions, obstacles, meta: 2,309 lines) and the string literals
of the UI, run, meta, tower and enemy scripts (1,162 lines), read as of HEAD a419102b plus the working tree.

## The council

| Seat | Reads as | Asks | Report |
|---|---|---|---|
| **N** New player | Never played tower defence or a roguelite | After one 5-second read, do I know what happens, to what, when, how much? | `wording_council/new_player.md` |
| **V** Genre veteran | Slay the Spire, Balatro, Bloons TD 6, Kingdom Rush | Does it stack, add or multiply, per hit or per second, count bosses? Where would two careful players play it differently? | `wording_council/veteran.md` |
| **C** Consistency keeper | The glossary | One name per thing, one phrasing per mechanic, capitals, tokens, text that disagrees with the data | `wording_council/consistency.md` |
| **S** Scan reader | Mid-fight, on a phone | Is the effect in the first words? Too long? Do sibling cards share a shape? | `wording_council/scan_reader.md` |
| **P** Plain English | Second-language reader, future translator | Idioms, words with two meanings, unclear "it", sentences built from pieces in code | `wording_council/plain_english.md` |
| Lead | | Merges the five, rules where they disagree, writes this file | this file |

The seat reports hold every flagged string with a rewrite (about 400 rows in total, overlapping). This file decides
and orders. Numbers in rewrites are the data's; where a seat wrote "(check)", the owner confirms the mechanic first.

## 1. Verdict

- **Most card text is fine.** Only 2 of the 261 regular Dream cards run over 25 words, and the plain one-effect cards
  read well to every seat.
- **The real damage is text that is wrong.** About 20 places state a number or rule the game no longer uses: stale
  diagram captions, a Codex that predates the Dew ×2 pass and the new family-pick timing, and a Poison lesson that
  teaches the old per-stack timer. A player who reads carefully gets punished. Fix these first (section 4).
- **Four words mean two things each:** Sleep / Asleep, Root (status, damage type, flavour), "every second" (once a
  second or every other one) and "set off / go off". Every seat tripped on at least one of these.
- **The hidden rules are the veteran's complaint:** Dream damage bonuses add or multiply under a ×4 cap, and Dream attack
  speed caps at +150%, but no screen says so (only one tip does).
- **Evolution and ascension cards are the long ones** (35 of the 37 cards over 25 words), because each opens with
  "X can now grow into Y (cost):" before the effect.

## 2. Where the council agrees

- **Diagram captions contradict their cards:** Crossroads (caption +40%, card and code 100%), Briar Crown (25% vs 60%),
  Thicket (+30% and an old rule vs 20%), Bitter Hedges. (N, V, C, S, P: all five.)
- **The Codex is out of date:** Wellspring cap 130 (code 260, `dew_catch.gd:12`), Perfect block +10 (now 20), "a family
  pick after each boss" (now after drifts 1, 10, 35, 60), Set Off, Night Chimes, Arc numbers. (N, V, C, S)
- **The Poison lesson is wrong:** `lesson_card.gd:222` "Each stack lasts 5 s"; the code and the glossary use one clock
  that ends 5 s after the last stack. (N, V, C, S)
- **The Reaction lesson is wrong:** "two full statuses" (lesson) vs "any two can" (chip) vs "enough stacks" (glossary,
  correct). (N, P)
- **Reroll and banish have too many names:** "Dream again" / "New cards" / "reroll"; "Let go" / "Banish", and "Let go"
  sits beside "Let it pass". (N, C, P)
- **"every second ring / pulse"** on Bellflower and Thorncoil reads as once a second. (N, P)
- **"chain" and "jump" are glossary links but lightning Warden text uses them as plain verbs** (Stormcap, Thunderhead).
  (N, C)

## 3. Where they disagree, and my ruling

| # | Topic | Positions | Ruling |
|---|---|---|---|
| 1 | Sleep vs Asleep | P: rename the Sleep status (Drowse). C: one name for the status, keep Asleep. N: confusing, no fix offered. | **Decided (owner 2026-10-22): Sleep → Drowsy.** {drowsy} shows "Drowsy" ("8 Drowsy", "a nightmare with Drowsy"); **Asleep** stays the stopped state. Role lines keep "Drowses". Plain "sleep" in rules text means Asleep and says {asleep}; flavour lines may keep "sleep". |
| 2 | US or UK spelling | text_style.md said US; text_pass.md and wording_review_2026-10-13 (both later) say UK; the text mixes both. | **Decided (owner 2026-10-22): UK** (neighbour, colour, grey, centre). text_style.md corrected. |
| 3 | Stating the ×4 card cap and +150% speed cap | V: on every damage card's tip and in the glossary. S: card faces are already long. | **Glossary and Codex entry ("Dream damage", "Dream speed"), linked from tips.** Each damage card's tip ends "Adds to" or "Multiplies with your other Dream damage." Not on card faces. This is a rule, not advice, so the no-hand-holding rule allows it. |
| 4 | "set off / go off" | P: "trigger" everywhere. S: fine if short. | **"trigger" in rules text** (Reactions, bolts, traps, "Crowned" lines). "goes off" stays in flavour only. |
| 5 | Lent cards that say "a Sporeling", "a Firefly" for the whole family | V: use the `{family:}` token. S: adds words. | **Use the token.** It is one word on screen and removes the wrong reading. |
| 6 | Evolution card opening line | S: make "X can now grow into Y (cost)" a header row. N, V: no view. | **Recommend to Roguelite Code and UI** as a layout change; wording alone can't fix it. Not blocking. |
| 7 | "status damage" vs "effect damage" | C: two names in use. | **"status damage"**: it names the thing the glossary already calls a status. |
| 8 | Root as flavour ("Its roots damage every nightmare in range") | P: rewrite on all 10 Root Wardens. | Rewrite: "It damages every nightmare in range." Root-the-damage-type is shown by its icon. |

## 4. Fix first: text that is wrong

The data wins unless its designer says otherwise. File evidence is in the seat reports (C §3 has file:line for each).

| Where | Says | Game does | Owner |
|---|---|---|---|
| `scripts/run/dream_state.gd` (**uncommitted working tree**, another chat's edit) | "Dream again Â·", "Next drift's Dew Ã1.2", "Omens pay Ã2" (48 lines) | Mojibake: the file was saved in the wrong encoding. HEAD is clean. | Whoever is editing dream_state.gd: re-save as UTF-8 before committing |
| Crossroads diagram_caption | +40% | 100% | Roguelite |
| Briar Crown diagram_caption | 25% | 60% | Roguelite |
| Thicket diagram_caption | +30%, "touches another Sprout" | 20%, current rule | Roguelite |
| Bitter Hedges diagram_caption | stale (V §6) | see card | Roguelite |
| `codex_data.gd:52` Wellspring | at most 130 a rest | 260 (`dew_catch.gd:12`) | Main |
| Codex Perfect block | +10 | 20 | Main |
| Codex family pick, Boss and Dreamlight entries | after each boss | after drifts 1, 10, 35, 60 | Main |
| Codex Set Off / Night Chimes / Arc | 3-4 Charge / 3 / 4 cells | 12 and 16 / 12 / 4.5 | Main |
| `lesson_card.gd:222` Poison | each stack lasts 5 s | one clock, 5 s after the last stack | Main |
| `lesson_card.gd:216` Reaction | two full statuses | the Reaction's stack count | Main |
| Grandmother Oak description | {dew:15} | dew_per_drift 30 | Tower Code |
| Heartwood Sapling description | 8, +4 | 16, +8 | Tower Code |
| Swift | +12% | 15% | Roguelite (check) |
| Beacon | "on top of" Exposure | replaces 25% with 50% | Roguelite |
| Honeysuckle | walls stop at 3 Sleep | cap 12 | Tower Code |
| Mossback, Boulderback | "with Exposure" | needs full Exposure | Enemy |
| Great Bell | card and Warden give different Charge thresholds | one value | Roguelite + Tower Code |
| Hunter's Patience | flyer bonus only in the tip | part of the effect | Roguelite |
| Charged Bloom | name says Charge | adds Sleep | Roguelite |
| "Never slowed" tag | implies Soak slows | Soak doesn't slow | Main |
| Waking Dreams cost | "can't be let pass" | not English: "can't be skipped" (check) | Roguelite |

## 5. Phrasing rules (new; add to text_style.md)

One fixed phrasing per idea. These come from what the best existing text already does (V §3, S §3, P §3).

1. **Damage:** "deals N% more damage" (Warden), "takes N% more damage" (nightmare). Add "from hits" when status damage
   doesn't count.
2. **Duration:** "for N s". Always say what a second application does: "Another one restarts the N s" or "Doesn't stack".
3. **Rate limits:** subject first: "Each nightmare once every N s", "Each Warden once every N s".
4. **Every other:** "every 2nd ring", never "every second ring".
5. **Multipliers:** "×N" only with its base: "×12 the damage of the Warden that triggered it". "Double / half" only
   for true ×2 / ×0.5.
6. **Chance:** "N% chance"; crit is "+N% crit chance".
7. **Distance:** "within N cells" (straight line); along the path, "N {steps}".
8. **Who counts:** family by `{family:}` token, one Warden by `{warden:}` token; for walls and Sprouts say "Walls
   don't count" / "Sprouts count".
9. **Bosses:** "(bosses N)" right after the number.
10. **Triggers:** "trigger", never "set off" or "go off", in rules text.
11. **Short forms** (S §2): "1 {held} for N s" (not "gains 1 Root and can't move for N s"); "the leader" for "the
    nightmare furthest along the path" (add "the leader" to the glossary).
12. **Order:** effect first, then condition, unless the condition is a single word ("Bends:"). Reactions open with what
    they do, then "Needs …".
13. **"it" rule:** when a Warden and a nightmare are both in the sentence, name one of them again instead of "it".

**Words to avoid in rules text** (full list P §3): set off, go off, spill over, pay out, shrug off, every second (=
every other), chain/jump as plain verbs, leak, tiles, square, route, Phantoms (for flyers), Rooted / Exposed / Drowses
as raw words (use tokens).

## 6. Terms: one name each

Decided in wording_review_2026-10-13 §1 and still leaking (C §1 has counts and places): tiles / square / route → cells
/ path; Phantoms → flyers; Rooted, Exposed Blow → tokens; "Let go" / "let-go" → Banish; Hints → Lessons.
**Reroll** (owner 2026-10-22) is the one name for redrawing the Dream cards: never "Dream again" or "New cards".

## 7. Localisation risks (later, before translation)

Sentences built from pieces in code: `drift_panel.gd:347-349`, `dream_state.gd:6146`, `icon_info.gd` (splits role lines
on ", " and adds or drops "the"), English-only plural helpers, about 30 `%s` fragments. Full list P §4. Not urgent for
an English launch; plan it before the first translation.

## 8. What already works

Plain one-effect cards ("For N s, …", "Every 3rd hit …"); the token links (every seat used them to check a status);
the Heartwood's "I" lines; Omen text (1 of 27 over 25 words); the "(bosses N)" pattern on Patient Roots and First Frost.

## 9. Next

1. Section 4 owners apply the wrong-text fixes (prompts in this chat's hand-off; owners paste them).
2. Owner calls: Sleep → Drowsy and UK spelling decided 2026-10-22 (section 3, rows 1-2). Reroll decided 2026-10-22 (section 6).
3. Section 5 rules go into text_style.md once the owner agrees, then a second pass over the seat reports' tables.

---

# Round 2 (2026-10-23): new cards, changed text, fix check

User, 2026-10-23: *"did you go over the new cards as well and changes?"* Round 1 read the text as of 2026-10-22 21:30.
Round 2 read only what is new or changed since a419102b: 11 new Dream cards (the ten hit cards and Undiluted), the
Dream / Calling text edits (3aafe1aa), the deepen pick, the Waystone line, the Reaction pool callouts, and the round 1
fixes (e31d8b8e, cef44886, ce75281f). Same five seats; reports in `wording_council/round2/`. Read-only; nothing run.

## R2.1 Round 1 fixes: 28 of 32 done

Not done (each spot-checked):
- **D1 Drowsy, partial:** `scripts/combat/support_log.gd:181` "Sleep applied: %d" and `:209` "applied %d Sleep".
- **M3 family picks, now wrong:** `codex_data.gd:27` says drift 60 brings a new family; since 2fcae6f4 it is the deepen
  pick. "Deepen" itself is never explained to the player.
- **R5 "every second", partial:** `tower/bellflower.tres` "Every second ring on a nightmare gives it {drowsy}" (the card
  was fixed, the Warden was not).
- **R6 family tokens, partial:** Settling Spores, Spore Huddle "a Sporeling"; Rude Awakening tip "Each bell".

Still wrong from section 4 and not yet sent: **Beacon** (`dream_beacon.tres`) says its bonus is "on top of" Exposure;
`enemy_statuses.gd:414` takes the larger of the two (`maxf(MARKED_EXTRA, marked_extra)`), so it replaces it. **Waking
Dreams** "can't be let pass". **Charged Bloom** adds Drowsy, not Charge. **Great Bell ascension node**
(`meta/grove/bellflower_ascension.tres`) "sets off all their Charged" (it strikes nightmares with 4+ Charged, half
damage). Old terms: "tiles" (straightaway_ii, weary_feet, fallen_log, rock), "Phantoms" for flyers (lightning fence,
nestling, starling murmuration, wren's nest, Codex).

## R2.2 New problems

| # | Where | Problem | Seats |
|---|---|---|---|
| 1 | **Undiluted** | "No {reaction} ever goes off", but no code blocks Reactions: only Last Chord, the offer filter and the two ×2 read `undiluted_on` (checked: nothing in `reactions.gd` or `scripts/enemy/`). "Each status's own effect grows" promises all six; only Poisoned ticks and the Charged bolt change. "goes off", "pay off". | V, N, P, S |
| 2 | **The Tallest Tree** | "the store", "add the store on top", three different "it"s; the per-attack and store caps sit in a 44-word tip; button "Make it the Tallest Tree" is 5 words. | N, P, S, V |
| 3 | **Hit cards don't share a shape** | Six shapes; the rank / form gate in four places; 8 of 10 drop "damage" from "deal N% more"; caps say "up to 40%" where older cards say "up to +30%". | S, C |
| 4 | **"Direct hit"** | New term, no glossary entry; five different "Hits only" tips. | S, C |
| 5 | **Stacking tips now wrong** | Ember Count, Grand Design, Crown of Leaves, The Long Walk say "Multiplies with your other Dream damage"; their Reaction parts now add into the Reaction pool (cap +300%, `REACTION_POOL_CAP`). No player text names the pool cap or the ×4 per-hit card cap. | V |
| 6 | **Invented words on hit cards** | Trophies "killing blows" (= dispels), Run Through "carries on" (Pinned says "pierces") and "within 2 cells along the path" (= {steps}), Standing Tall "court" / "base", Open Road "a straight", Measured Blow "its maximum health" (whose?), Clean Strike "your own family" (the hitter's). | N, P, C |
| 7 | **Finishing Blow tip** | "Best on the Wardens near the Heartwood" is strategy advice (no-hand-holding rule). | N, V, S, C |
| 8 | **"set off / go off"** | About 84 strings still, including new ones: Drowsy tooltip, Poison lesson, Warden panel "Reactions: set off N · fed N", Gone to Seed, Reprise, Nod Off, Mountain's Fall. | all |
| 9 | **A Calling evolution lost its trigger** | "A clump gives a {dose}…" no longer says who or when. | N, S |
| 10 | **Reaction callout "+N%"** (veteran, not spot-checked) | Shows the previous Reaction's pool (read before the new pool is computed), goes stale, never clears at rests; "+N% from K cards" counts pool parts, not cards. Code, not wording. | V |

## R2.3 Ruling: family names (3aafe1aa)

The user's text edits made the plain family name mean the whole family, with small print ("A Firefly is any Firefly Jar
form."). This replaces round 1 ruling 5 where the name differs from the base Warden: **Firefly** (base: Firefly Jar)
is clear as is. **Sporeling** and **Dewdrop** are also base Wardens' names, so a card meaning any form says "a
{family:sporeling} Warden" or keeps the Calling's small print in its tip; a card meaning only the base uses
{warden:sporeling}. "Bell" means any Bellflower form, as the small print says.

## R2.4 New phrasing rules (add to section 5)

14. **Direct hit:** a glossary entry, "A Warden's own attack landing: not statuses, Reactions, clouds or echoes." Tips
    then say "Direct hits only" in that one form.
15. **Hit cards use one shape** (S template T7): "[Gate] Wardens' direct hits deal N% more damage [condition], up to +cap."
16. **Card bonuses glossary / Codex entry:** how card damage adds and multiplies, the ×4 cap on one hit, the +300%
    Reaction pool, the +150% Dream speed cap. Stacking lines in tips must match it.
17. "dispel", never "kill" or "killing blow".

## R2.5 Next

Fix prompts go to Main Merger (Codex family pick, support log, glossary entries), Roguelite Code (new cards, stacking
tips, Calling text, Undiluted's rule hook), Tower Code (Bellflower Warden, Beacon, Charged Bloom, Phantoms / tiles in
Warden cards, Great Bell node if theirs) and Meta (Great Bell node). The "set off" sweep (84 strings) goes out as its
own prompt per owner.

## Round 2b (2026-10-23): the rebuilt Keeping Time evolutions

User: *"check the new evolution changes."* The lead read the uncommitted `scripts/combat/calling_paths.gd` (Keeping Time
rebuilt per dream_council_review.md 33: 20 live rows, 8 retired, the new drift 75 tier) against `keeping_time.gd`. No seat
agents (20 rows). Every number in the text matches its constant (TUNE_STEPS 6, WALL_STEPS 4, PRIME_STEPS 2 / DEPTH 3,
PEAL 4 / 8, STEADY_NEED 3, CRESC 25% / ×2, MIDNIGHT 12 / ×3 / bosses half, TWELFTH 6 rings / 3 others, DEEP III,
DOUBLE IV / 2, ALLEGRO V / 3 / cleared when a drift ends, SYMPHONY 4 / 6 s, CODA 4 s, TENOR 1 / s, ENSEMBLE 2 / 1 s).

| # | Row | Problem | Rewrite |
|---|---|---|---|
| 1 | Tier name **"Deepen"** (drift 75) | "Deepen" now names three things: Deepened cards, the drift 60 Deepen pick (a glossary entry since b4c17b1a) and this stage. | **Decided (owner 2026-10-23): Finale.** The drift 75 screen reads "Finale or Cross over"; code ids (DEEPEN, the "deepen" tag) may stay. |
| 2 | Carrying Tune | "Only a {toll} deals damage" reads as if the bell's own hits stop damaging. The shot cap (TUNE_MAX 4) left the tip. | "…rings nightmares up to 6 {steps} further down the path. Carried rings deal no damage; a {toll} they make does." Tip: "A shot carries to up to 4 nightmares." |
| 3 | Humming Walls, Carrying Tune tip | "pips" in player text; every other row says rings. | "Every 4 {steps} a nightmare walks beside Thornwalls counts as 1 ring: no damage, never the ring that makes its {toll}, once between {tolls}." Tip: "Not flyers." Carrying Tune tip: "Carried rings can make a {toll}; it lands like any other." |
| 4 | Steady Beat | One 30-word sentence; "since its last {toll} {tolls} every 3rd ring" needs a re-read. | "If one bell, or one group of {touching} bells, has done all the ringing on a nightmare since its last {toll}, it {tolls} every 3rd ring instead of every 4th, in full instead of at half." |
| 5 | Midnight Bell tip | "With Crescendo." is a fragment. | "Crescendo makes it stronger too. Starting rings don't count. Bosses take half." |
| 6 | Deep Tone tip | "Rings closer than half a second still count as one" reads as a new limit. | "Two rings on one nightmare within half a second count as one ring, doubled or not." |
| 7 | Allegro | "the 1 s wait" is never explained on the card. | "A nightmare can {toll} only once a second. When that stops a rank V+ bell's {toll}, the bell keeps it (up to 3) and spends it on the next ready nightmare it hits." |
| 8 | Accompaniment → Counterpoint, Tenor Bell, Sounding Board | "joined Warden" is used but never defined. | Accompaniment: "Other Wardens {touching} a bell join its song: their hits ring nightmares. When one of them makes a {toll}, the bell's {toll} lands and that Warden's hit repeats at half." |
| 9 | Counterpoint vs Coda | "note" means two things (a mark hung on a nightmare; a kept repeat on a Warden). | Coda: "After a Symphony, each Warden in it has its next hit within 4 s, on any nightmare, land again at half." |

## Round 2c (2026-10-23): Sporeling, Firefly and Dewdrop evolutions

User: *"review the rebuilt Sporeling, Firefly and Dewdrop Calling evolutions the same way as Bellflower's."* One reader
per Calling on the uncommitted `calling_paths.gd` (21 live rows each) against its class script. Full tables with a
rewrite per row: `wording_council/round2/evo_sporeling.md`, `evo_firefly.md`, `evo_dewdrop.md`.

**Numbers.** Sporeling 59 of 59 match. Firefly 54 of 55 (Bonfire's tip "at least double": a forced crit uses the
Warden's own `crit_multiplier` and only values at or below 1.0 become 2.0, `tower.gd:3391`; true only if no Firefly form
has a multiplier between 1 and 2, check). **Dewdrop is still being rebuilt** (`puddles.gd` changed during the review: the
new `EVO_*` constants landed, `WET_SECONDS` is gone), so its numbers are checked again once it is committed. Two Dewdrop
points hold either way: "Bosses half" on Stream, Long Current and Mudflats is untrue as written: `class_kit.gd:490` halves
the **cap** (0.35 → 0.175), not the slow, so a boss gets Stream's full 15%. Say "Bosses: at most 17.5% slower." Wet
Footprints' text says 2 s while its tip says the shared 4 s room: make them agree with the code.

**Wording, across all three:**
- **Undefined or doubled words:** Sporeling "limit" (four meanings), "Sprout bed"; Firefly "flare" (define once: "one hit
  from that glow's Firefly, damage only"), "glow" (the merged light vs one Firefly's own), "the usual {jump} limit" (the
  3 s cap is stated nowhere); Windfall's "pale cap" vs Host Trees' worn caps.
- **Text that says more or less than the code:** Toadstool Throne (text: every clump touching a final form; code: one per
  final form), Host Grove (only Poisoned and Charged damage), Sporefall (Sprouts count, unsaid), Retinue's "other", Circling
  Light (only on a return Marsh Lights counts).
- **"Bosses take half" missing** on Far Lights, Marsh Lights, Drawn In, Borrowed Light, Sightline (every flare and jump
  halves on bosses: `firefly_lights.gd:1064`, `:1080`, `:2197`).
- **Garbled:** Drifting Spores "a dose planted plants".
- **Rule 14:** Pile-On and several Firefly rows say "hit" where they mean a direct hit.
- **Thick Haze** (`sp_thick_haze`) is still live with its old text although the owner sent it back to the designer:
  retire it from offers until the new version exists.

---

# Gap round (2026-10-23): text the council had not read

User: *"run a Wording Council gap round on the text it hasn't read yet."* Round 1's extraction went one folder deep and
skipped `scripts/combat/` and short strings. This round read 329 lines of nested data (95 Grove nodes, 10 Crowned
Reactions, other nested `.tres`), 259 lines of `scripts/combat/` (Callings and their small print, Reaction / Kinship /
class strings; the evolution rows were done in 2b/2c) and 507 short UI strings (buttons, labels, headings). The Family
Blessings are all retired and the boss-pool files hold no text (boss text was in round 1), so neither needed reading.
Five seats; reports in `wording_council/gap/`. `briefs/extract_corpus.sh` now reads nested folders and `scripts/combat/`.

## G.1 Text that is wrong (spot-checked)

| Where | Says | Game does | Owner |
|---|---|---|---|
| Grove node Venom (`meta/grove/venom.tres`) | statuses and Reactions deal double damage | its card Venom Bloom: +40% Potency | Meta |
| The Heartwood's Crown | "Every other {node} is Grown." (reads as every 2nd node, and as an effect) | the unlock condition: every other node at its top level (`heartwood_memory.gd:437`) | Meta |
| Moon Moth node | reveals every Lurker; Wardens "in range" | reveals Hidden nightmares in its range; the range boost is for Wardens within 3 cells (check) | Meta |
| Crowned Nightbloom | triggered on an {asleep} nightmare | at full {drowsy} (`reactions.gd:1158`); leaves out its 4 s and the boss rule | Tower Code |
| Crowned Tempest | "Needs"; leaves out Ignite's 12 {spored}; raw "arc", "Ignite", "Thunderclaps" | also fires from Ignite's numbers on a Soaked nightmare at 8 {static} (`reactions.gd:324`) | Tower Code |
| Prismstorm, Starfall | a typed "8 {static}" | halves to 4 under the half-need rule: use `{stacks:…}` | Tower Code |
| Changeling | "within 3 cells" | measured along the path: {steps} | Tower Code |
| Acorn Calling, Volley (`callings.gd:21`) | "all Wardens next to the Acorn" | any Acorn-line aura Warden counts; the Wardens in its aura attack (`callings.gd:203-222`) | Roguelite |
| Whirligig Calling, Tailwind | no damage number | 60% damage within 2 cells (check) | Roguelite |
| Venom / Sporemother / Rootlight branch nodes | describe effects their Warden text doesn't (C §3, check) | | Meta |

Dropped after the spot-check: "Lodged Stone has no code" (veteran) is wrong: it is built in
`scripts/tower/dream_build_rules.gd:97` (`calling == "pebbling"`), just never named "lodge".

## G.2 Wording

- **Crowned Reactions** (9 of 10 over 25 words): open with "It …" before any nightmare is named; Tempest says "Needs"
  where the others say "Triggered by"; bosses and flyers handled five different ways (Still Pool, Changeling, Fever Dream,
  Fairy Circle unsaid). **No player text says what a Crowned Reaction is** (it replaces its base Reaction, shares its
  cooldown, counts as 2 chain links): add a Codex / glossary entry.
- **Grove Ascension and Memory Warden nodes** (14 over 25 words): 18-20 words of unlock and cost before what the Warden
  does. Effect first; the route as a fixed last line. They also glue "s" / "'s" onto tokens (`{warden:acorn}s`),
  which won't translate.
- **Callings small print:** "Every 5th acorn" reads as an Acorn Warden; Rootling's "turns to a nightmare" reads as
  "becomes one"; the Sporeling tip gives advice ("so it is weak against flyers"); all four tips over 40 words.
- **"Rooted"** (sell tag, `tower_seller.gd:192, :1007`) reads as the Root status: "Can't be sold".
- **"seed"** in the seed picker ("A seed", "Type a seed", "Dream it", "Which dream?") clashes with the Seeds currency and
  with "dream" = run: call it the **map seed** ("Map seed", "Type a map seed", "Use this map").
- **Old names:** the "Let Go" node (ruling: Banish), "Buffs" header (boosts), "path tiles" (cells), "Elite hunt" (Deeply
  Blighted), "Caught this run" (a status name). Node vs card names: One Line / Monoculture, Quickening / Hunt's Rush II;
  the card Forest's Edge shares Act 1's name.

## G.3 Buttons: one word per action

| Action | Now | Use |
|---|---|---|
| Close a panel | Close, Done | **Close** |
| Move past an info screen | Continue, Got it, Next | **Next** inside a sequence, **Continue** at its end |
| Start a run | Start, Start run, New run | **New run** on the title, **Start run** in the Grove |
| Confirm a group plant | Plant N (PC), Confirm (N) (phone) | **Plant N** on both |
| Grow | Grow into, Grows into | **Grow into X** on buttons; "grows into" in prose |
| Boss screen's one button | Face it, Continue, Prepare, Hunt it | **Continue**; "Hunt it" → **Hunt the X** (the object named) |
| Omen offer | Face an Omen or Clear Skies (6 words); phone: Omen or Clear Skies | **Choose an Omen** |
| Buttons with no object | Carry, Add, Auto, Title | **Carry perk**, **Add branch**, **Auto-drift**, **Title screen** |

## G.4 Localisation (later)

About 45 places build sentences in code: `%d time%s` plurals, `.capitalize()` (`coming_strip.gd:410`), verb agreement
(`gift_screen.gd:271`), string replace (`hud.gd:2018`), code comparing on-screen text ("Not enough Dreamlight"), tokens
with glued plurals. Full list: `gap/plain_english.md` §4. Plan before the first translation.

---

# Round 3 (2026-10-24): changes since the gap round, Dewdrop numbers, fix check

User: *"run Wording Council round 3 on everything changed since the gap round, recheck Dewdrop's numbers, and check the
2b, 2c and gap-round fixes landed."* Read: every `.tres` changed since 4630c8c2 (176 lines: 13 Dream cards, 27 Grove
nodes, Omens), the changed player strings in scripts (1,078 diff lines: drift shapes, Coming strip, rest report, Codex,
button words) and the Calling evolutions after their final pass (7573c842). Five seats; reports in `wording_council/round3/`.

## R3.1 Fixes: 13 of 18 done, 5 partial

Done: support log Drowsy, Codex Family pick + Deepen, Bellflower "every 2nd ring", Sporeling family tokens, Undiluted
(Reactions are now blocked in code, `reactions.gd:283`), Finishing Blow tip, stacking tips, Direct hit and Card bonuses
glossary entries, Beacon, the Finale label, Thick Haze, Grove node fixes (most), Callings small print.

Partial (spot-checked):
- **Hit cards:** 8 of 10 still "N% more" without "damage"; "direct hits only" in five wordings. The Tallest Tree: "spends up
  to 6" doesn't say 6 of what; tooltip "store" vs card "stored damage".
- **"set off":** 3 left: `dream_reaction_cards.gd:200, :203` ("Reactions set off N times"), Codex combo "Set Off" (`codex_data.gd:176`).
- **Crowned Reactions:** bosses and flyers still said four ways.
- **Buttons / old words:** "Face it", "Add, free", "Grows into" vs "Grow into", "Seed %d", "tiles" / "square" (6 places),
  "leak", "Pick a family" beside "Choose a Dream".
- **The Heartwood's Crown:** now "Grows when every other {node} is at its top level", which still reads as "every 2nd node"
  (the lead's own G.1 rewrite kept the ambiguity). Use: "Grows when all the other {nodes} are at their top level."
- **Keeping Time:** Deep Tone tip and Accompaniment only part-fixed; Coda still "keeps its note".

## R3.2 Numbers

Sporeling 63 / 64, Firefly 74 / 74, Bellflower 59 / 59, **Dewdrop 65 / 65** (all 21 rows against the committed
`puddles.gd`; boss slows now halve in code, so "(bosses 7.5%)" is true; Wet Footprints is retired). The one mismatch:
**Retinue** tip "At most Clump's 3 Wardens", code `RETINUE_MAX 2` (`spore_print.gd:179`, `:1199`). Every checked drift
shape and Omen number matches.

## R3.3 New problems

| # | Where | Problem | Seats |
|---|---|---|---|
| 1 | **"Finale"** | Now names two things: the Calling's drift 75 stage and the Spire block finale on screen (`drift_panel.gd:494` "Finale (drift %d): clear it clean for a Rare dream", rest report "Finale cleared clean"). The lead missed the Spire use when recommending it. | C, V |
| 2 | **Drift shape "Stream"** | Also Dewdrop's Stream style evolution and part of the Omen "Swift Stream"; the rest screen shows the shape and "Your Dreams this block" side by side. "Packs" makes "a pack" in Gathering Storm / Struck Twice tips read as "only in Packs drifts". | N, C, P, V |
| 3 | **Coming strip numbers** (`shape_rows.gd:79-84`) | No nouns: "Packs: 4 × 7", "Single file: 18, 1.6 s apart". Use "4 packs of 7", "18 nightmares, one every 1.6 s", "9 nightmares, 4 Deeply Blighted". "4 × 7" shows the largest pack and counts arrivals, not split bodies. The rest report lists a boss drift as "Stream". | N, V |
| 4 | **Drift shapes unexplained** | No glossary entry for the shapes or the 3-leaf pack cap (`run_state.gd:247`); the cap silently overrides Leaf Fall, Brittle Night and Giants' Walk's +1 leaf; Giants' Walk turns Few and tough into a Stream unsaid; Omen texts leave out pack_fill 8 and Restless Wind's "between packs". | N, V |
| 5 | **Lantern Alley** | Garbled: "A glow entered within 4 {steps} of the last {flares} the nightmare: …" | N, S, P |
| 6 | **Token nouns used as verbs** | {tolls} shows "Tolls" where a verb goes: Steady Beat "since its last Toll Tolls every 3rd Ring", Last Bell, Halfway Bell. Also {water} can't be counted ("a water", "two water"): say "a stretch of {water}". | N, P |
| 7 | **Glossary entries contradict rows** | Codex "Free hit" says at most once a second, but Elder Cap and Trampled Ground go past it; "Ring" says only bells ring, but Accompaniment and Carrying Tune ring without a bell hit; "Flare" says "in its glow" but Lantern Parade's flare lands outside any glow. Host Trees' {potency} promises stronger slows / longer Root; only damage rises. | C, V |
| 8 | **Undefined speed words** | Unfettered and the Calling hit Codex entry use "clock", "share", "bonus hits", "slow Wardens"; 18 evolution tips end "Slower Wardens deal less." with nothing defining it. | N, C, P, S |
| 9 | **Rows that scan worse than before** | Constellation, Show the Way, Full Glow; Toadstool Throne (is the Warden or the clump 10+ drifts old?); Host Trees reads as a Warden named "Shared Caps"; Moth to Flame's +50% lost "on that nightmare"; Pyre / Banked Fire "with 50 dispels on gold path crits". 6 tips over 40 words (Clump 49 … Pyre 44). | S, N |
| 10 | **Ascension nodes** | The route moved last, but each still opens "Unlocks X, the strongest form…" (10 words) before the effect; 8 of them 43-57 words. Runtime button "Grow into The Great Bell" (capital "The", 5 words). | S |

**Ruling on "Works for: … Safe / A bet" tips** (flagged by N, P, S as advice): not a break. It is the house convention
on 127 cards, asked for on every lent card by the card council (dream_council_review.md), and is neither a "Leads to" nor
a "Combos with" line. Kept.

## R3.4 Owner calls

1. **Finale clash:** keep "Finale" for the Calling stage and rename the Spire one on screen to **"Last drift"** ("Last
   drift (drift %d): clear it clean for a Rare Dream", "Last drift cleared clean"), or rename the Calling stage again.
   Recommended: rename the Spire one; "Last drift" is the plain description.
2. **Stream clash:** rename the drift shape. Recommended **"Steady"** (it is the even, unclumped arrival; "Mixed" would
   echo the card Mixed Company).

**Decided (owner 2026-10-24):** 1. the Spire block finale shows as **"Last drift"**; the Calling's drift 75 stage keeps
**Finale**. 2. the drift shape Stream is **Steady** (code id `STREAM` may stay); Dewdrop's Stream evolution and Swift
Stream keep their names.
