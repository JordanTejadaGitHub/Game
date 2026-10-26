# Seat T: Touch ergonomics and accessibility (round 2026-10-25)

**Conversion used.** A 6.5" 20:9 phone at 2400 x 1080 shows the 1200 x 540 view at 2x, so 1 view px is about 0.126 mm.
In OS units, a 20:9 Android phone in landscape is ~915 x 412 dp, so 1 px is ~0.76 dp. An iPhone 15 in landscape is
852 x 393 pt, so 1 px is ~0.73 pt. **So 48 dp ≈ 63 px, 44 pt ≈ 60 px, 8 dp spacing ≈ 10-11 px, and Apple's 11 pt text
floor ≈ 15 px.** `UiStyle.HUD_BUTTON_H = 48` (ui_style.gd:50) is 48 *view* px, which is ~36 dp / ~6 mm. It is not
48 dp. That gap explains most of what follows. All measurements below are visible plates in the PNGs; the hit rect may
be a little larger (QuietButton adds an 8 px inset, ui_style.gd:1067-1072).

## 1. Verdict
The layout is in the right places for a landscape two-thumb grip: the dock sits under the left thumb, the drawer
footer and drift controls under the right. Most targets are about 75% of platform minimum at Large and about 65% at
Standard, and the spacing between rows is under 8 dp. The drawer's single Sell is a one-tap, unconfirmed destructive
action. It wears the same gold rim as every primary action, so the eye and the colour-blind eye both read it as "the
button to press".

## 2. Top problems (ranked)

1. **Drawer Sell looks primary and has no confirm** (large_drawer_*, standard_drawer_*). It is a one-tap sell
   (warden_panel.gd:500) on `UiStyle.danger` (warden_panel.gd:2517). `POOR` is Ember #b8662c (ui_style.gd:21, "the
   palette has no red"), and in the shots it renders as the same amber/gold rim as Resume (large_pause), "Take Winding
   Path" (large_dream_looked), Plant 2 (large_building) and the selected "First" target. A slip down from a grow row
   lands on it, because it is in the row directly below. **Fix:** see owner ask "Sell colour" below, plus a second-tap
   confirm or an undo toast. **S.**
2. **Targets under minimum, worse at Standard.** Measured at Large: grow rows 307 x 54 with only **6 px** between them;
   footer Sell 105 x 53 and Nurture 167 x 53; drawer close X 43 x 41; top-right icon buttons 38 x 38; dock collapse
   chevron 33 x 33; Start drift 44 tall; pause and speed 40 x 44; Target 2x2 buttons 148 x 46; pause screen "Abandon
   run..." 138 x 32; settings tabs ~32 tall and "Reset this tab" 28 tall; settings toggles ~30 x 12 and slider knobs
   ~14 px. At Standard (90%) the top-right icons are 34 x 34 and pause is 34 x 37 (~25 dp), well below WCAG 2.5.5's
   44 and close to the 2.5.8 floor. **Fix:** set a phone hit-target floor of **60 view px** (≈ 46 dp / 44 pt; 64 is
   better), applied to hit rects, not plates. Keep 10-12 px between targets that do different things. Standard should
   shrink the art and text but never the hit rects. Give toggles and sliders 60 px tall hit areas with a knob of at
   least 28 px. **M.**
3. **Text floor is below the platforms' floor.** `PHONE_MIN_TEXT = 13` (ui_style.gd:316) is ≈ 9.5 pt / 10 dp. Apple's
   smallest style (Caption 2) is 11 pt ≈ 15 px. Small caps make it worse: "GROW INTO", "TARGET", "LESSONS", "THIS RUN"
   and "DREAMS INTO, 2 OF 5 THIS RUN" have ~8-9 px cap heights. "Price↑ 2/5" over the dock and "Quieter shrieks and
   whispers." (large_settings) read at 11-12 px. **Fix:** raise the floor to 15 px. Never apply small caps under
   16 px. Use body size ≥ 17 px for card text (the Dream cards already do). **S-M** (UI Code owns sizes).
4. **The drift panel and pause/speed vanish while the drawer is open** (large_drawer_* vs large_hud). This is open item
   13. Pause is the one control a player must always have under a thumb. **Fix:** see ask 5 (put Pause and speed in
   the freed dock slot, left thumb). **S.**
5. **Bottom-edge crowding.** The drawer footer's plates end at y ≈ 523 of 540 (≈ 2 mm from the glass). On large_building
   the "2 Sprouts ◆25 +4" price tag is cut by the bottom edge. Android's back/home gesture strip and the iOS home
   indicator sit at the bottom; Apple reserves a bottom inset in landscape. I could not confirm the exact current pt
   value, so check it on a device. **Fix:** keep interactive plates ≥ 12-16 px above the bottom edge on phones
   (`safe_insets` already exists, ui_style.gd:151). Move the price tag above the ghost. **S.**
