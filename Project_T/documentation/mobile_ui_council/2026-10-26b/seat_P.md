# Seat P (PC parity keeper): phone drift controls, round 2

All refs `scripts/ui/drift_panel.gd` unless named.

## 1. Verdict
The phone row gets the same actions as PC. It loses facts, though: every tip on this panel is a native `tooltip_text`
with no tap or hold path, and the Start button's tip now carries the drift pot, the maze bonus, the finale, Moonflip,
the rule-breaker warnings and Restless Night (`_fold_notes` 354-367). That breaks standards D and E. The new "Auto"
wording works, but only because two `toggled` handlers happen to run in the right order. There is also one stale-state
bug that PC has too.

## 2. What PC has and the phone row lacks
| PC | Phone | Where |
|---|---|---|
| "Auto-drift" / "Auto-drift on": the word says the state | "Auto" both ways; only the brass plate and an 18 px under-mark show it | 153-163 vs 194-195 |
| Auto tip: "drifts in a block start by themselves a few seconds after the last one arrived" | Tip only, no tap/hold path. A first-time player can't learn what Auto does | 157 |
| Pause tip: "Pause (Space). You can still build while paused." | Tip only. "Build while paused" is a real fact, lost | 167 |
| 1x / 2x / 3x as separate buttons: all speeds visible, one tap to any speed | One cycle button. 3x to 1x takes 1 tap, 1x to 3x takes 2. The phone tip "tap to cycle 1x, 2x, 3x" is tooltip-only | 170-181, 172 |
| Key chips: Enter on Start (rest / Resume), Space and Tab in the tips | Hidden on touch, correctly (`InputMode.touch()`, 330). Not a gap | 330 |
| Status line: "Resting: selling refunds 75%", "Drift N in 12 s", "Rest after drift N" | Hidden (303, 355). The auto countdown "Drift N in X s" has no phone place at all, so with Auto on the player can't see when the next drift comes | 287-290 |
| Start's tip: drift N's Dew pot, the maze bonus rule, "Clear drift N clean: Rare Dream", Moonflip, rule-breaker warnings ("Flyers ... ignore your maze"), Impatient Night | Tooltip-only on a button whose tap starts the drift. A hold can't be used to show it, because holding fires the press on release. Rule-breakers may also come through Whispers (`whispers.gd` uses RuleBreakers). Pot, finale and Moonflip have no other phone path | 344, 354-367, 570 |
| Rush tip (Headlong) | Tooltip-only | 110 |

**Fix (M):** give the panel one TapTip-style "i" or a hold-for-info on the speed row that shows the folded notes, the
countdown and Auto's rule. Simpler (S): put the countdown in Auto's plate while it's on ("Auto 4s"), and that also
answers "is Auto on?" in words.

## 3. State bugs and risks
1. **Auto label depends on handler order (fragile, works today).** The PC lambda (162) sets "Auto-drift on". The phone
   lambda (194) is connected later and overwrites it with "Auto". Godot calls handlers in connection order, so it
   works. If anyone moves or reconnects either one, phones show "Auto-drift on". **Fix (S):** make 162
   `if not UiStyle.is_phone()`, or use one `_auto_text(on)` helper.
2. **Auto plate goes stale after a run loads (PC and phone).** The button reads `drift_director.auto_drift` once in
   `_ready` (159, 163). `RunSaver` later calls `drift_director.set_auto_drift(data.auto_drift)`
   (`run_saver.gd:569`), and nothing syncs the button back. So a resumed run whose saved Auto differs from the
   settings default shows the wrong plate, and on phones the plate is the only signal. The DriftDirector settings read
   (`drift_director.gd:295`) has the same ordering risk. **Fix (S):** set `button_pressed` from the director in
   `_process`, as `_update_rush` already does (554-556).
3. **Paused mid-drift: three resume controls.** "Resume" (323-326), II showing pressed (531), and the speed cycle,
   whose first tap resumes at the shown speed instead of cycling (`_on_phone_speed` 521-525, unpressed while paused
   at 530). The logic is sound: `set_speed` unpauses (`game_speed.gd:24-27`) and the speed is kept. The cost is
   duplication: two big plates and a full-width bar all mean "resume", and a tap on 2x while paused does not do what
   its label suggests. Suggestion: keep Resume (the primary) and II. A paused speed tap could also cycle and unpause,
   which matches PC, where clicking 3x while paused goes to 3x.
4. **II and speed ignore a held pause.** Start's resume path won't unpause under an open choice screen and dismisses
   Lessons (460-464). II (`toggle_pause`, 168) and the speed cycle (523) have no such guard. While a Dream, Omen or
   family screen is peeking (`ChoicePeek`), they can unpause the game that `dream_screen.gd:295` /
   `omen_screen.gd:144` paused. PC has the same with Space/Tab (shared, not phone-only), but on phones the plate sits
   right next to the peek's map. Needs a device check.
5. **Building hides more than the subject says.** `_hide_speed_while_building` (414-428) hides Auto and Start too, not
   only the speed row. That is intended (user 2026-10-17), but subject.md describes only the speed row stepping aside.
6. **Auto's target is 48 px tall** (191-193). The file's own note (33) says 48 dp at 1200 x 540 is about 63 px. Auto is
   a toggle, not a destructive action, but it's below the code's own target. Seat T should decide.
7. **Same "on" mark on all three plates.** Brass plate plus under-bar (`_on_look` 230-244) for Auto on, II paused and
   1x running. In large_rest_auto_on all three look alike, so "Auto on" doesn't stand out.

## 4. Keep
Resume first-in-order in `_on_start_pressed` (460-464). Setting `disabled` once per frame (268, 327) fixed the dead
Resume tap. Start's width follows the row (`_fit_start` 409-412). `phone_short` shortens the labels before fitting
(384-406). II and speed are wider than Auto, as the owner asked. Every key chip is hidden on touch.
