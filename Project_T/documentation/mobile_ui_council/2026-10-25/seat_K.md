# Seat K: Mobile tower defense veteran (round 2026-10-25)

## 1. Verdict
The phone build already does the hard things right: a right-side drawer that leaves the map visible, a pinned footer with Nurture and Sell, tap-to-preview then tap-again-to-grow, and Sell on its own plate. The weak spot is the drawer's actions. The grow buttons, which are the most expensive and most-used decision in a run, scroll away under the info (on `large_drawer_grown` the third row is cut in half). Everything the PC learns from a hover tip about a grow (stat changes, damage change, role, wakes, tax reasons) has no phone path at all. Fix those two and the drawer is on par with Bloons TD 6 and Kingdom Rush.

## 2. Top problems (ranked)
1. **Grow rows scroll, and one is cut in half** (`large_drawer_grown`, `standard_drawer_grown`): the third option shows only its top 8 px above the footer. In mobile TDs the buy buttons never move: in Kingdom Rush the upgrade icons sit in a fixed ring around the tower, and in BTD6 the upgrade paths are fixed slots in the side panel (both from my own play; I could not find a written source). Phone players read a half-cut row as "nothing more". **Fix:** pin the grow options in the footer (see ask 1). **L**
2. **Grow details are hover-only** (`warden_panel.gd:358-395`: `_grow_tip`, the DPS change, wakes, rank surcharge and free ranks all go into `button.tooltip_text`; the catch preview hangs off `mouse_entered`, line 413). On a phone you pay 120 Dew and only find out afterwards what you bought. This breaks standards D and E. **Fix:** a hold card plus a short delta line on the first tap (ask 4). **M**
3. **Family lanes on phones are name-only, and the role goes into a hover tooltip** (`family_pick_screen.gd:813-832`: `lane.tooltip_text = tip`, which is not `TapTip.attach`, so phones can never see it). `_role_chips` (line 838) is defined but never called. The faded "not this run" icons also show at about 14 px with no words (`large_family`), which is the "reads as broken" case that the PC compaction (line 277) already hides. **Fix:** ask 3. **M**
4. **Bottom-right run controls are hidden while the drawer is open** (open item 13; compare `large_hud` with `large_warden`). With the drawer open you cannot pause or slow down while you decide, and that is when you most need to. **Fix:** use the dock slot that Sell frees up (ask 5). **S-M**
5. **Unlabelled number in the stat row** (`large_drawer_grown`: a flask icon and "1.0"; PC says "Potency 1.0" and also has a "Poison" status line). This breaks standard C. **Fix:** the word "Potency" after the value when the row fits, otherwise a TapTip on each stat icon. **S**
6. **The selected Warden can sit under the drawer.** On `large_drawer_grown` the second Warden at x≈840 is half covered. BTD6 moves its upgrade panel to the opposite side from the selected tower (from my own play, not verified online). Moving the drawer would break thumb memory, so **fix:** when a Warden is selected and its cell falls under the drawer, pan the camera until it sits in the visible map (a smoothed pan; never move the maze). **S**
7. **Building summary is clipped** (`large_building`, bottom-right: "2 Sprouts ♦25 +4" is cut at the screen edge). **S**
8. **"Copy save (dev)" shows in the pause menu** (`large_pause`). Gate it out of release builds. **S**

## 3. The owner's asks

