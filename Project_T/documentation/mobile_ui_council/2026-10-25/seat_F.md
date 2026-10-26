# Seat F: First-time phone player (round 2026-10-25)

I read the screenshots in run order (hud, building, warden, drawer, family, dream, dreams list, omen, dossier, gifts,
pause, codex, settings, remember) as someone who just installed the free demo. Mostly `large_*`; `standard_*` checked
for the same issues.

## 1. Verdict
It looks good, and the first minute works: plant a Sprout, tap it, see a tidy drawer with big buttons. Where I'd get lost
is the **first growth choice**. The drawer gives me a list of names I've never seen (Driftspore, Bloomcap, Fairy Ring,
Lichenling, Brood Cap, Inkcap), all at the same price, with no picture and no role. The family screen talks in words I
haven't learned ("No Calling", "Dreams into, 2 of 5 this run"). I wouldn't quit on the map. I might quit at the gift
screen, which shows nothing to pick, and I'd play blind every time I grow a Warden.

## 2. Top problems (ranked)

**1. Grow rows are bare names (`large_drawer_sprout`, `large_drawer_grown`, `_scrolled`). L/M.**
Each row is a name plus a Dew price. Nothing on it tells me what the form does. On PC the hover tip carries that
(`warden_panel.gd:358`, `_grow_tip`), and the row is empty on purpose (`:369`, user 2026-10-24 "remove the information
underneath"). On a phone I have no hover, so I'd pick by name and get surprised. Six identical 120-Dew rows for
Sporeling is a guessing game. Fix: give every phone grow row the form's **sprite icon** (it already exists, the family
screen and Remember use it) and a **one-word role chip** (Area / Wall / Poison...). That's a label, not a hint, so it
doesn't break the no-hand-holding rule. The full details go on the hold / first tap (ask 4).

**2. The gift screen is empty (`large_gifts`, `standard_gifts`). S to check, maybe a real bug.**
The title says "The Heartwood offers a gift, take one", the hint says "Tap a card to look at it", and there are no
cards. "Take" sits there with nothing to take. If a real player saw this they'd think the game broke. Either the capture
grabbed it before the cards built, or the cards really don't show on phones. Verify on a device before anything else.

**3. Family pick talks in jargon and hides what the branches do (`large_family`). M.**
- "Oh. I know you." reads like a line meant for a returning player. On my first run it confused me.
- "No Calling." What's a Calling? I don't have one, so why tell me?
- "DREAMS INTO, 2 OF 5 THIS RUN" plus three faded icons: I read it as "this family is 2/5 unlocked". I didn't get
  that these are the forms it can grow into.
- "Brood Cap" and "Inkcap" appear as names only. Their roles are moved into tips when the card doesn't fit
  (`family_pick_screen.gd:268-274`, `_compact_card` step 0). There's plenty of empty space on the Large card, so the
  roles shouldn't have to go.
Fix in ask 3.

**4. HUD numbers that don't say what they count (`large_hud`). S.**
I could guess leaves (15/15) and Dew (460). I couldn't guess the purple "0" (Dreamlight) or the green globe "29". Then
there's "Price↑ 4/5" over the slot (the earlier council asked for "Price up 4/5"; the screenshot shows an arrow), and
"10" vs "3" under the two slots: is that cost or how many I have? "Select" with a dashed square looked like a
screenshot tool. Hold-to-name exists for the top-right buttons (c4bf24c4 item 1). Give the resource numbers the same
hold-to-name, and spell out the slot numbers as Dew prices ("💧10").

**5. The build preview's label is cut off (`large_building`). S.**
Bottom-right shows "2 Sprouts ◆25 +4…" clipped by the screen edge, right where my right thumb rests. That's the total I
need before I tap "Plant 2". Keep the label inside the safe area, or put the total on the Plant button ("Plant 2 · 💧25").

**6. Sell in the drawer looks like the selected option, not a danger (`large_warden`, `large_drawer_*`). S.**
Sell has the same orange outline as the selected "First" target, so to me it read as "highlighted / recommended".
c4bf24c4 item 12 says a red danger plate, but in these captures it isn't red. It's under my left thumb, the natural
place to tap. Make it read clearly as red, or ask me to confirm on the first sell.

**7. Dream cards that seem to do nothing (`large_dream`). S (wording).**
"Your maze now: +0% Dew a drift. With this: +0%." That reads as "this card is worth zero", and I wouldn't take it.
"Plant nothing for a whole block": what's a block? "Now: you planted this block, no free rank" tells me I've already
failed. Hide the "now" line while the value is 0 and say what earns it instead, and use "5 drifts" for "block". Send
this to the Wording Council.

**8. Pause menu leftovers (`large_pause`). S.**
"Copy save (dev)" shows up, which is fine if this is a debug capture. Check it never ships (item 7 says debug only).
"Abandon run…" has the same orange outline as Resume, so it looks like a recommended action. This is open item 14 and I
agree with it. The "Show lessons On" switch's knob is grey, so I couldn't tell whether it's on.

**9. Dreams list is a wall of rules (`large_dreams_list`). M, not urgent.**
Toll, rings, Chain, Reaction, stacks, Root, Frost, all in a single paragraph. The links help, but I'd close it. Put
the Calling's one-line summary first and fold the full rule under it.

## 3. The owner's asks

**Ask 1: pin the grow rows like Nurture.** Yes. When rows scroll I lose them, and I didn't even know there were six
until I scrolled. Layout, bottom to top:
- the footer stays: Sell (left, danger) and Nurture (right);
- above it a pinned **grow strip**: 1-2 options as full-width rows (icon, name, role chip, price); 3-4 options as a
  2x2 grid of icon tiles (icon, name, price);
