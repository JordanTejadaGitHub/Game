# Seat F: first-time phone player (round 2, drift controls)

## Verdict
I'd find "Start drift 1" right away: big, bottom right, under my thumb. "II" and "1x" read as pause and speed straight away. "Auto" is the weak one: I can't tell whether it's on or off, or what it does. Mid-drift the top button stops being a button I understand: it reads "Rest after drift 5", which looks like a label.

## First sight, button by button (large_rest_auto_off / _on)
- **Start drift 1**: "begin the wave." Correct. I'd tap it. "Drift" is a new word, but next to a big gold button I'd guess it means wave.
- **Auto**: my guesses, in order: auto-*play* (the game places Wardens for me?), auto-*aim*, or auto-start. In Bloons, Ninja Kiwi puts auto-start in the settings, not on the HUD, so a bare "Auto" next to Start reads like "let the game play itself". With no hint, I would *not* tap it in my first minutes because I'd be afraid it hands my maze to the AI.
- **Auto on or off?** Comparing rest_auto_off and rest_auto_on, the only differences are a brass rim and a short underline under the word. The 1x button has that same rim and underline at the same moment, so "underline" means "this one is chosen". After the first look I'd learn that. On first sight I wouldn't notice that Auto changed when I tapped it. Nothing says "on" or "off".
- **II**: pause. Clear. In large_drift_paused the II gets the underline and the top button turns into "Resume". I'd have two buttons that both seem to un-pause. I'd tap the big one, which is fine, but the II button doesn't turn into a play triangle, so it still says "pause" while I'm paused.
- **1x**: "game speed, normal". I'd guess right that tapping makes it faster, because every TD has this. Would I know it *cycles* 1->2->3->1? Only by tapping it. Nothing hints at a next step. The risk: on 3x, wanting 2x, I tap and land on **1x**, so I have to tap twice more. That's mildly annoying, not confusing. Bloons uses the same "tap again to go back to normal" toggle ([Bloons Wiki, Fast Forward](https://www.bloonswiki.com/Fast_Forward)), so players accept a cycle button.
- **Speed lost its mark while paused** (large_drift_paused: 2x has no rim or underline). I'd briefly think the speed reset to 1x. Keep the 2x mark while paused.

## What confused me (ranked)
1. **"Rest after drift 5" in the primary slot mid-drift** (large_drift_2x, auto on). It sits where Start was and looks the same, but it's a status line, not an action. I'd tap it, nothing happens, and I'd think the game froze. Fix: show "Call drift 2 early, +Dew" there, or dim it clearly as text, not a button plate. **S**
2. **Auto with no state words.** Fix: "Auto: off" / "Auto: on". It's still basically one word and still narrow. Or keep "Auto" and add a tiny ON/OFF pip, and show a one-time toast on the first tap ("Next drifts start by themselves"). The PC already says "Auto-drift on" (drift_panel.gd:162), so a phone that says less goes against parity standard E. **S**
3. **No pause while the Warden drawer is open, or while placing** (large_drawer_open, large_building: the whole panel is hidden). As a new player, inspecting a Warden *is* when I want to stop time. Kingdom Rush doesn't have a speed-up at all, and players called that a "huge miss" ([OpenCritic, KR Frontiers reviews](https://opencritic.com/game/9124/-/reviews); [Steam thread](https://steamcommunity.com/app/246420/discussions/0/522730700387363452)). Speed and pause control is something players expect to *always* reach. Fix: keep II reachable (e.g. pinned in the drawer header or the top bar). **M**
4. **II doesn't turn into a play arrow when paused** and duplicates Resume. Fix: show a play arrow on that button while paused. Keep the big Resume. **S**
5. **Speed cycle**: keep it. Separate 1x/2x/3x buttons would be clearer but cost width. If a long press on speed showed a small 1x/2x/3x picker, the 3x-to-2x problem would be gone (**S-M**, optional).

## Owner's asks
- *Pause and speed bigger/wider than Auto*: yes, that's right. I use them far more. The sizes look good: easy thumb targets.
- *Rename to "Auto"*: shorter is fine, but the word alone hides both its meaning and its state. Add on/off wording (problem 2).
- *Start drift's width*: good. It's clearly the main button at a rest.

## What other games do
- Bloons TD 6: one play button that starts the round and then toggles fast-forward on later taps; auto-start sits in settings, not next to play ([Bloons Wiki](https://www.bloonswiki.com/Fast_Forward)). Copy: one obvious speed toggle. Avoid: hiding what the state is.
- Players treat speed-up as basic. Its absence is a top complaint in Kingdom Rush reviews (above), so never hide it behind panels.
- Arknights: I couldn't find player complaints about its 1x/2x button, so I make no claim about it.

## Keep
Bottom-right cluster, big II and speed, gold Start as the only primary, the speed label showing the current speed, and moving the controls aside while building (as long as pause stays reachable somewhere).
