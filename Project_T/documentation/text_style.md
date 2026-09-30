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
- Two lines at most on a button; tooltips at most ~42 characters wide (`screens_ui.md`).

## First sweep (2026-09-30): owners

Each chat audits the player-facing text it owns against this page and fixes it in place:

| Owner | Text |
|---|---|
| Main | HUD, menus, settings, Codex and glossary, whispers, toasts, results, rest summary, damage meter, intro cards, dossier |
| Tower Code | Warden descriptions (`resource/tower/*.tres`), Warden panel and build ghost strings, Kinship and Reaction text |
| Roguelite Code | Dream cards (`resource/dream/*.tres`), Omens, Remember screen, Dream / Omen screens |
| Enemy Code | nightmare and boss text (`EnemyData`: trait, intro lines, hints, dossier abilities), and the Enemy types design chat's new bosses |
| Meta Game Code | Memory Grove node names and descriptions, perks, milestones, Memories |