6. **Icon-only stat tiles** (large_drawer_*: ✷8, »2.0/s, ↔2.5, potion 1.0). The PC says "Potency 1.0" in words
   (pc_drawer_grown). This breaks standard C ("numbers say what they count") for a first-timer. **Fix:** make each tile
   a ≥ 60 px tap/hold target that names itself (the hold-to-name toast from c4bf24c4), or add a 13-15 px word under
   each number. **S.**
7. **Gifts screen shows no cards** (large_gifts, standard_gifts): only the header and footer render. This may be a
   capture artefact or a real bug. Main should check. **?**

## 3. The owner's asks

**Ask 1: pinned grow rows + Nurture + Sell.** Pin one action block at the drawer's foot. Only the info scrolls above it.
- 1-2 options: full-width rows, 60 px tall, 10 px gap.
- 3-4 options: a 2 x 2 grid of half-width tiles (each ~165 x 60). Name on line 1, ◆cost on line 2, so nothing
  truncates. Note `_phone_grow_columns` today pairs tiles "only when each fits whole".
- 5+ options: three tiles plus a fourth "+N more" tile that opens the full list as a sheet over the info area. The sheet
  has the same pinned footer.
- Bottom row: Nurture (wide, outer right, nearest the right thumb's pivot) and Sell (narrow, inner left). Put a ≥ 16 px
  gap and a hairline divider between the grow block and this row.
- Worst case at Large: 2 x 60 + 10 + 16 + 60 ≈ 206 px of a ~465 px drawer, leaving ~230 px for header and info. That is
  enough. Cap the pinned block at ~45% of drawer height. Past that, the "+N more" tile appears sooner.

**Ask 2: details matching the PC** (Seat P gives the full table). From a touch angle, the phone drawer lacks these PC
items:
- the "Poison" / "Potency 1.0" words (icons only on the phone),
- the hover-only parts of the grow tip (`_grow_tip`, warden_panel.gd:358, 1102),
- the "Wakes:" line (:381),
- the catch-zone hover preview (:411-414),
- the Sell refund rule, which lives in `tooltip_text` (:499).

None of these has a phone path except the first-tap preview. Each needs either always-shown text or a hold (see ask 4).
The Sell refund rule is short enough to show under the Sell label ("+25 · 50% while nightmares walk").

**Ask 3: family pick branches.** large_family shows two of five branch names as ~30 px rows with no role, and three
hollow glyphs. There is room: ~60 px of empty card below the names. Show each branch as a name plus a one-line role,
inline. Do **not** put tappable branch chips inside a card where a tap selects the card, because nested targets
cause mis-taps. If the roles don't fit, a hold on the card opens a full sheet listing the family's branches and roles;
letting go closes it. The "Glossary" button stays as the fallback.

**Ask 4: hold a grow button.**
- **Tap** (unchanged): first tap selects/previews and shows the ghost on the map (warden_panel.gd:404-408). The row
  relabels itself "Grow · ◆120 · tap again" so the armed state is visible. Clear the armed state on any other tap or
  after ~4 s.
- **Hold** (≥ 400-500 ms; Android's default long-press timeout is 400-500 ms depending on version): opens a details
  card with the before → after numbers, the new role and what it later branches into. It also shows the same map
  ghost. **Letting go closes it and never grows**, including when the row was already armed. Slide off to cancel.
- **Where:** the thumb covers the row, so anchor the card to the **left of the drawer** at the row's height, over the
  map. Clamp it to the safe area. Do not draw it above the thumb on the drawer itself.
- The tap path already covers everything a hold shows, so hold is never the only way in (Game Accessibility
  Guidelines). Use the same hold behaviour for Nurture choices, Target buttons and stat tiles so players learn one
  gesture.

**Ask 5: removing the dock's Sell.** Today it enters **sell mode** (tower_seller.gd:103-121). On phones a tap *marks*
Wardens and a "Sell N" bar sells them all (tower_seller.gd:123-132, `confirms_sells()`). Removing it loses fast
multi-sell. Box Select plus the group drawer's "Sell N" (warden_panel.gd:658-665, on the danger frame) still covers
that case, so nothing is lost as long as Select stays in the dock. Reach of the drawer Sell: bottom-right, inner side
of the footer, an easy right-thumb reach. It is less natural than Nurture, which is fine for a destructive action.
The risk is that the drawer Sell is single-tap with no mark/confirm step, unlike sell mode. Removing the dock Sell
makes the one-tap path the only one, so add a confirm or undo (problem 1).

**Freed slot:** put **Pause + speed cycle** there (one 60 x 78 slot: tap = pause, hold = name). It is the left thumb's
best spot and fixes item 13 whatever the drawer does. The second choice is leaving the space empty to enlarge the
Warden slots and the 33 px chevron.

**Owner question: should the drawer Sell be golden?** **No.** In this UI gold/amber means "primary, do this". Ember
#b8662c beside gold is a hue-only difference that many deuteranopes and protanopes can't see, and WCAG 1.4.1 says
colour must not be the only cue. Ember text on the dark plate also measures ≈ 4.4:1, just under AA for 13-16 px text.
Ruling:
- Sell gets a quiet dark plate with no glow and no gold rim.
- Its label is Mist/Ink with an Ember **glyph** (for example a Dew drop with a down/back arrow) as a shape cue.
- It keeps its narrow width and its 16 px gap.
- Gold stays reserved for the one primary action: the first affordable grow, or Nurture when no grow is affordable.
- The danger cue becomes the confirm itself: the second-tap state turns the plate Ember-filled and reads "Sell? +25".
- If the palette can't make a red, the confirm step and the glyph do the danger work instead of a red colour.

## 4. What other games do / standards worth copying
- **Platform floors:** 44 x 44 pt (Apple HIG, Caption 2 = 11 pt smallest text); 48 x 48 dp with 8 dp spacing (Android /
  Material). Hit area can exceed the drawn icon.
- **WCAG 2.2:** 2.5.8 sets 24 px as AA, 2.5.5 sets 44 as AAA. 1.4.1 says don't use colour alone.
- **Game Accessibility Guidelines / Xbox XAG 107:** "large and well spaced" virtual controls; avoid requiring holds or
  give alternatives (here, hold only previews, the tap path does everything); allow adjusting the size of touch
  targets (a third "Huge" UI size later).
- **Thumb zones** (Hoober's grip study; Smashing's thumb-zone write-up): about 75% of touches are thumbs and people
  switch grips. In landscape the reachable arcs are the lower-left and lower-right; top-centre is the stretch zone. The
  layout already follows this: the top-right icons are rare actions, which is correct.
- **Avoid** destructive one-tap actions next to frequent ones. One BTD6 player on the Steam forums describes upgrading
  the wrong tower and then having to sell it, a mis-tap cascade. I could not confirm whether BTD6 or Kingdom Rush
  confirm sells on mobile, so I make no claim about them.

## 5. What works (keep)
- Dock bottom-left, drawer and drift controls bottom-right: correct two-thumb split.
- Pinned Sell / Nurture footer, Nurture outer and wide, Sell inner and narrow, 40 px apart.
- Tap-to-preview, tap-again-to-grow with the map ghost. Hold-to-name toasts.
- Deferred presses on rebuilding buttons (warden_panel.gd:500, 785).
- Choice screens: Take / Peek / Skip pinned along the bottom edge, with Take bottom-right and large (~180 x 50). The
  armed card is raised and relabels the button "Take Winding Path" (large_dream_looked). This is a good confirm
  pattern; copy it for Sell and Grow.
- Dream card body text at ~17-18 px.

Sources: [Android touch target size](https://support.google.com/accessibility/android/answer/7101858) ·
[Apple HIG summary (secondary)](https://www.openxcell.com/10-basic-ui-guidelines-apple/) ·
[WCAG 2.5.8 / 2.5.5, Smashing](https://smashingmagazine.com/2024/07/getting-bottom-minimum-wcag-conformant-interactive-element-size/) ·
[Silktide 2.5.8](https://silktide.com/accessibility-guide/the-wcag-standard/2-5/input-modalities/2-5-8-target-size-minimum/) ·
[WCAG 1.4.1 (W3C)](https://www.w3.org/WAI/WCAG20/Understanding/use-of-color) ·
[MDN Use of color](https://developer.mozilla.org/docs/Web/Accessibility/Understanding_WCAG/Perceivable/Use_of_color) ·
[Smashing thumb zone](https://smashingmagazine.com/2016/09/the-thumb-zone-designing-for-mobile-users) ·
[A List Apart phone grips](https://alistapart.com/1-2-phone-grips-jpg/) ·
[Game Accessibility Guidelines, intermediate](https://gameaccessibilityguidelines.com/intermediate/) ·
[Xbox XAG 107 input](https://devdocs.xbox.com/gaming/accessibility/xbox-accessibility-guidelines/107) ·
[Android ViewConfiguration](https://developer.android.com/reference/android/view/ViewConfiguration) ·
[useyourloaf safe areas](https://useyourloaf.com/blog/supporting-iphone-x/) ·
[BTD6 Steam thread](https://steamcommunity.com/app/960090/discussions/0/3280317523017565472/).
Not verified first-hand: Apple's exact landscape bottom inset, and whether BTD6 or Kingdom Rush confirm sells.
