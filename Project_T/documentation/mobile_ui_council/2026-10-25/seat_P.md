# Seat P: PC parity keeper (code reader), round 2026-10-25

All paths under `D:\Projects\Game\Project_T\scripts\`. "wp" = `ui/warden_panel.gd`, "hv" = `ui/warden_header_view.gd`, "fp" = `ui/family_pick_screen.gd`, "pc" = `ui/phone_choice.gd`, "ts" = `tower/tower_seller.gd`, "tb" = `ui/touch_build.gd`.

## 1. Verdict
The phone drawer shows nearly every *visible* fact the PC panel shows. In a few places it shows more: the full description, the refund on Sell, the Deep line and the tax reason. The parity hole is the **tooltips**. A plain `tooltip_text` has no phone path. Only `TapTip.attach` (ui/tap_tip.gd:20-37) works on a tap, and the HUD's hold-to-name covers only the top-right buttons (hud.gd:1496-1526). So on phones every drawer button's tip is lost: grow, Nurture, rank choices, Target, Sell, rank picks and signature. So are the family card's branch roles and counters. That breaks standard D and standard E.

## 2. Top problems (ranked)
1. **Grow rows: everything that says what you grow into is in the tooltip only** (large_drawer_grown). `_grow_tip` (wp:358, 1102-1112) holds the stat changes ("Damage 8 → 14"), role points and description. The tip also carries the rank add-on (wp:360), the grow tax (wp:363), free ranks (wp:366), the role/support line (wp:373), the "+N damage a second" change (wp:376) and the cards it wakes (wp:381). On a phone the row shows only the name, the price and, when taxed, the tax line (wp:377-378). The first tap gives the map ghost (wp:404-408) and no numbers. Fix: hold-to-read (see ask 4). Size M.
2. **Family card: the branch roles are gone on phones** (large_family, standard_family). On PC each lane shows the name with its role line under it (fp:816-819). On phones the role is skipped (fp:813-815) and moved into `lane.tooltip_text` (fp:828-832). That is a plain tooltip, not a TapTip. The lane is `MOUSE_FILTER_PASS` (fp:801), so a tap on it just looks at the card. The role and counters cannot be reached at all. `_role_chips` (fp:838-854) was written for phones but nothing calls it. Size S-M.
3. **First family pick: the Calling's rule is cut on phones.** `short` is true below 620 px of viewport height (fp:16, 1119). Phones are 540 tall, so the card stops after the Calling's name (fp:1146-1147). The PC at 1080 shows the rule text (fp:1148-1155). The run-long rule is the pick's biggest stake (fp:600). Size S.
4. **Nurture and rank choices: the explanation is tip-only.** The Nurture tip (wp:443-444) says what the next rank adds and "+N when it grows into X" (`_growth_note`, wp:1651-1656). The full before → after of each rank choice (wp:458-459) is also tip-only. Phones see only the short change, plus the Deep line (wp:461). The rank preview on the map is hover/focus only (wp:2087-2092). Size S-M.
5. **Target modes are unexplained on phones.** The four meanings ("furthest along the path"…) live in the PC chip's tip (wp:731-735) and each button's tip (wp:778). The phone grid (wp:757-767) shows bare words. That tip also says "(T cycles)" while the chip says Z (wp:731): a wrong key on PC. Size S.
6. **The stack count is pruned.** `_prune_phone_stat_rows` drops every status row its chips name (wp:2354). So the PC's "Poison ×3" (hv:265-266) becomes a bare "Poison" chip, and the "×N" is lost. Potency becomes an unlabelled flask with "1.0" (wp:2428; PC "Potency 1.0", hv:271). Size S.
7. **Small tip-only facts:**
   - the rank/focus meaning on the title (wp:267)
   - each rank pick's text and "No effect on X" (wp:1317-1320)
   - the Signature (wp:1362-1365)
   - the refund rule and "half back while nightmares walk" (wp:490-499)
   - the locked-form tip (wp:923)
   - the names of the branches that are not in this run (wp:1284-1285; fp:786-787)
   - the family pick's "2 of 5" call-back cost (fp:758)

   Size S each.

## 3. Owner's asks

### Ask 2: Warden drawer, field by field
| Field | PC panel | Phone drawer | Where (phone) |
|---|---|---|---|
| Portrait + name | 32 px (hv:78) | 48 px (wp:125) | header |
| Role tags + rank line | yes, TapTip (hv:394-400; wp:256-260) | same | under name |
| Rank/focus meaning | title tooltip (wp:267) | **none** | — |
| Target | header chip + key, meanings in tip (wp:721-750) | 2×2 grid, **no meanings** (wp:757-793) | scroll, after grow rows |
| Description | cut to its opening when >3 options (wp:254; hv:212-216), rest in Details | full (wp:254 `not _phone`) | header (better) |
| Keyword chips | yes, TapTip (keyword_row.gd:47) | same | header |
| Damage / speed / range | 16 px icon row (hv:249-259) | 32 px tiles, TapTip (wp:2424-2460) | tiles |
| Crit % | icon row | same + word "crit" (wp:2376) | stat rows |
| Status "Poison ×N" | second row + tip (hv:264-266) | **pruned** (wp:2354): chip only, no ×N | chip |
| Potency | "Potency 1.0" (hv:271) | flask + number, no word (wp:2428) | tiles |
| Status strength, Jarlink-style lines | in Details (hv:281-289) | always shown (wp:1544) | scroll |
| Catch / interest / Caught | yes, TapTip (hv:294-302) | same | stat rows |
| Nurtured picks + Signature | row; per-pick tips (wp:1290-1322, 1362) | row, **tips lost** | under stats |
| Notes (wall, unique, Waystone) | yes (wp:269-274) | same | scroll |
| This run / Reactions / Kin / Combos / Boosts / Dreams on it | behind Details toggle (wp:1522-1544) | always open | scroll |
| Grow rows: name, price, key | pinned (wp:171-172), key chip | name + price, no key; **scroll** (wp:149) | middle |
| Grow details (tip) | `_grow_tip` + rank, tax, dps change, wakes (wp:358-381) | **none**; tax line only (wp:377) | — |
| Grow map preview | hover (wp:852-856) | 1st tap (wp:404-408) | map |
| Locked / not-in-run rows | text + tips (wp:919-944, 1268-1286) | text; **tips lost** | middle |
| Nurture | row + tip + hover rank preview (wp:439-448) | pinned footer (wp:2495-2499); **tip and preview lost** | footer |
| Rank choices | short change + full tip (wp:455-470) | short change + Deep line (wp:461) | middle |
| Sell | footer third, refund clipped in pc_drawer_* ("SELL X"), rule in tip (wp:496-499, 1740-1758) | red plate "Sell +25" (wp:2508-2529); **rule lost** | footer left (better) |
| Close | footer | square ✕ (wp:2597-2608) | header |

How the phone should show it (two paths, both phone-only):
- **Always shown**:
  - keep "×N" on the status chip (or stop pruning that row)
  - put the word "Potency" beside the flask
  - give each Target button a 13 px Mist line under it, or one line under the grid for the chosen mode
  - add a 13 px refund-rule line under Sell ("½ back while nightmares walk")
  - add Nurture's "+N when it grows into X" as a small note in the footer row
- **Hold to read (standard D)**: holding any drawer row or footer button for about 0.45 s (reuse `HOLD_LABEL_S`, hud.gd:1506) shows its whole `tooltip_text` in a tip panel to the drawer's side. Letting go hides it, and the press does not fire (`set_block_signals`, as hud.gd:1526). This one mechanism covers wp:267, 358-381, 443, 458, 778, 1317, 1362, 499 and 923 at once. Labels (picks, signature) should get `TapTip.attach` instead.

### Ask 1: Pin the grow rows
This is PC parity: the PC already pins `_buttons` under the scroll (wp:171-172). Phones put them inside the scroll (wp:149).
- Move `_buttons` back between the scroll and the footer on phones.
- Target, Details and the rank-choice list stay in the scroll.
- The pinned stack, bottom up: row 1 is Sell | Nurture (as today).
- Above it, grow options at 60 px (`PHONE_ROW_H`, wp:1825):
  - 1-2 options: full-width rows.
  - 3-4 options: a 2×2 grid. `_phone_grow_columns` / `_grid_cells_fit` (wp:2559-2594) already test whether names fit at 14 px, and fall back to one column.
  - 5+ options (a Sprout has 9 in pc_drawer_sprout): 3 cells and a "+N more" cell. It opens the rest *in the scroll* (`_more_open` exists, wp:42; `_more_row` is a stub today, wp:1517-1518).
- Cap the pinned block at about 55% of the drawer so the header, tiles and chips always stay visible above it. At 540 px that is about 3 rows of 60 plus the footer.
- While the Nurture choices are open, they replace the grow rows in the pinned block, with Back in the footer (wp:2500-2507).

### Ask 3: Family pick, show the branches
- Show each lane's role on phones. Call the unused `_role_chips` (fp:838) under the name, or drop the `_layout != null` skip (fp:813-817).
- Lay the lanes out one per line in the flow (fp:760-767). At 2 cards each card is about 530 px wide (pc:409-411), and large_family has spare height under the lanes.
- Make each lane a `TapTip` for the counters. A tap on an underlined word already doesn't take the card (pc:496-498, 431).
- Show the first pick's Calling rule on phones: a phone-specific threshold, or the rule at least on the looked card (pc:439-449).
- List the names of the branches that are not in this run in words ("Driftspore, Bloomcap not in this run").
- The cards scroll if they run tall (pc header comment, line 7).

### Ask 4: Hold a grow button
- **Tap** (unchanged): the first tap previews on the map, and the row reads "Grow into X". The second tap grows (wp:368, 404-410).
- **Hold** (0.45 s, either state) shows the grow sheet: `_grow_tip` plus the rank, tax, free-rank, dps-change and wakes lines (the same `tooltip_text`).
  - Show it in a panel on the drawer's outer side, top-aligned, so it never covers the Warden (the camera already keeps it clear, wp:2118-2136).
  - Also show the map ghost. Letting go hides the panel and never grows.
  - Holding never moves the row to the "Grow into" state.
- Also put the one-line dps change (wp:1129-1145, already phone-worded) under the name while the row is in the "Grow into" state. Then a player who never discovers holding still sees what the grow does before the second tap.
- Note: Godot's emulated `mouse_entered` on touch is not a reliable phone path. Don't lean on wp:852 or 2088.

### Ask 5: Remove the dock Sell
What it does today (it is a **sell mode**, not double tap or a selection sell):
- The slot is a toggle (hud.gd:472-497) that calls `TowerSeller.set_sell_mode` (hud.gd:500-513).
  - It ends build and Select mode and clears the selection (ts:110-121).
  - It works while paused (hud.gd:493).
  - It shows the sell hint and dims the bar (hud.gd:1120-1139).
  - Entered from building, turning it off goes back to building the same Warden (hud.gd:503-513).
- On phones a tap on a Warden **marks** it rather than selling it (`confirms_sells`, ts:131-132; ts:847-853; `toggle_sell_mark`, ts:135-147). A refused Warden gets a toast instead (ts:187-192). Marked Wardens get the Ember outline and their refund (ts:1003-1007).
- The touch bar's "Sell N +X" sells every marked Warden, of any kind (tb:84-93, 158-162, 216-219; ts:172-185). Cancel drops the marks (tb:209-214). Done and Back exit (tb:197-203, 400-408).
- It is the **only** way into sell mode on phones: TouchBuild's own Sell toggle is hidden on phones (tb:164).
- Double tap is selection, not selling (ts:807-816).

What must move so nothing is lost:
- **The confirm.** The drawer's single Sell sells on **one tap** (wp:500). The dock's mark-then-Sell was the phone's sell confirm (user 2026-10-17, ts:123). Give the drawer Sell a two-tap confirm on phones ("Sell? +25", like Grow's tap/tap and the group "Press again", wp:703-716).
- **Selling several kinds at once.** It survives through the Select slot and the group drawer's "Sell N +X" (wp:655-668), which confirms at 3+ or during a drift (wp:706). Nothing to add.
- **Selling right after placing, without leaving build mode.** This is lost: the player must press Done, tap the Warden, Sell, then pick the Warden again. Accept that, or let a tap on an already planted Warden in build mode open the drawer.
- **Code to update:**
  - hud.gd:108, 705-709, 833, 843-844, 866 (the `fixed` slot count), 892-895
  - wp `_dock_top` (wp:2294)
  - the sell hint
  - phone tests that find "SellSlot"
  - keep TowerSeller's sell mode: the PC's X key uses it.
- **Its slot:** leave it empty. The slot width formula (hud.gd:866-867) then gives the Warden slots more room.

## 4. What other games do (parity lens; I did no web lookups this round)
From my own knowledge, not verified this round:
- Kingdom Rush: a tap opens a ring, and the first tap on an upgrade shows its info with a confirm tick. That is the info-before-commit our tap/tap already copies.
- Slay the Spire mobile: hold a card to see its keyword tips.
- Bloons TD 6: the upgrade info shows in the panel at all times.

Pattern worth copying: **hold = read, tap = act, and no fact hidden behind hover only.**

## 5. What works (keep)
- The full description and visible refund on phones: better than PC.
- The Deep line (wp:461).
- The tax reason on the row (wp:377).
- TapTip stat tiles (wp:2457-2459).
- Deferred presses on Sell and Target (wp:500, 785).
- The pinned Sell and Nurture footer with a 16 px gap (wp:2523-2529).
- The family card's emblem, chips and costs.
- Glossary and Your Dreams on choice screens.
