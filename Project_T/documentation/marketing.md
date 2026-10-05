# Marketing plan: Heartwood TD

Owners (2026-10-04): **Marketing Discussion** (pitch, Steam page, copy, disclosure, posting) · **Short Form Video**
(§3–4: capture tools, shorts) · **Trailer** (§5) · Main Merger builds the capture code. Goal: **Steam wishlists.** Every video, post and
page points to the Steam page.

## 1. The pitch

- **One line:** *A dark-fairytale maze tower defence roguelite: your Wardens are the walls, and nightmares are coming for
  the dream.*
- **The hook in four words:** *Your Wardens are the maze.*
- **What makes it different** (lead with these, in this order):
  1. Wardens are walls: you build the maze the nightmares must walk.
  2. Combos and Reactions: statuses meet and chain (Soaked + Charged = Thunderclap, chains up to a ×10 Dawnburst).
  3. Every run is different: a new island, 2 of 5 branches per family, random Dreams, Omens and the Heartwood's Gifts
     that reshape the map.
  4. A dark fairytale look: cute Warden spirits against cold, eerie nightmares, in a starry dream void.
- **Feature lines** (the user, 2026-10-04: like the Legends of Idleon trailer's "Pick from over 100 classes"): each
  line *promises what you get to do*, never instructs ("Take one.", "Don't build any." read as orders). Verb first,
  inviting, a real number where we have one. Used by the trailer cards, the Steam About headers and short captions.
  The trailer shows only what makes the game special: **the maze and the combos** first, then Dreams and the scale.
  - *Build the maze with your Wardens*
  - *Make every nightmare take the long way*
  - *Discover combos between Wardens*
  - *Pick a Dream to power your maze*
  - *Grow over 100 Wardens* (**confirmed**, Tower Code 2026-10-04: 118 forms + the Heartwood Sapling. **Full game
    only**: the demo has 3 families, so a demo trailer or demo page can't use it)
  - *Chain lightning through the whole crowd*
  - *Choose from over 250 Dreams* (**confirmed**, Roguelite Code 2026-10-04: 262 cards offerable across full-game runs;
    "300+" is not true. 125 of them are Grove-planted, so full game only)
  Numbers go on screen only once the owning chat confirms them for the build the trailer ships with.
- **One name per thing** (the user, 2026-10-04: "make sure the wording is consistent"): the player's towers are always
  **Wardens**, the enemies **nightmares**, the cards **Dreams**, the goal **the Heartwood**. "Tower" appears only in
  the genre name ("tower defense", the Steam tag) and when talking about other games (Video 0's Warcraft maps).

## 2. Order of work

0. **First fans, one by one (start now, alongside everything below).** From "Why Indie Game Marketing Doesn't Work"
   (Indie Game Marketing Tips, 2025): channels and influencers amplify an audience you already have; they don't create
   the first one. So find the niche early and talk to players directly: maze-TD players (people who loved the Warcraft 3
   maze maps, Legion TD 2 and Element TD players), r/TowerDefense and r/roguelites (within each sub's rules), and a small
   **Discord** for the game. Invite a handful to **playtest the demo** (Steam Playtest or a private build), ask what they'd
   change, and iterate. These first fans become the word of mouth that makes the later steps work.

1. **Steam page** (before any push for views; wishlists only count once it exists): capsule art (Theme Asset, open
   item), the short description, 5–8 screenshots, the trailer, tags. Status and the tag list: §6 "Steam page checklist".
2. **Shorts and TikToks**: 3–4 a week, from the shot list below. **The first video is the developer's "why I made
   this"** (the user, 2026-10-04): the Warcraft 3 maze TD maps (Maze TD, Jungle TD) as the hook, roguelite runs as the
   twist, solo at your own pace as the reason. Script in §4 (Short Form Video), in the user's words. Name the mods only:
   no Warcraft footage, logos or art (Blizzard's trademarks). "Try the demo now" only once the demo is live; until then
   the call is "wishlist it on Steam", and the page must be up before it posts.
   **RESUMED 2026-10-04: finals go.** Theme re-called stable on stable_test2_t10 (main f2217e2d: base Wardens 64 px
   7a85c9d6, finals 1.4×, the tall-Warden fade aa80259d / f2217e2d), with the user's all-clear already given.
   History: **paused (the user, 2026-10-04): "Aren't we changing some of the tower assets? Pause the videos."** **All-clear given** (the user, via the design hub: "Then you
   can restart the video with the changes"): once the base-Warden revert to 64 px (Tower Assets + Tower Code) and the
   fade fix land, Short Form Video renders Theme's stable_test frame as a sanity check, then goes straight to the finals
   with no further user OK. Trailer follows the same gate. Before that, the render hold was released 2026-10-04: the user held final renders while the art changed; Theme Discussion called
   the look **stable** on the test capture `stable_test_t10` (main ec668620: bigger Wardens, ½-cell path, ground
   variation, Heartwood, nightmare readability and footing). Two small fixes follow (Beacon's Mark ring made crisp, Tower
   Code; the boxy top-right ground patch made ragged, Environment Code): only shots showing a Beacon mark or that patch
   re-render once they land. From now on, any change to the look goes through Theme Discussion first.
3. **Trailer** (60–90 s): once the capture tools exist.
4. **Demo + Steam Next Fest**: the biggest wishlist spike; plan it for when the demo is polished.

## 3. Capture tools (requested from Main Merger)

- **Capture mode** (debug setting): hides dev text, DPS tags, damage meter and dev buttons; options: clean HUD / no HUD.
- **Scripted capture scenes**: a small scene file (map seed, Wardens and their cells, Dew, drift, Omen or boss, camera
  path, speed). The game plays it and Godot's **Movie Maker** (`--write-movie`, fixed 60 fps) renders it, so late-game
  fights stay smooth however heavy. Re-run any clip after art changes.
- **Auto camera**: glide along the route, slow push-in, follow a nightmare, or hold on an area.
- **Export pipeline** (ffmpeg scripts): a 9:16 vertical crop or re-frame, burned-in captions, music, a "Wishlist on Steam"
  end card, and one file per platform (YouTube Shorts, TikTok, X / Bluesky 16:9).

**Half-cell mazes (2026-10-04, half_cells.md):** Wardens can sit at half-cell offsets, so walls stagger and mazes get
shapes a square grid can't make. Every capture scene uses staggered placements, and the maze shots show them off.
Capture after the half-cell merge (and after the final half-grid path art, when that lands, re-render).

## 4. Video 0 and the first five shorts (9:16, 15–35 s, captions on, music from the game's stems)

| # | Title / hook (first 2 s) | What happens | Capture setup |
|---|---|---|---|
| 1 | "Your Wardens ARE the maze." | Time-lapse: an empty island → a winding maze; the route mist stretches longer with each Warden ("+12 path"); then a drift floods in and walks the whole maze. | Test Grove, a fixed seed, scripted placements every 0.5 s, then drift 20 at 1×. |
| 2 | "Watch this chain." | One Charged nightmare is Soaked → Thunderclap → the chain jumps across a crowd → ×10 → Dawnburst. | A late storm board (Thunderhead, Lanternmoth, Rain Lily, Monsoon), drift 60, a dense block. |
| 3 | "The first boss." | The Hollow Stag's reveal (the What's coming page), its charge down a straight corridor, the maze bending it back, dispelled at 2 % health. | Drift 25, a fair board, the camera following the Stag. |
| 4 | "The forest moves." | A Heartwood's Gift (Sow a Ridge): a ridge rises, the route mist re-routes live, nightmares take the long way. Before / after split screen. | An act break, the gift screen, then the same drift before and after. |
| 5 | "One leaf left." | A close call: the last leaf, a nightmare at the Heartwood, the tree trembling, dispelled on its doorstep. | Drift ~40, 1 leaf left (Test Grove invulnerable off), the camera on the Heartwood. |

### Voiceover scripts (the developer voices them; ~150 words a minute, so each line fits its beat)

Delivered per short: a **no-caption, music-only version** (music at about −18 dB, so the voice sits on top) plus the
captioned one. Record the voice, drop it on the timeline, done. Speak like you're showing a friend; first person is fine.

**Video 0: "Why I made this" (~30 s + end card; posts first, once the Steam page is up; script: Marketing Discussion, short-form rewrite 2026-10-04)**
Name the Warcraft 3 maps only: no footage, logos or art from them. Wishlist call until the demo is live. Cut together from
several captures (export `cuts`, see `capture/video0.json`); every clip at real speed. The payoff (the chain) sits at ~60%.

| Time | Line (VO; captions follow it) | Shot (clip, in-point) |
|---|---|---|
| 0–2 s | *"I made a roguelite out of the old Warcraft 3 maze maps."* · big on-screen text: **"Warcraft 3 maze TD… but a roguelite"** | Empty island, the first Wardens snapping down (`video0_maze` 1–9 s, short 1's maze) |
| 2–8 s | *"Every Warden you place is a wall, and the nightmares have to walk whatever path you leave them."* | The maze growing, "+N path" (same clip) |
| 8–15 s | *"Each run is a new island, and at every rest you pick a Dream that changes how your maze plays."* | 8–10 s: a visibly different island, wide (act 4, `video0_island` 1.5–3.5 s); 10–15 s: a Rare Dream offer, the pick, a Sporeling growing into a Puffball (`video0_dream` 0.5–5.5 s) |
| 15–24 s | *"Then the combos kick in…"* (3–4 s with no words while the chain runs, peak ~23.5 s) *"…and the whole crowd lights up."* | Another island (act 3), the storm crowd chaining (`video0_storm` 12–21 s) |
| 24–28 s | *"Solo, at your own pace. It's called Heartwood TD."* | Pull-back over the whole maze with the drift in it (`video0_maze` 18.5–22.5 s) |
| 28–30.5 s | *"Wishlist it on Steam."* | End card (2.5 s) |

**Short 1: "Your Wardens ARE the maze." (~28 s)**
- 0–2.5 s: *"In my game, your Wardens are the walls."*
- 2.5–8 s: *"Every Warden you plant changes the path the nightmares have to walk. Longer path, more time to hit them."*
- 8–12.5 s: *"Fifty Wardens in, and the path's about four times as long as when I started."* (the hand-built maze: 50 Wardens, route ~18 → 70 cells)
- 12.5–28 s: *"Then I hit start, and they have to walk every bend of it."* · end card: *"It's called Heartwood TD. Wishlist it on Steam."*

**Short 2: "Watch this chain." (~24 s, real speed)**
- 0–2 s: *"Watch this chain."*
- 2–8 s: *"Water soaks them. Lightning charges them. Soaked and charged together? That's a Thunderclap."*
- 8–12 s: *"And it jumps. Nightmare to nightmare. Five, eight, ten…"*
- 12–24 s: *"Ten in a row is a Dawnburst."* (beat) *"I could watch that all day."* · end card line.

**Short 3: "The first boss." (~32 s)**
- 0–2 s: *"This is the first boss. The Hollow Stag."*
- 2–10 s: *"On long straight corridors, it charges, so the trick is: never give it a straight line."*
- 10–27 s: *"Bend the maze. Make it turn. Every corner kills its charge."*
- 27–32 s: *"A few tiles from the tree."* (beat) *"It never got its run-up."* · end card line.

**Short 4: "The forest moves." (~22 s)**
- 0–2 s: *"After every boss, the Heartwood gives you a gift."*
- 2–10 s: *"This one raises a ridge of dead trees wherever I want."*
- 10–17 s: *"Watch the route. It bends right around it. They have to take the long way now."*
- 17–22 s: *"Every run, the map is different, and you get to change it."* · end card line.

**Short 5: "One leaf left." (~19 s, one jump cut at 9 s)**
- 0–2 s: *"One leaf left."*
- 2–9 s: *"If one more nightmare reaches the tree, the run is over."*
- 9–16 s: *"Come on, come on…"* (let the action breathe)
- 16–19 s: *"Dispelled. On the doorstep."* (exhale) *"That's the game."* · end card line.

**Short 6: "Remember Warcraft 3 tower defense maps?" (~28 s; the user's hook, 2026-10-04; built from kit clips, the user edits)**
Name Warcraft only: no footage, logos or art from it. On-screen text uses "defense" (Steam tag); the VO can say either.

| Time | VO | On screen | Shot (kit clip, in-point) |
|---|---|---|---|
| 0–2 s | *"Remember Warcraft 3 tower defense maps?"* | **Remember Warcraft 3 TD maps?** | The maze snapping together (`video0_maze` from ~1.5 s, or `kit_build_ghost`) |
| 2–7 s | *"You'd spend the whole game building one giant maze… then watch everything walk it."* | | A drift walking the finished maze, wide (`kit_long_take_maze`, any 5 s after ~20 s) |
| 7–11 s | *"I couldn't find a game that felt like that anymore."* (beat) *"So I made one."* | | The pull-back over the whole maze, landing on "So I made one" (`video0_maze` 18.5–22.5 s) |
| 11–18 s | *"Your Wardens are the walls, and every run is a new island with a new maze."* | | Half-cell walls going down (`kit_half_cells`), then act 1 → act 4 (`kit_early_game` → `kit_late_game`) |
| 18–24 s | *"Then the combos kick in…"* (let the chain run 2–3 s) | | The storm chain (`short_02` ~9–13 s, or `kit_late_game`) |
| 24–28 s | *"It's called Heartwood TD. Wishlist it on Steam."* | | End card (the store art + logo) |

**TikTok alt hook (A/B; TikTok skews younger, so the Warcraft nostalgia may not land there):** same video, only two lines change.
- 0–2 s: VO *"This is a tower defense where you build the maze."* · on screen **A tower defense where YOU build the maze**
- 7–11 s: VO *"I couldn't find one like it,"* (beat) *"so I made one."*
Post the Warcraft version on YouTube Shorts and Reddit, the alt on TikTok, and compare 3-second holds.

**End card line (every short):** *"Heartwood TD. Wishlist it on Steam, link below."* (swap the name if it changes)

**Recording tips:** a quiet room, phone mic close and slightly off to the side, read each line two or three ways, and
keep the best take. Leave half a second of silence at the start and end. Lines can be trimmed to fit the cut.

Later ideas: "Can 60 Sprouts beat act 1?", "a 300-tile maze", "every Warden in one family", "this one card changed my run",
the Night Mare's laps, the Memory Grove growing, Rank V Nurture choices, the Spire-hard act 4.

**Caption style**: short, lowercase-casual on TikTok and title case on YouTube, one line per beat, never covering the action.
**Every short ends** with a 1.5 s card: the logo + "Wishlist on Steam" + the link in the description and comments.

## 5. Trailer script (≈75 s)

Owner: Trailer chat (2026-10-04). No logo intro: the first frame is the maze being built, because capsule A (the watchful
Warden) doesn't show the maze, so the trailer has to deliver "your towers are the maze" before any mood shot; pitch.md's
dispel hook comes second. Rules: every clip at real
speed (1×, never sped up or slowed: cut instead); every maze shows staggered half-cell walls (half_cells.md); wide
shots (the maze) alternate with close ones (zoom 3–4: nightmares, combos, bosses). **Cards (the user, on rough cut 2):
promise lines, not instructions**: verb first, inviting, a real number where there is one (like Legends of Idleon's
"Pick from over 100 classes"); show only what makes the game special, the maze and the combos. Numbers are full game
only (a demo trailer drops "over 100 Wardens").

| Time | Shot | On screen | Music |
|---|---|---|---|
| 0–5 s | Frame one: a staggered half-cell maze. Wardens snap down one after another; with each, the route mist bends live into a longer detour ("+N path"). | "Build the maze with your Wardens" | motif, Warden snaps on the pulse; carries through the cut |
| 5–8.33 s | Close (zoom 4): a Shade skitters in; a spore puff hits it; it cracks into motes. Cut one beat after. | | **hit 7.5 s**: the dispel |
| 8.33–15 s | Pull back: a crowd of nightmares walks every bend of the maze. | "Make every nightmare take the long way" | pulse returns |
| 15–25 s | Close on a crowd: Soaked, Charged, Thunderclap after Thunderclap. | "Discover combos between Wardens" | build; **hit 20 s** |
| 25–35 s | Lightning arcs, then the storm crowd close: a chain to ×10, Dawnburst. | "Chain lightning through the whole crowd" | drive; **the big hit at 30 s** |
| 35–40 s | A rest: the Dream pick (3 cards, one taken). | "Pick a Dream to power your maze" | a breath |
| 40–47.5 s | One Warden grows in place, close: Sprout → Sporeling → Driftspore → Puffball (40 / 41.25 / 42.5 / 43.75), the Ascended form at 45 shown only as a dark silhouette (a tease). | "Grow over 100 Wardens" (116 forms, Tower Code) | swells on 40 / 42.5 / 45 |
| 47.5–60 s | The Night Mare's gallop, the Hollow Oak, then the Stag (zoom 3, the follow leads it) dispelled on the 60 s hit. | "Dispel bosses" | gallop, Oak drums, the Stag's horn; **hit 60 s**, "the turn" (no silence) |
| 60–70 s | The Memory Grove: close on Rootling as it's planted (branch grows, bud opens), then a pull-back while the whole tree grows from fresh to full. | "and grow the Grove" | the hopeful motif out of the dispel's ring, rising |
| 70–75 s | The logo on the store art, the tagline *"Grow a living maze. Hold back the nightmares."*, "Wishlist on Steam", platforms. | "Heartwood TD" | the button + held D major chord |

**Music:** the dedicated trailer cue (§9), not the loop stems. Cuts sit on 2.5 s bars (72 bpm 3/4) and the four hits
fall on downbeats; if Sound Discussion picks another tempo, the cuts move to its bars. Cut changes go to Sound Discussion.

Dropped: the Omen screen, the Kinship and the Sow a Ridge gift (the user: show only the maze and the combos).

**Capture scenes** (`capture/trailer_*.json`, the cut list in `capture/trailer.json`, exported with `export.ps1 trailer`):
01 maze (also the drift walk), 02 Shade, 04 Thunderclap crowd, 05 Dream pick, 06 growth, 07 Stag, 08 Night Mare,
09 Hollow Oak, 10 storm to Dawnburst. Boards 01, 07 and 10 are copies of Short Form Video's tuned short boards.

**Timing:** final capture only after the grain clean-up (calm detail pass, Wardens and ground; Wardens keep the classic
golem, the per-family poses were dropped), the nightmare readability fix and the final half-grid path art (art_direction.md "AI-look audit", half_cells.md). A rough cut from today's art is fine
for timing. Steam wants the trailer first on the page: lock the date with Marketing Discussion.

## 6. Steam page text (draft)

**The capsule is concept A (the watchful Warden, 2026-10-04; brief in art_direction.md).** It doesn't show the maze, so
the hook "your Wardens are the maze" has to land in **screenshot 1**, the **first seconds of the trailer** and the **first
words of the short description**. Nothing on the page opens with lore or the look before the maze.

- **Short description (≤ 300 characters; 2026-10-04 rewrite, ~230):** *A maze tower defense roguelite where your Wardens
  are the walls. Every Warden you plant bends the path the nightmares take to the Heartwood. Soak them, then charge them,
  and the lightning jumps through the whole crowd. New island every run.*
  Leads with the maze (the capsule can't). Store copy spells "defense" (US) to match the Steam tag and search; in-game
  text stays UK. Replaces pitch.md's earlier draft (pitch.md points here). (Was: "Nightmares are hunting the Heartwood's
  dream…": flagged as generic in text_pass.md.)
- **About this game (draft v1, 2026-10-04; full game).** Format from Thronefall (§10): a bold promise line per block,
  a GIF under it, one or two plain sentences. One name per thing (§1). Numbers are confirmed unless marked.

  > **Your Wardens are the maze.**
  > *[GIF 1: an empty island; Wardens snap down one by one and the route mist bends into a longer detour, "+N path"]*
  > Every Warden you plant is also a wall. The nightmares re-route the moment it lands, so the path they walk is the
  > one you drew. The longer you make it, the longer your Wardens get to work on them.
  >
  > **Discover combos between Wardens.**
  > *[GIF 2: a Soaked crowd gets Charged; "Thunderclap!" and the lightning jumps through all of them]*
  > Soak a crowd, then charge it, and the lightning jumps from one nightmare to the next. There are 16 Reactions to find,
  > 8 of them Crowned ones that only happen when a third status joins in. Chain ten in a row and you'll see a Dawnburst.
  >
  > **Grow over 100 Wardens.**
  > *[GIF 3: a Sprout grows Sporeling → Driftspore → Puffball → Sporemother]*
  > Every Warden starts as a Sprout. Nine families branch out from there into final forms, and one step further, Ascended.
  >
  > **Pick from over 250 Dreams to power your maze.**
  > *[GIF 4: the Dream screen, three cards, one taken]*
  > Three Dreams at every rest. Some are bittersweet: more power now, a price later.
  >
  > **100 drifts. A new island every run.**
  > *[GIF 5: the Hollow Stag charging a straight corridor and stalling on a bend]*
  > Four acts, each ending in a boss that breaks a rule your maze relies on. The Hollow Stag charges down straight lines.
  > The boss you meet changes from run to run.
  >
  > **Grow the Memory Grove.**
  > *[GIF 6: the Grove tree with buds opening (needs Main Merger's grove capture)]*
  > Seeds from every run, won or lost, grow a tree of memories: six more Warden families, new Dreams, and small perks to
  > carry into the next dream.
  >
  > **Why I made it**
  > Heartwood TD started with the Warcraft 3 maze maps. The best part of those was the path: you built it, and every
  > enemy had to walk it. I wanted that on my own schedule, playing solo, with the pull of a roguelite, so no two runs
  > play out the same.

  (The user's story is context for this block, not a script: rewrite it in fresh words, claim nothing the user didn't
  say.) To check before it goes up: the boss pools
  (full game draws the boss per act, BossPool) and "six more families" (3 starting + 6 Grove, Tower Code) hold on the
  build that ships. GIFs: Short Form Video, ≤ 3 MB each, 616 px wide (Steam's About column), reusing the short / trailer
  boards. **Demo page:** a separate About with demo numbers (3 families, no Grove), never these.
- **Tags** (pitch.md's order; the first 5 matter most): Tower Defense, Roguelite, Strategy, Dark Fantasy, Cute, then Pixel
  Graphics, Atmospheric, Procedural Generation, Replay Value, Singleplayer, Steam Deck (once verified). No
  "Deckbuilding-lite": not a Steam tag, and Dream picks aren't a deck.
- **Screenshots, in order** (capture once the nightmare readability fix is in; Wardens keep the classic seated golem,
  the per-family poses were reverted 2026-10-04, art_direction.md 7049be26):
  1. **The maze:** a staggered half-cell maze (half_cells.md) at full scale with the **route shown** (route mist / line
     winding through it) and a drift walking it. Must read as "they built this path" as a 600 px thumbnail.
     Checks (first candidates, 2026-10-04): the bends are walled by **Wardens, not dead trees** (clear the obstacles
     in the maze area); combat is visible (puffs in the air, a dispel cracking); nightmares spread along the route and
     readable against the path; no dev labels; the banner names the default boss.
  2. Building: the ghost Warden, "+N path", the route preview bending into the new detour.
  3. A Reaction: Thunderclap lightning jumping through Soaked nightmares, callouts on.
  4. A dispel close-up: a nightmare cracking into light.
  5. The Dream screen: 3 cards, one Rare.
  6. A boss in the maze (the Hollow Stag on a bent corridor).
  7–8 (optional): the Memory Grove; a late-game board in another act's palette (Ascended / final Wardens, a dense
     drift), so the page shows the game changing. (The Gift ridge was dropped as a still: it only reads in motion.)
  **Rule for every still** (first review, 2026-10-04): action shots at zoom 2–4 (nightmares, combos, bosses), only the
  maze shot wide; vary the shots so they don't all look like the same dark violet board.

### Steam page checklist (status 2026-10-04)
| Item | Status | Waiting on |
|---|---|---|
| Name | **"Heartwood TD"** (decided 2026-09-28, pitch.md "Title") | free check: Steam, itch.io, trademark search for "Heartwood" |
| Studio | **"Topbunk Studios" (planned, not final;** spelling to confirm: Topbunk vs TopBunk) | the user's checks below; then the Steam developer / publisher fields, the end card / credits line, and a small wordmark (Theme Asset, hand-feel, anti-AI-look rules) |
| Capsule art | **A, chosen** (the watchful Warden, 2026-10-04); **AI-made for now** (Theme Asset) | artist: **deferred** (the user, 2026-10-04: "Leave it AI for now, then I'll decide later"; brief stays in art_direction.md) |
| Logo | not started; **AI-made for now** (Theme Asset) | artist: deferred, same as the capsule |
| Short description | drafted above, maze first | — |
| About | outline above | GIFs (capture tools) |
| Tags | drafted above | — |
| 5–8 screenshots | **#1 final, chosen:** `marketing/screenshots/final/screenshot_01_t12.png` (main b0efacf9, maze v4; passes at 600 px, nothing clipped)  **Also chosen:** #3 chain `screenshot_03_t9.5` (zoom 2, act 3), #5 Dream `screenshot_05_t1.5`, #6 Stag `screenshot_06_t13.0` (zoom 2, trample callout + boss bar), #8 late game `screenshot_08_t12` (act 4, Ascended, Reactions). #7 Memory Grove `screenshot_07_full_t1.0` (full preset, no UI; the page's warmest, most different shot). **Six done (Steam's minimum is five).** #4 dispel dropped: as a still it's a small shape on an empty path (it sells in motion, in the trailer). | #2 build ghost (Main Merger's ghost action) and #7 Grove (Main Merger's grove scene) are extras; the page doesn't wait for them |
| Trailer | §5; its first seconds = the maze. **Target: user-approved by 2026-10-07**, slips day for day if the video pause runs past 2026-10-05 (~1 day of render + rough cut after the all-clear, then review) | **the user's all-clear** (paused for the tower-asset changes); Sound's cue stems; then the user's review + one revision. Ready: 9 scenes dry-run, cut list 8459d82b, 16:9 export 902f7207 |
| AI disclosure | drafted in §7 | Valve's wording at submission |

## 7. AI disclosure (Steam requires it)

Steam's content survey asks about AI-generated content. The game's art, sound and much of its code and text were made with
AI assistance (art and audio by generator scripts written with AI). Disclose it plainly. Draft: *"This game was made with
the help of AI tools: its pixel art, sound effects and music were produced by generator scripts written with AI assistance,
and AI was used for code and writing. All content was directed, curated and edited by the developer."* Check Valve's current
wording at submission.

Valve's survey covers store-page assets too. While the capsule and logo are AI-made (artist deferred, 2026-10-04), the
disclosure must say so: add *"The store art and logo were also made with AI assistance."* Remove that line only if a
human artist replaces both.

## 8. Posting and measuring

- **2–3 shorts a week** (was 3–4; see the study below: frequency barely mattered, consistency and testing did). Post each
  on TikTok and YouTube Shorts, plus X / Bluesky and a relevant subreddit when it fits (r/TowerDefense, r/roguelites,
  r/godot for dev-angle clips; read each sub's self-promo rules).
- Post from **the developer's own account** (a solo dev's personal account reads as "a real indie game", people root for
  it). The Steam link and "wishlist" go in the **bio**: that mattered as much as saying it in the video.
- Track per video: 3-second hold, average watch %, shares, and wishlists that day (Steamworks). **Re-post each format 2–3
  times** before judging it; the same video can get 10k views one day and 1M the next.
- Reply to comments yourself; a real dev voice is the best marketing.
- **Hooks to A/B** (v2, 2026-10-04, built on the vidIQ outliers and the two studies; compare 3-second holds per platform).
  Every hook: on screen as text in the first second, and the short pays it off.
  | Format | Hook | Where | Clips |
  |---|---|---|---|
  | Mechanic in one sentence | "A tower defense where YOU build the maze" | TikTok | `build_ghost`, `s1_wardens_are_the_maze` |
  | Mashup | "What if Slay the Spire and a maze tower defense had a kid?" (the user's idea) | TikTok | open on `dream_cards` so the claim is visibly true, then the maze and a chain; we have no deck, so expect "this isn't Slay the Spire" comments |
  | Nostalgia | "Remember Warcraft 3 maze maps? I turned them into a roguelite." | YouTube Shorts, Reddit | `v0_*` clips |
  | Problem and fix (the strongest dev format) | "My Wardens got so strong the first boss never reached the tree." | all | `story_stag_rebalance_A` → `_B` |
  | Problem and fix | "Players kept sealing the path in my tower defense, so I had to stop them." | all | `path_blocked` |
  | Problem and fix | "I made my Wardens 40% bigger. Then I changed my mind." | all | `story_warden_size_*` |
  | Curiosity | "This boss has one weakness: corners." | all | `bosses/old_stag`, `s3_first_boss_stag` |
  | Early vs late | "Act 1 vs act 4 of my tower defense." | all | `early_game` / `late_game` split screen |
  | Close call | "One leaf left." | all | `s5_one_leaf_left`, `run_loss` |
  | Fans steering (only if the user will follow through) | "Comment a Warden idea. I'll make the best one." | TikTok | `families/` |
- **Track where wishlists come from**: a Steam **UTM link** per platform (TikTok bio, YouTube description, Reddit post),
  so Steamworks shows which platform drives wishlists. The most useful setup step; do it before the first post.
- **Tools** (the user edits): CapCut desktop for vertical edits and auto-captions (or DaVinci Resolve, free, heavier);
  Audacity to record the voice, Adobe Podcast Enhance (free) to clean it; native YouTube Studio / TikTok scheduling (or
  Metricool / Buffer to cross-post); native analytics for the 3-second hold. Further reading: Chris Zukowski's How To
  Market A Game, GameDiscoverCo.
- **Workflow for scripted shorts: voice first.** The user records the VO and sends it with the script name; Short Form
  Video times scenes so the beats land on the lines and renders clean clips cut to length. Pure-gameplay posts stay
  clip-first.
- Expectation: roughly **2 wishlists per 1,000 views** for gameplay-driven virality (~2,000–2,500 per million). Funny or
  dev-tip videos get views but convert a quarter to a tenth as well; paid boosts converted poorly. Don't pay for views.

### What a study of 100+ viral indie TikToks says (Indie Game Luke, "How 100 Indie Games Went Viral on TikTok", 2025)
- **Gameplay is king, and unique beats genre.** Tower defense / strategy was *rarely* seen going viral, so we win on what's
  distinct: Wardens that are the walls, the chain lightning, the Grove, the dark-fairytale look. Visual distinctiveness
  correlated with wishlists per view.
- **Formats that worked, mapped to us** (each a short series to test 2–3 times):
  1. *Pure gameplay*: "15 seconds of my maze tower defense". Shorts 1–2 already are this.
  2. *The trailer, vertical* (blurred-bar background): a cheap win once the trailer is approved.
  3. **Dev journey / how it started vs now** (the study's top pick): the first placeholder blocks and cozy prototype →
     today's Wardens and nightmares. The git history and old art are the source. Make this a series.
  4. **Early game vs late game**: an act 1 Sprout maze vs an act 4 storm of Ascended Wardens. A perfect fit for us.
  5. *Nostalgia*: "Remember Warcraft 3 maze TD?" (Video 0's hook); the study saw nostalgia clips hit 1M+.
  6. *Comparison to known games* ("Warcraft 3 maze TD meets a roguelite"): works when it's a new mix, backfires when it
     looks like a copy.
  7. *Ask for feedback* ("which Warden should get an Ascended form next?") and *responding to comments*.
  8. *Milestones*: Steam page live, demo out, Next Fest. Always post one.
  9. *A funny bug*: record it before fixing it.
- **Length didn't matter** (15 s to 2 min all went viral). Trending sounds and CapCut memes rarely mattered.
### vidIQ check (2026-10-04: YouTube Shorts "tower defense" outliers, last 6 months; TikTok + Reels indie-dev outliers since April)
- **Winning hooks state the one unusual mechanic as a sentence on screen in the first second**: "In this game your best
  loot isn't actually yours to keep" (1.1M), "A war game where you're not supposed to kill anyone" (54× the creator's
  median), "This Tower Defense Has 1 Million Enemies On Screen" (39×), "Is this Scrabble meets Tower Defense?". For us:
  *"A tower defense where you build the maze."* / *"You build the path the enemies have to walk."*
- **"I made this game because…"** opened a 130× outlier (an indie roguelite FPS), the same shape as Video 0.
- **Split screen (the dev talking to camera + gameplay)** appears in several outliers ("I just published my first game
  on Steam", 432× median). Worth testing once: the user on camera, the game below.
- **Low-effort can work**: a 13 s gameplay clip with one line of text and lo-fi music ("help an aspiring indie dev",
  36×) and a 12 s single-shot clip both broke out. Not everything needs a voiceover.
- **Tower defense does travel on TikTok** when it's a clear, readable fight: clips of *Sir, We Have an Orc Problem* hit
  45–99× their creators' medians with plain commentary over wave-by-wave planning.
- Most outliers: fast cuts, dynamic captions, voice + music, about a day's work.
- **Indie-dev outliers in general** (second pass, any genre, 100k+ views): the strongest dev format by far is
  **"a problem in my game, and how I fixed it"**: "The humans in my godsimulator are completely overpowered" (1.5M,
  88×), "This streamer found a major issue with the glider in my game" (1M, 321×), "Someone's trying to turn my shotgun
  into a pinpoint sniper rifle" (1.9M), "I REINVENTED shotguns for my indie game" (1.1M, 223×), "Playtesters are too
  good at my indie game". Ours, all true: the Wardens got so strong the Stag died 17 tiles from the tree (we re-tuned);
  players could seal the path, so placement had to be refused; the base Wardens grew 1.4× and went back.
  Also working: **fans steering the game** ("HAIL JIMOTHY PLEASE ADD HIM", 99×; "Making a game with your help. Am I
  cooked?", 40×), **stakes** ("Steam just handed me an ultimatum", 59×; "My indie game BLEW UP because I was dumb", 3M)
  and **"I made X, but Y"** ("I Made Minecraft, but It's 4D", 1.1M, 75×), which is Video 0's shape.
- **More curators** (YouTube Shorts channels whose indie features broke out): darkgeek ("THIS BRAZILIAN INDIE GAME IS
  INCREDIBLE", 1.6M, 49.7k subs), Keaton Luis ("Sniper Dan Is A Hilarious New Indie Game…", 1.3M, 184×, 17.5k subs),
  Warlord Mdama ("This Indie Game Lets You Build Your OWN Empire", 32×), Jake (Jake Lucky's indie dev segments).
- **Curators to pitch** once the Steam page is live (shorts channels featuring indie TD / roguelites): DimeByTheSword
  ("This Tower Defense Has 1 Million Enemies On Screen", 14.6k subs, 260k views) and Indie Game Joe (69.6k subs).

### Bopl Battle's playbook (Johan Grönvall on Jonas Tyroller's podcast, "TikTok and Shorts Are Insane for Indie Devs", 2025)
Shorts were the *only* marketing that worked for him (Reddit, YouTubers, even a big streamer barely showed on the
wishlist graph); roughly all his wishlists came from his own shorts (~70k at launch, his estimate).
- **Story shorts in the dev's own voice**: one a week (every Friday, about a day's work), each a real thing that happened
  while making the game: a bug turned into a feature, a friend's idea that saved an ability, a prank. Keep a running
  list of these stories as you work.
- **The first seconds**: say it's your game ("In my game…") and open an honest question the short answers ("I almost
  deleted this ability, but a friend had a brilliant idea to fix it"). Never click-bait: deliver the payoff, or the
  next video gets skipped.
- **No jargon the audience doesn't know.** His StarCraft-style "units and buildings" short flopped with TikTok's young
  audience. For us: avoid "drift", "Dreamlight", "Reactions" unexplained, and **don't rely on Warcraft 3 on TikTok**
  (many viewers never played it). Keep Video 0's Warcraft hook for YouTube, Reddit and older audiences; test a TikTok
  version that opens on the maze itself.
- **TikTok first, YouTube later**: TikTok tells you within days which shorts are good. Post only the proven ones to
  YouTube Shorts, in a burst around a big moment (demo, Next Fest, release). His YouTube exploded at launch (some shorts
  10–20M views). Stack the spikes: demo + Next Fest + a new short the same week.
- **A generous demo with visible locks**: his demo was nearly the full game, but every locked ability was visible by
  name, which made people want the full game. (For demo_scope.md's owners: show the locked families and Grove in the
  demo, named.)
- **Post-release updates + a short about each** kept producing sales spikes.

**Our story bank** (real things from this project; the user picks, tells them in their own words, adds their own):
the theme pivot from cozy to dark fairytale; "my Wardens are walls, so I had to stop players sealing the path";
half-cell placement making new maze shapes possible; the Hollow Stag, a boss built to punish straight corridors;
bigger Wardens tried and then reverted for the base forms; a chain that once hit ×26; the Memory Grove growing from
every run. Avoid making AI tools the story; the disclosure covers them.

- **Curators**: TikTok channels that feature indie games (e.g. Brax finds games, Mad Morph) got some games ~1M views the
  dev's own account never got. Pitch them once the Steam page is live.

## 9. Music for marketing (brief, 2026-10-04)

The user asked for trailer music and short-form music. Owner of the brief: Marketing Discussion. **Sound Discussion**
decides the musical direction (audio_direction.md), **Sound Code** synthesizes it (`tools/sound_generator.gd`), and
Trailer / Short Form Video cut to it. Today export.ps1 loops the 20 s in-game stems under every clip, which works as a
bed but has no shape: no hit on the hook, no build, no ending on the end card.

**Shared rules**
- Same world as the game: D minor, the game's instruments and motifs, "rounded, never sharp" (no clicks or crackle).
  Someone who hears a short and then plays the game should recognise it.
- Made in-house = no copyright claims on YouTube / TikTok. Post shorts with the original audio named
  "Heartwood TD – <cue>" so others can use the sound.
- Every cue ends **on** the end card (a resolve or a single held note that lands with the logo), never a fade or a
  loop cut.
- Each cue also exists as a **voice mix**: same music with the 300 Hz–3 kHz band thinned, for the voiceover versions.
- Deliver as WAV stems (low / mid / top / percussion) plus the full mix, so Trailer and Short Form Video can drop a layer.
- The music is not on hold: the art hold covers renders, not audio. Compose to the locked cut lists; when a cut moves,
  the cue's section map moves with it.

**1. Trailer cue (~75 s), through-composed to the §5 cut list** (Trailer's cuts snap to 2.5 s bars, 72 bpm 3/4;
7d6e9d8d; if Sound picks another tempo, Trailer re-snaps)
| Time | Picture | Music |
|---|---|---|
| 0–5 s | The maze being built | The motif alone, soft and warm; each Warden snap on a pulse (the snaps are the rhythm) |
| 5–10 s | The Shade close-up | Drop to near-silence, one cold low note; **hit 7.5 s**: the dispel |
| 10–15 s | The drift walks the maze | The pulse returns, low dread underneath |
| 15–27.5 s | Soaked + Charged, Thunderclap | Building; percussion enters; **hit 20 s**: the Thunderclap |
| 27.5–45 s | Rest, Dream pick (to 37.5), Gift | A breath: warmer, half the density (the rest swell), then rising again under the ridge |
| 45–60 s | Bosses | The boss material; heaviest low end; **hit 52.5 s**: a hard stop as the Stag stalls on the bend |
| 60–70 s | Dawnburst | Everything, the peak; **hit 65 s**: the chain's ×10 |
| 70–75 s | Logo, Wishlist | The resolve, one held warm chord under the logo |

**2. Short beds (9:16, 15–35 s)**
- **Instant start:** music at full presence from frame 1 (viewers decide in 2 s); no fade in.
- **One bed per mood, reusable:** *Build* (maze shorts 1 and 4: warm, steady pulse, rising as the maze grows), *Storm*
  (short 2: tension into a hit on the chain), *Boss* (short 3: the boss stem with a stinger on the dispel), *Close call*
  (short 5: the heartbeat thinning to near-silence, one release on the dispel). Each about 35 s with 2–3 hit points that
  a cut list can move.
- **Video 0 ("why I made this"):** the developer talking. Gentle, warm, mostly the base stem's motif, voice mix only;
  it lifts on "So I made one." under the maze pull-back and resolves on the end card.
- **End-card button:** a 1.5 s signature (the same two or three notes on every short), so the series has a sound.

**Sound's answers (audio_direction.md "Marketing music", 518676a8; Sound Code building):** 72 bpm 3/4 stays; energy
rises through density, subdivision, the bass an octave down for bosses and percussion layers, not tempo. The button is
the Heartwood motif's Hope form (D-A-F#, harp + music box, onto a warm D major), the same phrase players hear in game
when a boss falls. Short beds are rendered per short to Short Form Video's hit times (main hit on a downbeat, the rest
on a hits stem). Files land in `marketing/`: stems low / mid / top / perc, the full mix and the voice mix.

## 10. Comparables (research 2026-10-04; store pages + published trailer advice, the trailers not watched frame by frame)

| Game | Hook | How the page sells features | Takeaway for us |
|---|---|---|---|
| **Rogue Tower** (closest: roguelite TD, path control) | "a continuously expanding path which you can influence"; ends on a verb list "Unlock, build, upgrade, expand, defend." | "over 400 unique cards and upgrades" | Their path grows randomly and you steer it; **ours you build yourself**. Say "you build the path" plainly; don't let it read as the same game. |
| **Thronefall** (minimal TD/builder, ~1M sold) | one line: "A minimalist game about building and defending your little kingdom." | bold number headers: "10 Maps." "9 Unlockable Weapons." "Over 50 Unlockable Perks." | The format for our About section and the user's Idleon idea. Wishlists took off at **Next Fest with a demo** (+2,043 followers, #15 of ~1,000) plus the dev's YouTube. |
| **Legion TD 2** (sequel to the WC3 mod) | "the 2nd most popular Warcraft 3 mod of all time" | "over 100 unique fighters" | The WC3 heritage sells to exactly our audience (Video 0's angle); "over 100" is the genre's standard claim. |

**Trailer checks against published advice** (Derek Lieu via GameDiscover; Steam Page Analyzer): gameplay in the first 5 s, no logo intro
(ours: the maze build at 0 s ✓); 60–90 s (75 s ✓); readable muted, since Steam autoplays without sound (the cards carry it ✓);
text on gameplay, not full-screen slides (the scrim band ✓); end on a climax then title + "Wishlist" (the Dawnburst, then the end
card ✓); 1080p ✓. Later: a **second, longer trailer** (2–3 min) for the systems (combos, Dreams, growth), since released pages
average 2.4 videos; and a **muted dev-commentary cut** (Spelunky 2 did one) fits Video 0.

**About section format** (from Thronefall): bold number lead-ins, one line each, a GIF under each:
*Over 100 Wardens.* · *Over 250 Dreams.* · *Reactions* (number to confirm: 8 + 8 Crowned) · *100 drifts, 4 acts, a boss at
the end of each* (check the boss-pool count before claiming more). Full game only; the demo page uses demo numbers.
