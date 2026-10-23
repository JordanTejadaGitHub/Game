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