- more than 4 options: the first 3 tiles plus a "+N more" tile that opens the full grow list as a sheet over the info
  area (pinned footer stays visible).
The info (description, stats, Target) scrolls above. Never let a grow tile sit directly next to Sell: put the 8 dp
gap and the danger colour between them.

**Ask 2: details matching the PC** (only what I noticed as a player; seat P has the full table).
- The phone shows a flask icon and "1.0" with no word. PC says "Potency 1.0" and "Poison" (`pc_drawer_grown`). I
  didn't know what the flask meant. Add the word, or hold the tile to name it.
- PC has a **Details** button. I found no way to the deeper page on the phone. Add it to the info area, not the footer.
- On PC, hovering a grow row gives the before/after numbers. The phone has nothing (problem 1).

**Ask 3: branches on the family card.** Under "Grows into", list each branch as icon, name and role word
("Brood Cap: area poison"), always shown. The Large card has the room. If a card truly can't fit, drop the flavour
blurb before the roles: the branches are what I'm actually choosing. Rename "DREAMS INTO, 2 OF 5 THIS RUN" to
"Grows into (2 of 5 forms this run)" and give the faded ones their names in dim text. Don't drop them (that's what
`NotInDream` hiding does, `family_pick_screen.gd:275-277`). Hide "No Calling." when there's no Calling.

**Ask 4: hold a grow button.** First-time players don't discover hold. I'd only find it by accident. So:
- **First tap** (already: preview on the map, the label becomes "Grow into X", `warden_panel.gd:368`) should also open
  the details card: sprite, role, before → after stats (damage, rate, range, status), cost and any rank/tax lines. Put
  it over the drawer's info area, not on the map under my thumb. Second tap on the same row grows.
- **Hold** shows the same card without arming the grow. Letting go closes it and buys nothing (standard D).
- Tapping another row switches the card. Tapping the map or ✕ cancels.
This is the Kingdom Rush pattern (below), and it means I always see what I'm buying before I pay.

## 4. What other games do (first-ten-minutes praise and complaints)
- **Slay the Spire (mobile).** The most common complaint: text is "quite tiny on an iPhone" and card controls are
  "clunky" (TouchArcade). Reviewers say tap-to-read turns into a drag (AppUnwrapper), and players on Steam say the phone
  version is easier to misclick. Heartwood **would** get this complaint on Remember (`large_remember`: the stat line
  "6.5 1.5/s 1.3" is tiny), on the Dreams list, and anywhere a hold is the only way to read something.
- **Balatro (mobile).** Praised as "almost a perfect port": text "generally easy to read". Its buttons were too small for
  phones, so buying and selling became drags to big zones (Shacknews). Its one complaint is a **Skip button placed
  where you fat-finger it** (Engadget). Heartwood risks the same with Sell next to Nurture and "Let it pass" / "Skip the
  gifts" beside Peek. Copy Balatro's big targets and keep the easy-to-regret button apart from the others.
- **Kingdom Rush (all mobile).** Tap a tower, and the ring shows upgrade icons with prices. Tap once to see what it
  does, tap the check to buy. Its encyclopedia is praised (MobyGames), and its tutorials teach the basics quickly
  (KR wiki). From memory rather than a page I re-checked: upgrades always show the next tower's **picture**, never a
  bare name. Heartwood's grow rows should do the same.
- **Infinitode 2.** Reviews call it "simple to learn, hard to master" (TapTap), with towers unlocked gradually as you
  progress (RAWG). Heartwood throws six named branches at me on the first growth. Gradual reveal or pictures would ease
  that.

Which of these Heartwood would get today: "tiny text" in the deep screens (Remember, Dreams list), "I don't know what
this upgrade does" on grow rows, and "I misclicked Sell". It would **not** get the Slay the Spire drag complaint:
tap-to-look then Take is clear (`large_dream_looked`: the button becomes "Take Winding Path", which is great).

## 5. What works (keep it)
- Tap a card, it lifts, and "Take Winding Path" names my choice. Clear and safe. Same on Omens.
- The Omen offer (`large_omen_offer`): three plain bullets, the best-written choice in the game.
- The dossier (`large_dossier`): "Keep the path turning: it charges down every straight of 4 cells or more." One line
  that tells me what to do. More of this.
- Big HUD buttons in the corners: Start drift, speed and pause under my right thumb.
- The drawer's 2x2 Target grid with full words, and the pinned Sell / Nurture footer.
- "Peek at the map" on every choice screen.
- The Codex search plus "See also" chips.

Sources:
- [TouchArcade: Slay the Spire iOS review](https://toucharcade.com/?p=268940)
- [TouchArcade: Slay the Spire iOS](https://toucharcade.com/?p=268725)
- [AppUnwrapper: Slay the Spire iOS review](https://www.appunwrapper.com/2020/06/13/slay-the-spire-ios-review/) (search summary; the page returned 403)
- [Steam discussion: Slay the Spire on phone](https://steamcommunity.com/app/646570/discussions/0/516333317611638857)
- [Engadget: Balatro is an almost perfect mobile port](https://www.engadget.com/gaming/balatro-is-an-almost-perfect-mobile-port-163050971.html)
- [Shacknews: Balatro mobile impressions](https://shacknews.com/article/141549/balatro-mobile-impressions)
- [MobyGames: Kingdom Rush](https://www.mobygames.com/game/54588)
- [Kingdom Rush Wiki: Frontiers](https://kingdomrushtd.fandom.com/wiki/Kingdom_Rush:_Frontiers)
- [TapTap: Infinitode 2 review](https://www.taptap.io/post/4644706)
- [RAWG: Infinitode 2](https://rawg.io/games/infinitode-2-infinite-tower-defense)
