# Seat K: Mobile tower defense veteran, round 2 (phone drift controls)

## Verdict
The layout is mostly right, and it is the shape mobile TDs use: one cycling speed button, a pause next to it, and the next-wave action above them, all in the bottom-right thumb corner. Keep it. The problems are about state, not size. Mid-drift, row 1 shows a button that does nothing ("Rest after drift 5"). Auto's on and off look too alike. And while the Warden drawer is open, a phone player has no pause at all.

## Top problems (ranked)
1. **There is no pause while the drawer is open mid-drift** (large_drawer_open: the nightmares are walking, and II and the speed button are hidden under the drawer, `drift_panel.gd` `_phone_panel_open`). In a phone TD you open a tower mostly *during* a wave, which is when you want time to stop. PC players can press Space. Fix: put a small II in the drawer's header next to ✕, or pause automatically while the drawer is open mid-drift (an option, off by default). **M**
2. **Row 1 is a dead "button" mid-drift** (large_drift_2x: "Rest after drift 5" in a full-width plate). It has the same frame, the same caps font and the same spot as Start, so players will tap it and nothing happens. In mobile TDs, the call-early control only shows up when you can use it. Kingdom Rush's call-early icon appears at the path entrance only while early calling is allowed. Fix: while the button can't be used, draw the line as a status label with no plate (dimmed text), or hide it. Bring the plate back when "Call drift N early" becomes available. **S**
3. **Auto's on-state is too quiet** (large_rest_auto_off vs large_rest_auto_on: the only difference is a brass rim and a 12 px underline). The speed button uses the same underline to mean "running", so the mark means two different things. With the owner's one word "Auto", the state has to come from the plate. Fix: when on, fill the plate (a lit brass face with dark text) or add a small lit dot or ↻ glyph before the word. When off, keep it plain. Don't add words. **S**
4. **Start drift is shorter than the buttons below it** (48 px vs II and speed at 60 px). At a rest it is *the* action, yet it is the lowest-weight plate in the cluster. Fix: make Start 56-60 px tall on phones, as tall as II and speed. It is already the right width. **S**
5. **Three "resume" paths when paused** (standard_drift_paused: Resume, II lit, and the speed button also resumes on its first tap, `_on_phone_speed` l.521). This is fine and forgiving; BTD6 also resumes from several places. One note: the speed button's first tap resumes at the current speed instead of cycling to the next one. Keep that, it's correct. Nothing to change beyond problem 2.
6. **Building hides pause too** (large_building). If a player picks a Warden mid-drift, they can't pause to place it carefully. The tooltip on PC even says "You can still build while paused." This is the owner's decision (2026-10-17). It costs mid-drift precision, so pausing while building could be worth giving back later. **S** (later)

## Owner's asks
- **"Pause and speed bigger / wider than Auto":** done correctly. They are 96 × 60 against Auto's ~58 × 48, and both clear 44 pt / 48 dp. The 10 px gaps pass standard B. Keep it.
- **"Just say Auto":** fine. Arknights and BTD6 also show bare icons or words. The word only works if the plate carries the on/off state, which is problem 3.
- **Speed cycle vs separate buttons:** keep the cycle. It is the mobile norm: BTD6 uses one play button that becomes fast-forward and toggles back, and Arknights has one 1x/2x toggle. Separate 1x/2x/3x buttons are a PC luxury.
- **Start drift's width:** right as is. It spans the row and stays out of the centre of the map. Only its height is wrong (problem 4).

## What other games do
- **BTD6:** one button bottom-right that starts the round, then toggles fast-forward on and off. Auto Start is a settings toggle, not a HUD button. The Bloons wiki describes the play button as a toggle during a round. The page 403'd for me, so this is from the search summary: https://www.bloonswiki.com/Fast_Forward. The Auto Start setting exists per a bot README that requires it on: https://github.com/piweiblen/BloonsPlayer. I could not confirm where it sits on screen.
- **Kingdom Rush:** you call the next wave early from a timer icon at the path's spawn, shown only while early calling is allowed (guides: https://www.gamerevolution.com/?p=60649, https://kingdomrushtd.fandom.com/wiki/Kingdom_Rush:_Frontiers). The old games had no fast-forward (https://steamcommunity.com/app/246420/discussions/0/522730700387363452). The lesson is to only show a call-early control when it can be used.
- **Arknights:** a 1x/2x toggle and a pause button, the same size, in the top-right. That is from my memory: the wiki only confirmed the "Maintain 2x Speed" setting (https://arknights.wiki.gg/wiki/User_interface). Arknights keeps them reachable while an operator's panel is open, which bears on problem 1. I'm not certain of that last part.
- **PvZ2:** a single Turbo toggle that speeds up both planting and zombies (https://www.imore.com/plants-vs-zombies-2-gets-updated-cool-stuff-upgraded-map-and-more). Like BTD6, it is one button with two states.
- **Avoid:** auto-wave with no easy way to stop it. One itch.io TD player asked for auto-wave to turn itself off before a dangerous wave (https://itch.io/post/8673333). Heartwood's block-wise Auto with a rest after every 5 drifts already avoids this.
- I found no reliable source for Infinitode 2's layout, so I'm not citing it.

## What works (keep)
- The whole cluster sits bottom-right, about 18 px off the edge. It is in the thumb zone and clear of the safe sides.
- The cycling speed button shows its current speed as its label.
- Start, Call early, Resume and the waiting choice's name all live in one slot, so there is one place to look.
- Only the next action glows gold; the toggles that are on get brass (`_on_look`).
- The panel steps aside while building and under the drawer, which is correct for the space it frees. It just needs a pause somewhere else (problem 1).
