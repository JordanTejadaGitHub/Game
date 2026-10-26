# Seat T: Touch ergonomics and accessibility (round 2026-10-26b, drift controls)

**Conversion.** 1200 x 540 view on a 6.5" 20:9 phone (2400 x 1080, about 405 ppi): 1 view px = 2 physical px = 0.125 mm = **0.79 dp**. So 48 dp = 61 px, 44 pt (about 7 mm) = 56 px, 8 dp = 10 px. Sizes below are the control rects from `drift_panel.gd`, checked against the plates in the PNGs.

## 1. Verdict
The cluster is in the right place: bottom right, under the right thumb, out of the map's way. The owner's ranking (II and speed bigger than Auto) also matches how often each one is used. Two things fail on touch. **Auto and Start drift are too short**: 48 px is 38 dp, under the 48 dp target. And **Auto's on/off depends on a 2 px bar that the always-"on" speed button also wears**. Every gap is at or just under the 8 dp minimum.

## 2. Measurements (Large / Standard 90%)
| Control | Large px | Large dp | Standard dp | 48 dp? |
|---|---|---|---|---|
| Start / Call early / Resume | 273 x 48 | 216 x 38 | ~194 x 34 | height fails |
| Auto | ~60 x 48 (word-wide, `drift_panel.gd:192`) | 47 x 38 | ~42 x 34 | **fails both** |
| II | 96 x 60 (`:34-35`, `:189`) | 76 x 47 | 68 x 43 | Large ok, Standard short |
| Speed cycle | 96 x 60 | 76 x 47 | 68 x 43 | same |
| Gap in row 2 | 10 (`:196`) | 8 | 7 | Large borderline, Standard fails |
| Row 1 to row 2 | ~13 | 10 | 9 | ok |
| Bottom / right margin | ~18 / ~17 | 14 / 13 | | see 3.4 |

Standard sources: Google, 48 x 48 dp and 8 dp apart, about 9 mm ([Android Accessibility Help](https://support.google.com/accessibility/android/answer/7101858)); Apple HIG 44 pt.

## 3. Top problems (ranked)
1. **Auto's state is colour plus a hair-thin mark, and the mark means two things** (`large_rest_auto_off` vs `_on`). Off and on both say "Auto". "On" adds a brass rim and an 18 x 2 px bar (`:241-246`), which is about 2.3 x 0.25 mm on the glass. The speed button wears the same rim and bar whenever the game runs (`:525`, `set_pressed_no_signal(not paused)`). So in `rest_auto_off` the bar sits under "1x", and you can only read Auto's state by comparing it with its neighbour. **Fix:** keep the one word and add a state glyph that has a shape: a lamp in front of the word, hollow ring for off and filled for on (`○ Auto` / `● Auto`), or a small switch track. Also stop drawing the on-mark on the speed cycle, which is not a toggle (the label already shows the speed). **S.**
2. **Auto is the smallest and the farthest left of the three** (`large_rest_auto_on`, 47 x 38 dp). Being smaller than II and speed is fine (owner rule), but it has to stay at the minimum. **Fix:** at least 52 px tall in Large (min-size y = 62 px, so ≥48 dp after the 90% Standard scale), and widen it to about 64 px. It can still be narrower than the 96 px pair. Bottom-align it with the II and speed plates, not "at the row's foot", which leaves a dead strip above it. **S.**
3. **Gaps at 7-10 px, and the "on" toggles touch the primary** (all shots). A miss between II and speed flips pause against speed, which costs nothing much. A miss from II up into "Call drift early" sends a drift, which cannot be undone. **Fix:** row gap 12 px (≥8 dp at 90% too), and 14-16 px between Start and row 2. **S.**
4. **Start / Call early is 38 dp tall** (`large_rest_auto_off`). It is the one primary action and the only irreversible one, yet it is shorter than II. **Fix:** 56-60 px tall in phone mode, same as II. That makes the cluster about 130 px tall, which still leaves the map clear. **S.**
5. **Pause / resume is said three times** (`*_drift_paused`): the "Resume" bar, II with its on-mark, and the speed button, which also resumes on tap (`:521-525`, which is hidden behaviour). It's not dangerous, but three targets compete for one meaning. **Fix:** keep the Resume bar, since it's big and plain. While paused, show II as "▶" (or dim the on-mark), so the icon says what a tap does. Keep speed resuming, but don't count on it. **S.**
6. **Edge margin vs. gesture zones.** The row sits about 14 dp above the bottom edge. Android 10+ reserves a bottom home-gesture inset ([Android codelab, gesture insets](https://developer.android.com/codelabs/gesture-navigation)); the exact dp is not stated there. **Fix:** check that `UiStyle.safe_sides` also uses the bottom system-gesture inset on a real device (Pixel, gesture nav) in the next phone build. **S, verify only.**

## 4. Owner's asks
- *II and speed bigger / wider than Auto*: done right, and it matches use. Keep it, but Auto must still be ≥48 dp (problem 2).
- *"Just say Auto"*: fine for reading, but the word alone can't show the state. Add a glyph rather than a second word (problem 1).
- *Speed cycle vs separate buttons*: keep the cycle. One 76 dp target is better on touch than three 35 dp ones. The label shows the current speed, as with Bloons' play/fast-forward toggle, where the same button turns fast-forward on and off ([Bloonswiki, Round](https://www.bloonswiki.com/Round)).
- *Start drift's width*: as wide as the row is good. It is a big target, and the only gold one. The fault is its height.

## 5. Other games (patterns)
- **Bloons TD 6**: one play button that starts the round and then toggles fast-forward, on its own in the bottom-right corner, sourced above. Copy: big corner primary. I couldn't confirm where BTD6's mobile auto-start toggle sits ([Steam thread](https://steamcommunity.com/app/960090/discussions/0/4362373720226866045) only mentions auto start in co-op), so I'm not claiming anything about it.
- **Arknights / Kingdom Rush**: speed and pause sit in a top corner. I didn't look this up this round, so it's not cited. Heartwood's bottom right is better for thumb reach.
- **Avoid**: state shown only by rim colour, and the same "on" mark on a button that is always on.

## 6. What works (keep)
- The bottom-right cluster, the order (seldom → often, moving out toward the thumb), and only Start glowing gold.
- The whole cluster hides while building (`large_building`, where Close takes over) and under the drawer, so you can't stray-tap behind a panel.
- The 22 px speed / II type and 15 px Auto type are both above the 13 px floor. "Rest after drift 5" in `large_drift_2x` reads as a plain plate, not a call to action.
- The Resume bar while paused: big and plain.
