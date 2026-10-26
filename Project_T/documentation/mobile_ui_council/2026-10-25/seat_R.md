# Seat R: Mobile roguelite / deckbuilder veteran (round 2026-10-25)

## 1. Verdict
The choice screens (Dream, family pick, Omen) are already better than most roguelite phone ports. They use "tap to look, then Take", have a real skip, Peek at the map, and Glossary and Your Dreams in the header, and the text is big. The weak spot is the step where a build changes shape. Phone players can't see what a grow turns into, and they can't see the role of a family's branches. On PC both live in hover tooltips. On phones they are plain `tooltip_text` that nothing can open. Fix those two and the phone player can plan a build as well as a PC player.

## 2. Top problems (ranked)

**1. Grow details are hover-only. A phone player grows without seeing what they get.** (`large_drawer_grown`, `large_drawer_sprout`)
The PC grow tip holds the role points, the key changes ("Damage 14 → 27"), the damage-a-second change, Wakes, the tax and the rank cost. It is built at `warden_panel.gd:358-381` and set only as `button.tooltip_text`. On a phone, the first tap at `warden_panel.gd:404-408` arms the row: it relabels it "Grow into X" and draws the map preview, but none of the tip text ever appears. The rows show only a name and a price. For a roguelite, "what does this become" is the decision itself.
Fix: show a grow card on the first tap and while the row is held (see ask 4). **M**

**2. The family card hides each branch's role on phones.** (`large_family`, `standard_family`)
On phones (`_layout != null`) the branch lane shows only an icon and a name (`family_pick_screen.gd:813-815`). The role goes into `lane.tooltip_text` (`:828-832`), which is a plain tooltip, not a `TapTip`. The lane passes clicks through to the card, so a tap picks the card. Phone players have no way to read "Brood Cap: Area, Heavy". The faded "not in this run" row's tip ("Add one on the Remember screen…", `:786`) is lost on phones in the same way. A helper `_role_chips()` already exists (`:838`) and nothing calls it.
Fix: see ask 3. **S-M**

**3. Grow rows have no portraits.** (`large_drawer_*` vs `large_remember`, `large_family`)
Every other "what it becomes" screen shows the form's art: Remember's tree, the family card's branch lanes. The drawer shows small-caps text only ("DRIFTSPORE ·120"). On mobile, the art is how players recognise a build at a glance. Slay the Spire, Wildfrost and Balatro all make the card art the target you tap.
Fix: put the form's 32 px portrait at the left of each grow tile. The phone drops no information and gains the thing people recognise. **S**

**4. The gift screen captured with no cards.** (`large_gifts`, `standard_gifts`)
The header says "Take one, or skip them" and the hint says "Tap a card to look at it", but there are no cards. Either the capture state had no gifts, or this is a real layout bug. Check it on a device before anyone signs off on that screen. **S** (to verify)

**5. A Dream preview line that says nothing.** (`large_dream`, Winding Path)
"Your maze now: +0% Dew a drift. With this: +0%." With a +0% maze, the "now / with this" preview shows no difference and reads as broken. Hide the line when both values are equal, or say what the maze needs. This is a wording item, not touch-specific: pass it to the Wording Council. **S**

