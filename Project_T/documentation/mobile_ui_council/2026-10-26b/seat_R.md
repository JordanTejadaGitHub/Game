# Seat R (mobile roguelite veteran): round 2, phone drift controls

## Verdict
The layout is right for a phone: one big "next thing" button over a row of II / speed, all in the right thumb's corner,
with the two most used toggles the biggest. What's left is about pacing: with Auto on, the phone hides *when* the next
drift comes, and the speed button wears an "on" mark that means nothing. Both are small fixes. Keep the structure.

## Top problems (ranked)
1. **Auto-drift's countdown is invisible on phones** (large_drift_2x, standard_rest_auto_on). `drift_panel.gd:289`
   writes "Drift N in X s" into `_status_label`, and `:303` hides that label on phones. So a phone player with Auto on
   gets a drift landing "by itself" with no warning: in a roguelite that's the moment you were about to Nurture or
   Sell. Fix: put the countdown on the Start button itself while it counts, e.g. "Call drift 3 early, +12 Dew · 4 s",
   or a thin fill bar across the button's foot that drains (Kingdom Rush's wave icon has a timer ring you tap to call
   early). **S-M.**
2. **The speed cycle wears the "on" plate and underline** (large_rest_auto_off: "1×" has the brass rim + gold bar while
   Auto, which is off, has none). `_add_speed_button` -> `_on_look` (`:220-237`) gives the cycle button toggle styling,
   but its label already is its state. Three buttons now share one "on" language for three meanings (speed chosen,
   paused, Auto). Fix: on phones, `toggle_mode = false` and no on-mark for `_phone_speed`; keep the brass/underline
   only for Auto and II, so "lit = a mode you switched on" reads cleanly. Optional: tint the label (not the plate) at
   2× / 3× so fast play is glanceable. **S.**
3. **Auto's on/off is still subtle at a glance** (large_rest_auto_on vs off): the difference is a rim colour and an
   18 px bar on a 48 px plate. With problem 2 fixed it becomes the only lit small button, which mostly solves it. If
   the owner wants more, a tiny state glyph inside the word (a filled vs hollow dot) beats renaming. Don't go back to
   "Auto: on/off" text; the owner asked for one word. **S.**
4. **"Rest after drift 5" sits in the primary slot as a dead plate** (large_drift_2x). It's correctly plain, but it is
   full-width and in the thumb's best spot while doing nothing. Fine as info; just make sure it never takes the gold
   look and that a tap does nothing silently (no error sound). Keep. **none / S.**
5. **Speed should survive rests and new runs.** I could not confirm in code whether `GameSpeed` keeps 2×/3× across a
   rest and a Dream pick; please verify. Mobile players set speed once (Arknights has a "Maintain 2x Speed" setting for
   exactly this). If it resets each drift, players tap the cycle every drift and the cycle's 1×->2×->3× order becomes
   a chore. **S (check).**

## The owner's asks
- *Pause and speed bigger / wider than Auto*: yes, done correctly; Auto is set-and-forget, II and speed are used every
  drift. BTD6 even keeps auto-start in its settings, not the HUD, so a small Auto is genre-normal.
- *"Just say Auto"*: fine, as long as the on look is Auto's alone (problem 2).
- *Speed cycle vs separate buttons*: keep the cycle. BTD6 uses one play button that starts the round and then toggles
  fast-forward; one button for speed is the mobile norm and frees width. Three states is the upper limit.
- *Pause vs Resume duplication*: keep. When paused, the big Resume is the easy target and II staying lit explains why;
  two ways to the same thing is fine when one is the obvious one.
- *Start drift's width*: keep matching the row; it's the one gold action and the widest, which is what reads as
  primary.

## What other games do
- **BTD6**: one play/fast-forward button bottom right (start round, then tap toggles speed); auto-start is an option,
  so the next round flows without a press. Copy: the single button and that auto-start never skips a decision screen
  (Heartwood's Auto already stops at rests and choices, `pending_choice` at `:315`; keep that).
- **Kingdom Rush**: calling a wave early pays gold and shortens spell cooldowns; the call is a pulsing icon at the
  path start with a timer ring. Copy: show the remaining time on the call-early control.
- **Arknights**: 1×/2× and pause in the top corner during combat, plus "Maintain 2x Speed". Copy: remember speed.
- **Roguelite pacing (Brotato, Slay the Spire)**: the run auto-advances through combat, but the shop / reward screen
  always waits for the player. Heartwood's "Auto only within a block, rests need Start" matches this; keep it.
- **Avoid**: Slay the Spire mobile's reviews note misfires from small, centre-placed buttons; never let Start / Call
  early move toward the board's centre or shrink when its text changes.

## What works (keep)
Bottom-right cluster with 10 px gaps; II / speed 96 x 60 in 22 px type; Start as wide as the row; the waiting choice's
name on the Start button; Resume replacing Start while paused; the speed row stepping aside while building and the
panel hiding under the Warden drawer.

## Sources
- Kingdom Rush call-early: https://www.trueachievements.com/a382017/daring-achievement ,
  https://www.aol.com/news/2014-07-30-kingdom-rush-tips-and-tricks.html
- BTD6 play / fast-forward and auto-start: https://www.bloonswiki.com/Fast_Forward ,
  https://www.bloonswiki.com/Apopalypse_(BTD6) , https://steamcommunity.com/app/960090/discussions/0/4362373720226866045
- Arknights "Maintain 2x Speed": https://arknights.wiki.gg/wiki/User_interface
- Slay the Spire mobile misclicks: https://www.tapsmart.com/?p=28595 ,
  https://www.pocketgamer.com/slay-the-spire/slay-the-spire-review-genre-defining-card-roguelike-finally-goes-mobile/
