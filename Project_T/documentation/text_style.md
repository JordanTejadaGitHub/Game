# Text Style

How every player-facing string in Heartwood TD is written: buttons, tooltips, Warden and nightmare
descriptions, Dream and Omen cards, Codex and glossary entries, whispers, toasts, settings. Added
2026-09-30 (user: "look through all the texts … check for the right capitalisation and formatting";
"a bit too much hand holding"). Every chat that writes player-facing text follows this; the audit
list at the end tracks the first sweep.

## Voice

- Short and plain. Say what it does, in the fewest words. No hand-holding: **buttons show the
  action and its price; explanations live in tooltips and the Codex**.
- No parenthetical explanations on buttons: not "(you have 0)", "(half during a drift)",
  "(and +40 when it grows into Moonstone)". Those go in the tooltip, or are cut.
- Whispers and flavour lines are the only places for mood; everything else is information.
- US or UK spelling: **US** throughout (color, gray… in data; the UI never shows either much).

## Capitalisation

| Kind | Rule | Examples |
|---|---|---|
| **Names** (Wardens, nightmares, bosses, Dream cards, Omens, families, Kinships, combos, Memories, places) | Title Case, always, also mid-sentence | Standing Stone, the Hollow Stag, Mending Bark, Blood Moon, Hammer and Anvil, Thunderclap, Forest's Edge |
| **Statuses and damage types** | Capitalised, always | Soaked, Drowsy, Asleep, Rooted, Charged; Stone damage |
| **Currencies and the Heartwood** | Capitalised | Dew, Dreamlight, Seeds, the Heartwood, the Memory Grove |
| **Common game terms** | lowercase in running text | drift, block, rest, leaf / leaves, perfect block, family pick, rank, focus, maze |
| **Buttons and menu items** | Sentence case (first word only, plus names) | Grow into Moonstone · Sell · Let it pass · Peek at the map · Face an Omen |
| **Screen titles and panel headers** | Sentence case; short captions may use the UI style's small caps | A Dream, after drift 10 · The wind carries Omens · Coming this block |
| **Tooltip first line** | the name in Title Case, then sentence case | Standing Stone · Stone damage |

