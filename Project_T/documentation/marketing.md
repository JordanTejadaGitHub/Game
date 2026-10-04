# Marketing plan: Heartwood TD

Owners (2026-10-04): **Marketing Discussion** (pitch, Steam page, copy, disclosure, posting) · **Short Form Video**
(§3–4: capture tools, shorts) · **Trailer** (§5) · Main Merger builds the capture code. Goal: **Steam wishlists.** Every video, post and
page points to the Steam page.

## 1. The pitch

- **One line:** *A dark-fairytale maze tower defence roguelite: your Wardens are the walls, and nightmares are coming for
  the dream.*
- **The hook in four words:** *Your towers are the maze.*
- **What makes it different** (lead with these, in this order):
  1. Wardens are walls: you build the maze the nightmares must walk.
  2. Combos and Reactions: statuses meet and chain (Soaked + Charged = Thunderclap, chains up to a ×10 Dawnburst).
  3. Every run is different: a new island, 2 of 5 branches per family, random Dreams, Omens and the Heartwood's Gifts
     that reshape the map.
  4. A dark fairytale look: cute Warden spirits against cold, eerie nightmares, in a starry dream void.

## 2. Order of work

1. **Steam page** (before any push for views; wishlists only count once it exists): capsule art (Theme Asset, open
   item), the short description, 5–8 screenshots, the trailer, tags. Status and the tag list: §6 "Steam page checklist".
2. **Shorts and TikToks**: 3–4 a week, from the shot list below. **The first video is the developer's "why I made
   this"** (the user, 2026-10-04): the Warcraft 3 maze TD maps (Maze TD, Jungle TD) as the hook, roguelite runs as the
   twist, solo at your own pace as the reason. Script in §4 (Short Form Video), in the user's words. Name the mods only:
   no Warcraft footage, logos or art (Blizzard's trademarks). "Try the demo now" only once the demo is live; until then
   the call is "wishlist it on Steam", and the page must be up before it posts.
   **Hold on all video renders** (the user, 2026-10-04): the path and other environment art are still changing, so no
   final renders of shorts, the trailer or screenshots until Theme Discussion calls the look stable. Open: the Heartwood
   glow fix and path ribbon (Environment Code), **ground variation** (moss / clearing / flower patches; Environment
   Discussion → Assets + Code), bigger dead-fruit husks on the Heartwood, **bigger Wardens** (if the user approves the
   preview, the whole roster changes first). Environment Assets' other art is final. Done: grain clean-up, nightmare readability. Scripts, voiceover, capture scenes and test renders can go on.
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

## 4. The first five shorts (9:16, 15–35 s, captions on, music from the game's stems)

| # | Title / hook (first 2 s) | What happens | Capture setup |
|---|---|---|---|
| 1 | "Your towers ARE the maze." | Time-lapse: an empty island → a winding maze; the route mist stretches longer with each Warden ("+12 path"); then a drift floods in and walks the whole maze. | Test Grove, a fixed seed, scripted placements every 0.5 s, then drift 20 at 1×. |
| 2 | "Watch this chain." | One Charged nightmare is Soaked → Thunderclap → the chain jumps across a crowd → ×10 → Dawnburst. Slow-motion on the ×10. | A late storm board (Thunderhead, Lanternmoth, Rain Lily, Monsoon), drift 60, a dense block. |
| 3 | "The first boss." | The Hollow Stag's reveal (the What's coming page), its charge down a straight corridor, the maze bending it back, dispelled at 2 % health. | Drift 25, a fair board, the camera following the Stag. |
| 4 | "The forest moves." | A Heartwood's Gift (Sow a Ridge): a ridge rises, the route mist re-routes live, nightmares take the long way. Before / after split screen. | An act break, the gift screen, then the same drift before and after. |
| 5 | "One leaf left." | A close call: the last leaf, a nightmare at the Heartwood, the tree trembling, dispelled on its doorstep. | Drift ~40, 1 leaf left (Test Grove invulnerable off), the camera on the Heartwood. |

### Voiceover scripts (the developer voices them; ~150 words a minute, so each line fits its beat)