**Ask 1: pinned grow rows with Nurture and Sell.** The drawer is about 460 px tall and 350 px wide. Make the footer an action block that never scrolls, with only the info above it scrolling (the BTD6 split: description on top, buy slots fixed):
- **Row 1 (grow), by count:** 1 option = one full-width row; 2 = two half-width tiles side by side; 3-4 = a 2×2 grid of tiles (each about 165 × 52, name on line 1, ♦cost on line 2, tax in orange on line 2 when taxed); 5 or more = 3 tiles plus a fourth "+N more" tile that swaps the scroll area for the full grow list (the pinned block stays where it is, and Close/back returns). No horizontal scroll strips: they hide options the same way the cut row does now.
- **Row 2:** Sell (small, danger plate) at the drawer's bottom-left corner and Nurture (wide) to its right, as today. Keep at least 12 px between Row 1 and Row 2 so a thumb going for a grow tile never lands on Sell.
- **Budget:** 2×2 grid plus footer ≈ 52+8+52+12+60 = 184 px. That leaves about 250 px for header, description and stats, which fits `large_drawer_grown`'s info without scrolling. Move the "Grow into" heading into the block (one 16 px label line). The Target 2×2 grid stays in the scroll area. Also put the PC's header target chip on phones (BTD6 places targeting right under the portrait; Blooncyclopedia), so the most common target change needs no scrolling.
- Primary highlight (`grow_primary` / `nurture_primary`) stays as now, on one tile only.

**Ask 2: PC facts the phone drawer lacks or shows differently.**
| PC shows | Phone today | Phone should |
|---|---|---|
| Target chip in header ("First Z") | 2×2 grid after the grow rows | Header chip (tap cycles, hold lists the modes) + grid stays in the scroll |
| "Poison" status line, "Potency 1.0" with its word | Flask + "1.0" | Word or TapTip on every stat icon |
| Grow tip: role points, stat before → after, description, DPS change, rank surcharge, tax reason, free ranks, Wakes | Name, cost, tax line only | Hold card (ask 4) + one-line delta on the first tap |
| Catch-zone ring on grow hover (line 413) | None | Show it during the first-tap preview |
| Details toggle (Buffs, This run, Kinship, combos, Dreams on it) | Always open in the scroll (comment line 63) | Fine. Keep it below the grow block |
| Description cut with "…" | Full description | Fine (phone is better) |
| Sell has no price | "Sell +25" | Fine (phone is better, consider for PC) |

**Ask 3: family pick with branches.** The card has spare height (`large_family`: about 45 px under the lanes). Per lane: emblem, branch name, "→ final" name, then the role as `_role_chips` (already written, unused) on the next line. Put the two lanes one above the other rather than side by side so the chips have width. Tapping a lane (or its underlined words) gives a TapTip with what it counters, the same way Dream card underlines work (`phone_choice.gd:495`). Tapping the card still looks at it. Replace the tiny faded "not this run" icons with words ("+3 more branches, not this run") or drop them as the PC does. The family's characteristics (status chip, job, cost line, Calling) already show, so keep them.