**6. Holding something is not taught anywhere.** The hold-to-name top buttons (`hud.gd:1496-1526`) are the only hold in the game. Apple's guidance on touch-and-hold menus warns that people won't find a hidden gesture ([Notion HIG summary](https://hzzr.notion.site/Context-Menus-8f0afe7a59fe41e695150f89a196cdd6)). Make hold a shortcut only. Everything a hold shows must also be reachable by a tap (ask 4). **S**

## 3. The owner's asks

**Ask 1: pin grow rows to the bottom with Nurture and Sell.** Yes. Build one pinned action tray at the drawer's foot. Only the info (portrait, blurb, stats, Target) scrolls above it.
- **Footer row (always there):** Sell on its red plate at the left, Nurture at the right, as today, with the 8 px gap.
- **Grow tray above it:** tiles 48 px tall (Material 48 dp), each showing a portrait, the name, and the price under the name.
  - 1 option: one full-width tile.
  - 2 options: two half-width tiles side by side. This is the normal in-run case, because a run offers 2 of 5 branches.
  - 3 or 4 options: a 2x2 grid. The 4 starting families fit exactly.
  - 5 or more (only with Grove unlocks or dev): three tiles plus a fourth "+N more" tile. It opens the full list as a sheet over the info area, with Back in the footer. This reuses the Nurture-choices "Back" pattern (`warden_panel.gd:2501`).
- **Height budget at Large:** the drawer runs from about y 75 to 530 (455 px). Footer 56, plus a 2x2 tray of about 104 with an 8 px gap, takes about 170 px. That leaves about 250 px for the header, blurb and stats, and the Target grid scrolls. This is acceptable because Target is a once-per-Warden setting.
- **Highlight:** the primary affordable grow (`grow_primary`, `:392`) gets the gold primary frame, as Take does on the Dream screen. When a grow is primary, Nurture drops to secondary, as the code already does (`can_rank = false`).
- **Wide names:** keep the `_phone_grow_columns` fallback. A name that won't fit in half the width makes that tray one column, capped at 2 visible plus "+N more".

**Ask 2: details that should match the PC.** Seat P owns the field-by-field table. From my seat, the gaps that change decisions:
- the grow tip: role, changes, damage a second, Wakes, tax, rank cost (`:358-381`)
- branch roles on the family card
- the "not in this run / Remember" note

Static stats and statuses are already on the phone (the chips, plus the damage, rate, range and Potency row). The rule I'd use: anything the PC shows in a tip at the moment of a choice must be on screen at the moment of that choice on a phone.

**Ask 3: show branches on the family pick.** Phone cards have the room. Standard leaves about 100 px empty above the cards, and Large ends at y 440 with the footer at 480.
- Call the existing `_role_chips()` under each branch name, so each name gets 1-2 gold chips ("Area", "Heavy").
- Keep the lanes side by side in their flow.
- A tap on a lane opens a `TapTip` with its counters line and does not pick the card. Use the same `LINK_TAP_MS` guard that underlined words use (`phone_choice.gd:39`).
- Show the "not in this run" silhouettes at 24 px or larger. A tap on them gives the Remember note.
- Never show finals (owner rule, `:794`).

This matches what the PC card shows (`:816-819`), so it adds no hand-holding.

**Ask 4: hold a grow tile to see what it grows into.** Use one "grow card" with two ways in:
- **Where:** a Dream-card-sized panel on the map side, left of the drawer and vertically centred, so the drawer and the thumb never cover it. Inside it: the current portrait → the next portrait (as on Remember's detail panel, `large_remember`), the role points, then the key changes ("Damage 8 → 14, Range 2.5 → 3.0"), the damage-a-second line, Wakes, then cost, tax and rank. All of this is the `_grow_tip` text laid out as a card, not a tooltip. Show the map grow preview at the same time.
- **Hold (≥0.45 s, the same timing as `HOLD_LABEL_S`):** the card shows while the finger is down. Letting go closes it and never grows (standards D). Reuse hud.gd's block-signals-on-hold trick so the release doesn't count as a press.
- **Tap:** the first tap does what it does today (arms the tile, "Grow into X", map preview) and also pins the same card. The second tap grows. A tap anywhere else, or on another tile, disarms it. This is exactly the Dream screen's look-then-take, so the game has one choice grammar. It also avoids Slay the Spire mobile's complaint that tapping to read took the card, with no confirm step ([Pocket Gamer](https://www.pocketgamer.com/slay-the-spire/slay-the-spire-review-genre-defining-card-roguelike-finally-goes-mobile/)).
- Short of Dew: the card still opens (reading is free), with the price shown in POOR. Only the second tap refuses.

## 4. What other games do

**Copy:**
- **Tap to read, then a separate commit.** Wildfrost tells players to tap each card to read its effects, and that habit is how mobile players learn the game ([Pocket Tactics](https://www.pockettactics.com/wildfrost/review)). Slay the Spire mobile was criticised because inspecting could take the card, with no confirm ([Pocket Gamer](https://www.pocketgamer.com/slay-the-spire/slay-the-spire-review-genre-defining-card-roguelike-finally-goes-mobile/)). Heartwood's choice screens already do this right. Extend it to grows.
- **Show the upgrade before buying it.** Slay the Spire shows a preview of the card's new stats before an upgrade ([StS wiki](https://slaythespire.wiki.gg/wiki/Upgrade)). Our grow card is that preview.
- **The offer itself tells you the build.** In Vampire Survivors an evolution simply appears among the level-up choices once its pair is held ([Prima Games](https://primagames.com/gaming/vampire-survivors-weapon-evolution-guide)). The art and the name carry the "what it becomes", with no hint text. This fits the no-hand-holding rule: portraits and roles, not "Leads to" lines.
- **Bigger everything and targeting cues.** Playdigious enlarged text, buttons and touch areas for Loop Hero mobile, and added visual cues because the finger hides the target ([GameMaker blog](https://gamemaker.io/blog/pc-to-mobile-loop-hero)). Showing the grow card off to the side, with the map preview, does the same job.
- **One glossary everywhere.** Wildfrost's blue "?" tutorials can be opened at any time ([Pocket Tactics](https://www.pockettactics.com/wildfrost/review)). Keep the Glossary button on every choice screen, as Heartwood already does.

**Avoid:**
- **Tiny icons as the only way in.** Slay the Spire on Android ("a UI for ants", [Android Central](https://www.androidcentral.com/slay-spire-android-game-week)) and the TouchArcade forum ([thread](https://toucharcade.com/community/threads/slay-the-spire-by-megacrit-humble-bundle.409572/page-5)) both describe relic and status icons that take several taps to inspect.
- **Drag-only buy and sell.** Balatro mobile buys and sells by dragging cards to screen zones ([Shacknews](https://shacknews.com/article/141549/balatro-mobile-impressions?amphtml=1)). It works for Balatro's slow pace, but on a busy map, Heartwood's pinned buttons are safer.

I could not confirm from sources how Balatro, Monster Train or Legends of Kingdom Rush show long-press details, so I make no claims about them.

## 5. What works (keep it)
- The tap-look-Take grammar on every choice screen (`phone_choice.gd:10`): the looked card lifts and the others dim, and Take is renamed "Take Winding Path".
- Equal-weight skip and Take, with skip value shown ("Let it pass, +30", "Skip the gifts, +60").
- Peek at the map, Glossary and Your Dreams on every choice screen. Underlined glossary words that can be tapped inside cards.
- The family card already has its costs, status chip, Calling line, "Dreams into, 2 of 5 this run" and branch portraits. It needs only the roles.
- Omen offer: three plain bullets each side and an honest "Once revealed, you must take one".
- Remember's tree plus detail panel with Unlock pinned at the foot. It is the model for the grow card and for pinning.
- Sell on a red plate away from Nurture. Text is readable at both sizes.

Sources: [androidcentral.com](https://www.androidcentral.com/slay-spire-android-game-week), [pocketgamer.com StS](https://www.pocketgamer.com/slay-the-spire/slay-the-spire-review-genre-defining-card-roguelike-finally-goes-mobile/), [toucharcade StS thread](https://toucharcade.com/community/threads/slay-the-spire-by-megacrit-humble-bundle.409572/page-5), [shacknews Balatro](https://shacknews.com/article/141549/balatro-mobile-impressions?amphtml=1), [pockettactics Wildfrost](https://www.pockettactics.com/wildfrost/review), [gamemaker.io Loop Hero](https://gamemaker.io/blog/pc-to-mobile-loop-hero), [slaythespire.wiki.gg Upgrade](https://slaythespire.wiki.gg/wiki/Upgrade), [primagames VS evolutions](https://primagames.com/gaming/vampire-survivors-weapon-evolution-guide), [HIG context menu summary](https://hzzr.notion.site/Context-Menus-8f0afe7a59fe41e695150f89a196cdd6).
