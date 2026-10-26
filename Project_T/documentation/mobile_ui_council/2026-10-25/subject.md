# Round 1 (2026-10-25): the whole phone UI, focus on the Warden drawer and growing

First round of the Mobile UI Council (user 2026-10-25: "Create a mobile ui council that also look at other mobile tower
defence and roguelite games for context", "Let the council have a pass through").

## State of the phone build
Latest phone build v0.1.78 = commit c4bf24c4 (Mobile UI council fixes 1-12 from an informal earlier review: bigger
top-right buttons, hold-to-name toasts, Target 2x2 grid, 90% Standard size, 13 px text floor, Sell back in the drawer
as a red plate, etc.; read that commit message with `git -C D:\Projects\Game log -1 c4bf24c4`).
Still open from that review: 13 Pause / speed visible with the right drawer open; 14 Abandon on a danger plate with
spacing; 15 the floating "Something moves..." whisper needs a plate / top position; 16 fit the camera to the island;
and the drift panel hides while the drawer is open (the flyer hint's buttons "disappear").
Unverified on a device: phone aspect detection, punch-hole padding, upside-down refit, hold-to-name toasts.

## The owner's asks this round (answer each)
1. **Warden drawer:** "the grow buttons should be pinned to the bottom like the Nurture" (today the grow rows scroll
   with the info; Nurture and Sell sit in a pinned footer). How should pinned grow rows, Nurture and Sell share the
   bottom when there are 1-4 grow options (and "+N more")?
2. **Warden drawer:** "fix the details in the Warden so it matches the PC": list what the PC Warden panel shows that the
   phone drawer doesn't (or shows differently), and how the phone should show it.
3. **Family pick on phones:** "mobile also need to show the branches it grows when choosing family" (with the family's
   characteristics). Today the phone family card may drop or hide branch info that PC shows (family_pick_screen.gd
   `_fit_to_view` / `_compact_card` move branch roles into tips, and phones have no hover).
4. **Hold a grow button in the drawer** "should bring up details of what it will grow into" (PC shows a hover tooltip
   via `_grow_tip` and a map preview; phones: first tap previews, second tap grows). What should the hold show, where,
   and how does it sit with tap-to-preview / tap-again-to-grow?

5. **Added 2026-10-26:** "If we're keeping the sell button in the Warden drawer, we can remove the sell feature on the
   tower bar" (the dock's Sell button, bottom-left on phones). Decided by the owner: say what else the dock Sell does
   today (a sell mode? selling several via Select?) and what must move so nothing is lost, and what to put in its slot
   (or leave it empty).

## Screenshots (shots\)
- `pc_drawer_sprout`, `pc_drawer_grown`, `pc_drawer_grown_scrolled`: PC Warden panel (every form unlocked, for layout).
- `large_drawer_*`, `standard_drawer_*`: the same on a phone at both UI sizes.
- `large_*` / `standard_*` (hud, building, warden, dreams_list, dream, dream_looked, family, remember, pause, codex,
  settings, omen_offer, dossier, gifts): every phone screen.
- `user_phone_v0177_bug.jpg` (if present): a photo from the owner's phone of an earlier build.
