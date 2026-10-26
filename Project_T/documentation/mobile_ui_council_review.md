# Mobile UI Council review

Skill: .claude/skills/mobile-ui-council. Briefs and rounds: D:\Projects\logs\mobile_council\. Seat reports: documentation/mobile_ui_council/<date>/.

## Mobile UI Council, round 1 (2026-10-25/26): lead review

Seats: K mobile TD veteran, R mobile roguelite veteran, T touch ergonomics, P PC parity (code), F first-time phone
player. Reports: `seat_K.md`, `seat_R.md`, `seat_T.md`, `seat_P.md`, `seat_F.md` (this folder). Captures: `shots\`.

### Verdict
The phone run is sound in its bones (two-thumb split, pinned footer, tap-to-look then Take, tap-again-to-grow), but
**growing is blind on a phone**: every fact the PC gives about a grow, a Nurture choice, a target mode, a family's
branches or Sell's refund lives in a hover `tooltip_text`, and phones have no hover. That one gap is behind four of the
owner's five asks. Second: the grow rows scroll and get cut (`large_drawer_grown`: the third row half under the
footer). Third: targets and text are smaller than platform minimums (T).

### The owner's asks, ruled
1. **Pin the grow rows (K R T P F agree).** One pinned action block at the drawer's foot that never scrolls; the info
   above it scrolls. 1 option: one full-width row; 2: two side by side; 3-4: a 2x2 grid; 5+: three cells + "+N more"
   (opens the rest; Back returns). Rows 60 px tall, >= 10 px apart. A divider, then the footer: Sell (left, narrow) and
   Nurture (right, wide). Cap the block at ~55% of the drawer; the info keeps at least the name + stats row visible.
2. **Details match the PC (P's table).** Missing or worse on the phone drawer, to add:
   - the target mode chip ("First") in the header (PC shows it beside the name; phone hides it in the capture);
   - the status line "Poison" (with its stack count when stacked) and **Potency's word** next to the flask (phone shows
     a bare "1.0", wp:2428; the status row is pruned at wp:2354);
   - a Details section (PC's Details toggle: range / catch ring, Wakes, kills, damage dealt) reachable on phones;
   - each grow row's damage-a-second change ("+86 a second") shown under its name (PC shows it in the tip).
   Phone already beats PC on the full description, the Sell refund and the Deep / tax lines: keep those.
3. **Family pick shows its branches (K R T P agree).** Phones skip the branch role (fp:813-815, the role goes into a
   lane `tooltip_text` a phone can't open, fp:828-832) and `_role_chips` (fp:838) is written but never called. Show
   each branch's name and its role inline on the card (T: inline text, not tappable chips inside a tappable card);
   counters on hold. Also P: the first pick's Calling rule is cut at 540 px (`CALLING_FULL_HEIGHT` 620, fp:1119/1146).
4. **Hold a grow row to see what it grows into (all agree on the shape).** Hold >= ~0.45 s: a grow card opens beside
   the drawer (on the map side, at the held row's height), laid out like Remember's detail: now -> next portrait, role,
   key stat changes, damage a second, what it wakes, cost and grow tax; the map preview shows too. **Letting go never
   grows.** Tap still previews + arms ("Grow into X"), second tap grows. F's split vote: show the card on the first tap
   too, since new players won't find hold (owner call O2).
5. **Remove the dock's Sell (decided by the owner).** Today it is the phone's only sell mode: mark several Wardens then
   "Sell N" across kinds (tower_seller.gd:110-185, touch_build.gd:84-93/164/216), works while paused. Nothing is lost:
   box Select + the group drawer's "Sell N" (wp:655-716) covers selling several. Must change with it: hud.gd's slot
   count and `_dock_top` (wp:2294) stop listing `sell_slot`. Freed slot: K and T say Pause + speed there (also closes
   open item 13); P says leave it empty so the Warden slots widen (owner call O3).
6. **Nothing under the camera punch hole (owner 2026-10-26).** Today the left-docked drawer ignores a mid-side hole on
   purpose (wp:2261-2265, owner 2026-10-21: a full-height band "looked broken"). New ruling: the drawer's frame stays
   flush to the edge, but its content gets the hole's width as left padding when docked left (`_pad_left(side_holes.x)`,
   already written), so no text or button sits under the camera. Check the other left-edge items (leaves counter, dock)
   against `side_holes` too.
7. **Should Sell be golden? No (T, F; owner asked).** `UiStyle.danger` draws Ember (#b8662c; the palette has no red),
   which reads as the same gold rim as Take / Resume / the primary grow, so Sell looks like the action to press, and
   colour alone carries the meaning (WCAG 1.4.1). Ruling: a quiet plate with the words in Ember-tinted "Sell" + a sell
   glyph, gold kept for the one primary action; and on phones a **second tap confirms** ("Sell? +25"), because the
   dock's mark-then-Sell was the old safety and the drawer's Sell sells on one tap (wp:500). The plate look is UI Code's.

### Fix first
| # | What | Owner |
|---|---|---|
| 1 | Pinned grow block + footer (ask 1) | Mobile UI |
| 2 | Hold-to-read on phones: one shared hold (0.45 s, release never fires) for every drawer tooltip (grow tip, Nurture, rank choices, Target modes, Sell rule); the grow card (ask 4) is its big case | Mobile UI |
| 3 | Drawer parity: target chip, Poison / Potency words, Details reachable, damage-a-second on grow rows (ask 2) | Mobile UI |
| 4 | Family card branches inline + Calling rule not cut (ask 3) | Mobile UI (family_pick_screen phone path) |
| 5 | Remove dock Sell; Sell two-tap confirm on phones; slot use per O3 (ask 5, 7) | Mobile UI |
| 6 | Drawer content clear of the punch hole when docked left (ask 6) | Mobile UI |
| 7 | Sell plate not gold: a quiet danger look that isn't gold (ask 7) | UI Code (UiStyle.danger) |
| 8 | Tap targets: a 60 px hit-rect floor on phones that Standard doesn't shrink; 10-12 px between different actions (T: HUD_BUTTON_H 48 = ~75% of 48 dp at 1200x540) | Mobile UI + UI Code |
| 9 | Text floor 13 -> 15 px on phones; small caps only at >= 16 px (T) | UI Code / Mobile UI (`_text_floor`) |
| 10 | HUD numbers that don't say what they count ("29", purple "0", "10"/"3" under slots) and the clipped "2 Sprouts" build total (F, K) | Mobile UI |

Not a bug: the empty gift screen in `*_gifts.png` is the capture opening GiftScreen with no `current_offer`.
For the Wording Council: Winding Path's "+0% ... With this: +0%" reads as worthless (F, R).

### Patterns from other games worth copying
- Upgrade / evolve shown before buying with its result (Kingdom Rush's tower upgrade info, Slay the Spire's upgrade
  preview, Vampire Survivors showing an evolution in the offer) (K, R).
- Tap to read a card or keyword without committing (Wildfrost, StS mobile); commit is a separate, clearly placed button (R).
- Sell quieter than upgrade and apart from it; fat-finger sells are a common mobile TD complaint (K, T, F).
- Avoid: Balatro's drag-to-sell (R); tiny icon-only buttons (StS mobile reviews, F).

### What works (keep)
Two-thumb split of the HUD; pinned footer; tap-again-to-grow; "Take X" after looking; Peek at the map; Glossary and
Your Dreams on choice screens; Omen bullets; the dossier's one-line tip; the phone drawer's full description and Sell
refund (better than PC).

### Open owner calls
- **O1** Pinned block layout: 2x2 grid of cells (name + price, damage change on hold) vs always full-width rows (fewer per screen).
- **O2** Grow card on the first tap too (F), or only on hold with the first tap just arming (K R T P)?
- **O3** Freed dock slot: Pause + speed (K T; closes item 13) or empty (P)?
- **O4** Sell on phones: second-tap confirm (T P) or an undo toast?
- **O5** Raise phone targets to 60 px and text to 15 px (T): affects every phone screen; a bigger pass.

### Owner calls and what was built (2026-10-26)
Owner: O1 2x2 grid; O2 grow card on the first tap and on hold; O3 freed dock slot left empty; O4 Sell's second tap
confirms. O5 (60 px targets, 15 px text floor) still open.

Built (Mobile UI chat, phones only unless noted): pinned grow cells (warden_panel `PinnedGrow` / `GrowScroll` /
`GrowGrid`, "+N more" opens the rest, past 45% of the drawer they scroll); the grow card (`GrowCard`, beside the drawer,
moves to the far side when it would cover the Warden; armed cell reads "Tap to grow"); Sell on a quiet pewter plate in
Poor (not gold) with "Sell? +N" first; no dock Sell (hud.gd no longer makes `sell_slot`); the stat rows keep PC's status
and Potency line (no flask tile); Target first in Details; drawer content clear of a punch hole on its side (frame
flush, drawer wider by the hole); family cards list each branch with its role (2 columns); Remember beside Glossary and
Your Dreams on every choice screen. Asked in the same session: the nightmare card closes when the Warden drawer opens
and ends above the drift panel (nightmare_info.gd `_fit_phone`); the Armoured line says what armour does (PC too,
EnemyData.KIND_LINES); the drift button's Resume works again (PC too, 45f43db0: a per-frame disabled toggle cancelled
the press).

### Round 2 (2026-10-26): the phone drift controls (Start / Auto / II / speed)

Seats K R T P F, reports in documentation/mobile_ui_council/2026-10-26b/. Captures: rest (Auto off / on), building,
mid-drift at 2x, paused, drawer open, both UI sizes.

#### Verdict
Keep the layout (all five): one wide action above Auto, II and the speed cycle in the right thumb's corner; II and speed
bigger than Auto; one cycling speed button (Bloons' play / fast-forward toggle is the same idea). The problems are
state, not layout: Auto's on / off barely shows, the speed button wears the same "on" mark, paused says "resume" three
ways, and some facts (the auto countdown, the tips) have no phone path.

#### Fix first (all phone-only, drift_panel.gd unless noted; spot-checked)
1. Speed cycle loses the on-mark (R T K P): `_on_speed_changed` presses `_phone_speed` whenever the game runs
   (drift_panel.gd:530), so "1x" looks switched on like Auto. Only Auto (on) and II (paused) light up.
2. Auto on / off by shape, not only colour (T K F R): keep the one word; add a small dot before it, filled when on,
   hollow when off.
3. Paused (T F P): II shows a play triangle while paused; a speed tap while paused cycles the speed and stays paused
   (today its first tap resumes, :521-525), so Resume and II are the two ways back.
4. Sizes (T K): Auto and Start 60 px tall like II / speed (Auto still the narrowest); 12 px between row-2 buttons, 14 px
   between Start and row 2 (a mis-tap there starts a drift).
5. Mid-drift "Rest after drift N" (K F): it can't be pressed; draw its words dim so it reads as status, not a button.
6. Bugs (P): the Auto plate goes stale after loading a run (run_saver.gd:569 sets auto drift, nothing syncs the
   button): sync it every frame as Rush does; the phone "Auto" label relies on handler order (gate the PC words to PC);
   II / speed can unpause under a peeking choice (PC too: Space / Tab).

#### Owner calls
- O6 Auto countdown (R P): with Auto on, phones never show "Drift N in X s" (the status line is hidden). Put the
  seconds on the Call early button ("Call drift 2 early, +40 · 8 s"), or as a draining bar on it?
- O7 Pause while the Warden drawer is open (K F; was open item 13): the whole panel hides under the drawer. Add a small
  II to the drawer's header, or leave it (close the drawer to pause)?