Delivered per short: a **no-caption, music-only version** (music at about −18 dB, so the voice sits on top) plus the
captioned one. Record the voice, drop it on the timeline, done. Speak like you're showing a friend; first person is fine.

**Short 1: "Your towers ARE the maze." (~25 s)**
- 0–2 s: *"In my game, your towers are the walls."*
- 2–10 s: *"Every Warden you plant changes the path the nightmares have to walk. Longer path, more time to hit them."*
- 10–18 s: *"Forty Wardens in, and the path's about three times as long as when I started."* (the clip's real count)
- 18–25 s: *"Then I hit start, and they have to walk every bend of it."* · end card: *"It's called Heartwood TD. Wishlist it on Steam."*

**Short 2: "Watch this chain." (~22 s)**
- 0–2 s: *"Watch this chain."*
- 2–8 s: *"Water soaks them. Lightning charges them. Soaked and charged together? That's a Thunderclap."*
- 8–16 s: *"And it jumps. Nightmare to nightmare. Five, eight, ten…"*
- 16–22 s: *"Ten in a row is a Dawnburst."* (beat) *"I could watch that all day."* · end card line.

**Short 3: "The first boss." (~30 s)**
- 0–2 s: *"This is the first boss. The Hollow Stag."*
- 2–10 s: *"On long straight corridors, it charges, so the trick is: never give it a straight line."*
- 10–22 s: *"Bend the maze. Make it turn. Every corner kills its charge."*
- 22–30 s: *"A few tiles from the tree."* (beat) *"It never got its run-up."* · end card line.

**Short 4: "The forest moves." (~22 s)**
- 0–2 s: *"After every boss, the Heartwood gives you a gift."*
- 2–10 s: *"This one raises a ridge of dead trees wherever I want."*
- 10–17 s: *"Watch the route. It bends right around it. They have to take the long way now."*
- 17–22 s: *"Every run, the map is different, and you get to change it."* · end card line.

**Short 5: "One leaf left." (~20 s)**
- 0–2 s: *"One leaf left."*
- 2–9 s: *"If one more nightmare reaches the tree, the run is over."*
- 9–16 s: *"Come on, come on…"* (let the action breathe)
- 16–20 s: *"Dispelled. On the doorstep."* (exhale) *"That's the game."* · end card line.

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
speed (1×, never sped up or slowed: cut instead); every maze shows staggered half-cell walls (half_cells.md); cards say
one concrete thing each, in the developer's voice (text_pass.md), and read in under 3 s.

| Time | Shot | On screen | Music |
|---|---|---|---|
| 0–5 s | Frame one: a staggered half-cell maze. Wardens snap down one after another; with each, the route mist bends live into a longer detour ("+N path"). | "Your Wardens are the walls." | base stem |
| 5–9 s | Close on the forest edge: a Shade's eyes open and it skitters in. A spore puff hits it; it shrieks and cracks into motes. | | quiet beat |
| 9–16 s | Pull back: the drift streams in and walks every bend of the maze; dispels along it. | "Now they take the long way." | + dread1 |
| 16–28 s | A Soaked crowd, Charged: Thunderclap callouts; Poisoned fog on the next bend. | "Soaked + Charged = Thunderclap." | + dread2 |
| 28–38 s | A rest: the Dream pick (3 cards, one taken); a Warden grows into its branch; Kinship roots join two kin. | "Three Dreams at every rest. Take one." | rest swell |
| 38–46 s | A Heartwood's Gift (Sow a Ridge): the ridge rises, the route bends around it live. | "That ridge wasn't there a minute ago." | |
| 46–60 s | The Hollow Stag charges a straight corridor, then stalls on a bend; cut to the Night Mare's laps; the Hollow Oak rising. | "The Stag charges down straight lines. So don't build any." (over the Stag only) | + heartbeat, boss stem from the Oak |
| 60–70 s | A late storm board: one chain to ×10, Dawnburst; the Heartwood glowing gold. | | full |
| 70–75 s | Logo, the tagline *"Grow a living maze. Hold back the nightmares."*, "Wishlist on Steam", platforms. | "Heartwood TD" (pitch.md "Title"; trademark check pending) | resolve |

Dropped from the draft: the Omen screen (a second menu in 10 s; save it for a short).

**Capture scenes needed (Main Merger, capture_director.gd):** (1) a staggered maze built Warden by Warden, route mist
bending each time (the opening shot; Short Form Video's short_01 idea at 16:9); (2) forest-edge Shade close-up; (3) drift ~20 walking the maze; (4) a storm board on a Soaked crowd, drift ~40; (5) a rest with Dream
pick, grow and a Kinship; (6) an act break with Sow a Ridge; (7) drift 25 Stag on a board with one straight corridor;
(8) the Night Mare; (9) the Hollow Oak's arrival; (10) a late storm board to Dawnburst, drift ~60, the Heartwood at a
high Grove stage.

**Timing:** final capture only after the grain clean-up (calm detail pass, Wardens and ground; Wardens keep the classic
golem, the per-family poses were dropped), the nightmare readability fix and the final half-grid path art (art_direction.md "AI-look audit", half_cells.md). A rough cut from today's art is fine
for timing. Steam wants the trailer first on the page: lock the date with Marketing Discussion.

## 6. Steam page text (draft)

**The capsule is concept A (the watchful Warden, 2026-10-04; brief in art_direction.md).** It doesn't show the maze, so
the hook "your towers are the maze" has to land in **screenshot 1**, the **first seconds of the trailer** and the **first
words of the short description**. Nothing on the page opens with lore or the look before the maze.

- **Short description (≤ 300 characters; 2026-10-04 rewrite, ~230):** *A maze tower defense roguelite where your towers
  are the walls. Every Warden you plant bends the path the nightmares take to the Heartwood. Soak them, then charge them,
  and the lightning jumps through the whole crowd. New island every run.*
  Leads with the maze (the capsule can't). Store copy spells "defense" (US) to match the Steam tag and search; in-game
  text stays UK. Replaces pitch.md's earlier draft (pitch.md points here). (Was: "Nightmares are hunting the Heartwood's
  dream…": flagged as generic in text_pass.md.)
- **About (outline):** the hook (Wardens are the maze) · combos and Reactions · runs that are never the same (branches,
  Dreams, Omens, Gifts) · bosses · the Memory Grove (meta progression) · the look and sound. Write each block as one
  concrete scene from play (a GIF + two sentences), not a feature list. The first GIF is a maze being built.
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
  7–8 (optional): the Memory Grove; a Heartwood's Gift reshaping the island.

### Steam page checklist (status 2026-10-04)
| Item | Status | Waiting on |
|---|---|---|
| Name | **"Heartwood TD"** (decided 2026-09-28, pitch.md "Title") | free check: Steam, itch.io, trademark search for "Heartwood" |
| Capsule art | **A, chosen** (the watchful Warden, 2026-10-04); **AI-made for now** (Theme Asset) | artist: **deferred** (the user, 2026-10-04: "Leave it AI for now, then I'll decide later"; brief stays in art_direction.md) |
| Logo | not started; **AI-made for now** (Theme Asset) | artist: deferred, same as the capsule |
| Short description | drafted above, maze first | — |
| About | outline above | GIFs (capture tools) |
| Tags | drafted above | — |
| 5–8 screenshots | **on hold**; order above, #1 = half-cell maze + route | nightmare readability (art_direction.md 395fed8a: Enemy Assets done f07637d1; Enemy Code shader, Environment Assets path shadows to land); Warden poses no longer block (reverted 7049be26); capture scene: inland clear + Warden-walled maze (Main Merger) |
| Trailer | §5; its first seconds = the maze | Trailer chat, capture tools; date locked by Marketing Discussion |
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

- 3–4 shorts a week; post each on TikTok and YouTube Shorts, plus X / Bluesky and a relevant subreddit when it fits
  (r/TowerDefense, r/roguelites, r/godot for dev-angle clips; read each sub's self-promo rules).
- Track per video: 3-second hold, average watch %, shares, and wishlists that day (Steamworks). Keep what holds past 3 s;
  test 2–3 hooks on the same clip.
- Reply to comments yourself; a real dev voice is the best marketing.