**Second pass (2026-09-30, user: "capitalisation seems all over the place"):** rules for the cases that
kept slipping:
- **Families and damage types are names:** "Any Nestling-family final form" (not "any wing final
  form"), "Spore cards", "Water damage". Internal line ids (wing, acorn, song…) never reach the player.
- ~~Same-tag (resonance) lines~~ **Removed 2026-10-02** with tag Resonance itself (user: "remove the
  resonance"): no "+X% from …" lines anywhere. What stays from that rule: **internal archetype words**
  (wide, narrow, affliction, tempo…) **never reach the player.**
- **Card tags on screen:** tags that are names are capitalised (Spore, Water, Kinship, Reaction,
  Sprout, Thornwall, Nurture); plain categories stay lowercase (economy, maze, tempo, crit, wide,
  narrow, status): *"+20% from 2 Spore cards"*, *"+10% from 1 economy card"*.
- **Obstacles, stages and places are names:** Withered Tree, Mossy Boulder, Thorn-Sapling; Kinship
  stages Sapling / Blooming / Old Kin; Whole Tree; the Codex, the Memory Grove.
- **One separator style:** " · " with single spaces, never double spaces around it.
- **"The" in boss names is lowercase mid-sentence:** "About the Mire Hag", "the Hollow Stag arrives"; capital only at the start of a line or as a title ("The Mire Hag" on the name plate).
- **Checked automatically:** a text lint test (below) so it can't drift again.

"Deeply Blighted" and "Ascended" are names (capitalised). "Rank III" capitalises Rank when it's a
label ("Rank III needs a Nurture Dream"), lowercase in a sentence ("grow past rank V").

## Formatting

- **Numbers:** "+80 Dew", "−25%" (a real minus sign), "×1.5" (a real multiplication sign),
  ranges with an en dash and no spaces ("2.0–8.1"), times with a space ("2 s", "0.5 s"), percent
  without one ("40%"), "½" only in icons.
- **Separators:** " · " (a middle dot with spaces) between parts of one line; never " - " or " | ".
- **Hotkeys:** the key in a badge, or "(X)" at the end of a button when badges aren't available;
  never "press X to …" on a button.
- **Punctuation:** full sentences end with a period; labels and button text don't. One space after
  a period. "…" is one character. Quotes are curly (" ", ' ') in flavour text.
- **Tokens, never raw names:** status words, damage types, game terms and family names go through
  the link tokens ({damp}, {drift}, {family:dewdrop}, …) so they link and follow renames; a raw
  "{token}" must never reach the screen.
- **No jargon without a link:** if a term is in the glossary, it's a link; if it isn't and isn't
  obvious, rephrase ("5 drifts in a row without losing a leaf").
- **Say what it does, not what it sets up** (2026-09-30, user on Windborne Rain: "don't know what it
  means and it's telling me a combo"): card and Warden text states its own effect ("Samara's seeds
  apply {damp}…"). It never names a combo or Reaction ("becomes a Thunderclap corridor"): combos
  stay "???" until discovered, and the Codex and placement links show the pairings.
- **Requirements by damage type:** "Needs Wind" (a linked word), not a family name.
- **Scaling cards show the live value** on the card: "You have 7 · +40%".
- Two lines at most on a button; tooltips at most ~42 characters wide (`screens_ui.md`).

**Card wording, one way each** (card text audit, 2026-10-02: 335 cards used two forms for the same
thing):
- **Distance is in cells:** "within 2 cells", "reach 3 cells" (never "tiles" for a distance).
  **Path squares are path tiles:** "5+ path tiles", "+1 Dew per 10 path tiles".
- **Caps are "up to":** "(up to +45%)", never "(max +45%)".
- **Warden bonuses read as verbs:** "deal 30% more damage", "attack 20% faster", "+0.5 range";
  not "+30% damage" / "+20% attack speed". Nightmare side: "take 25% more damage".
- **Stacking:** none since 2026-10-06 ("Fewer, bigger cards"): every card is one copy, so no
  "(stacks…)" anywhere.
- **"Double / twice / half" only for true multipliers** (2026-10-06): a bonus that adds to the
  damage, speed or Potency sum is written in percent ("deal 100% more damage", "deal 50% less",
  "attack 100% faster", "+100% Potency"). "Double", "twice" and "half" are kept for real ×2 / ×0.5
  effects (Nightshade, Lasting Dreams, "fires twice").

## Text lint test

`tests/test_text_style.gd` (Main Merger) scans every player-facing string it can reach: every
`display_name` / `description` / trait / hint / title / cost / reward field in `resource/**.tres`,
glossary and Codex text, whispers, and the UI strings the scripts build (a list the owners keep in
one place). It builds the **name list from the data** (Warden, nightmare, boss, Dream, Omen,
Reaction, family, damage type, status, obstacle names plus Dew, Dreamlight, Seeds, Heartwood,
Memory Grove, Kinship stages) and fails on:
- a name written in lowercase outside a `{token}` (e.g. "withered trees", "old kin", "acorn final form");
- a raw internal id (a `line` value like "wing", a snake_case id);
- " - ", " | ", or double spaces around " · ";
- a leftover "{token}" after formatting.
Allowed exceptions sit in one list in the test (e.g. the seed a Samara throws, "fall asleep" as a verb).

## First sweep (2026-09-30): owners

Each chat audits the player-facing text it owns against this page and fixes it in place:

| Owner | Text |
|---|---|
| Main | HUD, menus, settings, Codex and glossary, whispers, toasts, results, rest summary, damage meter, intro cards, dossier |
| Tower Code | Warden descriptions (`resource/tower/*.tres`), Warden panel and build ghost strings, Kinship and Reaction text |
| Roguelite Code | Dream cards (`resource/dream/*.tres`), Omens, Remember screen, Dream / Omen screens |
| Enemy Code | nightmare and boss text (`EnemyData`: trait, intro lines, hints, dossier abilities), and the Enemy types design chat's new bosses |
| Meta Game Code | Memory Grove node names and descriptions, perks, milestones, Memories |