**Ask 4: hold a grow button.**
- **What:** a "grow card" with the same content as `_grow_tip` plus the DPS change, wakes and cost breakdown. Put the "before → after" lines first, the description last.
- **Where:** to the left of the drawer, vertically centred on the held row, over the map, never under the thumb (the right thumb covers the drawer). At the same time the map shows the new form's ghost and catch ring (`show_grow_preview`).
- **Timing:** about 0.4 s to open, with a fill ring on the row so the player learns the gesture. Release closes the card and does nothing else (standard D). A hold never counts as the first tap, and a drag off the row cancels.
- **With tap/tap:** keep it unchanged. The first tap shows the preview, relabels the row "Grow into X" and adds a one-line delta under the drawer header ("Damage 8 → 14 · +Area · +86/s"), because long press must not be the only way to reach information (Flook's mobile tooltip guidance). The second tap grows. Tapping elsewhere or another tile cancels the confirm. Kingdom Rush mobile works the same way: one tap selects an upgrade and shows its description, a second tap buys it (from my own play; I could not find it documented).

**Ask 5: removing the dock Sell.** What it does today: it is a toggled *sell mode* (`hud.gd:472-494`, tooltip "tap Wardens to mark them, then Sell"). It marks several Wardens and sells them with "Sell N +X" on the touch bar (`touch_build.gd:48-49, 162`; `tower_seller.gd:110-160`), and it works while paused (`hud.gd:493`). What must move: bulk sell already exists through **Select → group drawer "Sell N +X"** (`warden_panel.gd:658`, which also asks for confirmation during a drift). Before removing it, check that (a) Select mode and the group Sell work while paused (TouchBuild is PROCESS_MODE_ALWAYS, line 60; check the group drawer too), (b) the group refund matches the mark-sell refund, and (c) mixed kinds in a selection still show Sell. Whispers or onboarding text that mention sell mode need rewording. **What goes in the slot:** in Kingdom Rush the bottom-left corner holds the hero portrait and the spells (Rain of Fire, Reinforcements), so that corner belongs to frequent, time-critical actions. Heartwood has no actives there, so I recommend **Pause plus a speed cycle** in that slot. That also solves open item 13, because the drawer never covers the left side, and pausing is the left thumb's natural job. Otherwise leave it empty rather than filling it with something rare.

## 4. What other games do
- **Fixed buy slots, scrolling description** (BTD6 side panel, Kingdom Rush ring): buy buttons never move between selections. Copy this.
- **Tap to inspect, tap again to buy** (Kingdom Rush mobile ring icons, Heartwood already). Copy this, and add the delta line.
- **Targeting under the portrait** (BTD6, per Blooncyclopedia's targeting page). Copy it as the header chip.
- **Selling is a small icon set apart from the upgrades** (Kingdom Rush's $ on the ring, per the AOL/Joystiq tips). Heartwood's danger plate fits this.
- **Bottom-left holds the actives you use often** (Kingdom Rush heroes/spells). Use the freed slot for pause/speed.
- **Avoid:** misbuy with no undo. Players complain about upgrading the wrong tower and having to sell and re-place it (BTD6 Steam thread). Heartwood's two-tap grow already prevents this, so keep it, including on taxed grows.
- **Avoid:** Rogue Tower players asked that UI buttons stop "clicking through" to towers underneath (Steam discussion). Make sure a tap on the drawer or the dock never reaches the map.

## 5. What works (keep)
- The right drawer with the map visible, the square close button and the portrait header (`large_warden`).
- Sell on its own red plate showing the refund. Nurture pinned beside it.
- Two-tap grow with the map ghost preview, and the Dew refusal before any preview (line 402).
- The Dream "look" flow (`large_dream_looked`): lift, dim the others, "Take X" button, Let it pass. The family pick should match it.
- Pause is laid out clearly, with Abandon apart on its own plate (`large_pause`).
- A 13 px text floor and 48+ px rows everywhere I measured (grow rows about 52, footer 60, dock slots about 60×80).

## Sources
- Blooncyclopedia, Targeting option (BTD6 targeting sits below the portrait): https://www.bloonswiki.com/Targeting_option
- Bloons Wiki, Selectable Target / Lock in Place: https://bloons.fandom.com/wiki/Selectable_Target , https://bloons.fandom.com/wiki/Lock_in_Place
- BTD6 Steam discussion (wrong upgrade, then sell and re-place): https://steamcommunity.com/app/960090/discussions/0/3280317523017565472/
- Kingdom Rush tips (sell by tapping the tower, then its $): https://www.aol.com/news/2014-07-30-kingdom-rush-tips-and-tricks.html
- Kingdom Rush walkthrough (rally flag in the tower menu): https://ayumilove.net/kingdom-rush-walkthrough-guide/
- Kingdom Rush Wiki, Upgrades: https://kingdomrushtd.fandom.com/wiki/Upgrades
- Kingdom Rush 5 Steam discussion (a confusing tower-menu button): https://steamcommunity.com/app/2849080/discussions/0/4515505814160134213
- Infinitode 2 (targeting first/last/toughest/weakest): https://videogamegeek.com/videogame/341361/infinitode-2
- Rogue Tower Steam suggestions (click-through, font): https://steamcommunity.com/app/1843760/discussions/0/3182358960696047374
- Android accessibility, touch target size (48 dp, 8 dp spacing): https://support.google.com/accessibility/android/answer/7101858
- Flook, mobile tooltip best practices (long press only as an enhancement): https://flook.co/blog/mobile-tooltip-best-practices
- Unverified (from play, not documented online): Kingdom Rush's tap-then-confirm ring, BTD6's panel on the side opposite the tower, Kingdom Rush's bottom-left hero/spell buttons.
