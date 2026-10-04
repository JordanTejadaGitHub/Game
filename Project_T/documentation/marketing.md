# Marketing plan: Heartwood TD

Owners (2026-10-04): **Marketing Discussion** (pitch, Steam page, copy, disclosure, posting) and **Short Form Video**
(sections 3–5: capture tools, shorts, trailer; Main Merger builds the capture code). Goal: **Steam wishlists.** Every video, post and
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
   item), the short description, 5–8 screenshots, the trailer, tags (Tower Defense, Roguelite, Strategy, Deckbuilding-lite,
   Pixel Graphics, Dark Fantasy, Singleplayer).
2. **Shorts and TikToks**: 3–4 a week, from the shot list below.
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
- 10–18 s: *"So you're not just placing towers. You're building a maze, one Warden at a time."*
- 18–25 s: *"And then they come. All of them. Through every twist you built."* · end card: *"It's called Heartwood TD. Wishlist it on Steam."*

**Short 2: "Watch this chain." (~22 s)**
- 0–2 s: *"Watch this chain."*
- 2–8 s: *"Water soaks them. Lightning charges them. Soaked and charged together? That's a Thunderclap."*
- 8–16 s: *"And it jumps. Nightmare to nightmare. Five, eight, ten…"*
- 16–22 s: *"Ten in a row is a Dawnburst."* (beat) *"I could watch that all day."* · end card line.

**Short 3: "The first boss." (~30 s)**
- 0–2 s: *"This is the first boss. The Hollow Stag."*
- 2–10 s: *"On long straight corridors, it charges, so the trick is: never give it a straight line."*
- 10–22 s: *"Bend the maze. Make it turn. Every corner kills its charge."*
- 22–30 s: *"Two percent health left at the door. Close."* (beat) *"Too close."* · end card line.

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

| Time | Shot | On screen |
|---|---|---|
| 0–5 s | Straight into building: Wardens snap down and the route mist bends. | "Your Wardens are the walls." |
| 5–15 s | A drift arrives; nightmares follow the maze; the first dispels crack into light. | "The nightmares must take the long way." |
| 15–30 s | Statuses meet: Soaked, Charged, Thunderclap; Poisoned fog; the first Reaction callouts. | "Combine them." |
| 30–42 s | Dreams (a card pick), a branch grows (Remember screen → Grow), Kinship roots form. | "Grow your Wardens. Shape every run." |
| 42–52 s | A Heartwood's Gift reshapes the island; an Omen screen. | "Every dream is different." |
| 52–65 s | Bosses: the Stag's charge, the Night Mare, the Hollow Oak rising. Music builds (the boss stem). | "Something old has found the dream." |
| 65–72 s | The biggest late-game chain to a Dawnburst; the Heartwood glowing. | |
| 72–75 s | The logo, "Wishlist on Steam", platforms. | |

## 6. Steam page text (draft)

- **Short description (≤ 300 characters):** *Nightmares are hunting the Heartwood's dream. Plant Warden spirits that are also
  the walls of your maze, combine their powers into chain Reactions, and grow a new forest every run in this dark-fairytale
  tower defence roguelite.*
- **About (outline):** the hook (Wardens are the maze) · combos and Reactions · runs that are never the same (branches,
  Dreams, Omens, Gifts) · bosses · the Memory Grove (meta progression) · the look and sound.

## 7. AI disclosure (Steam requires it)

Steam's content survey asks about AI-generated content. The game's art, sound and much of its code and text were made with
AI assistance (art and audio by generator scripts written with AI). Disclose it plainly. Draft: *"This game was made with
the help of AI tools: its pixel art, sound effects and music were produced by generator scripts written with AI assistance,
and AI was used for code and writing. All content was directed, curated and edited by the developer."* Check Valve's current
wording at submission.

## 8. Posting and measuring

- 3–4 shorts a week; post each on TikTok and YouTube Shorts, plus X / Bluesky and a relevant subreddit when it fits
  (r/TowerDefense, r/roguelites, r/godot for dev-angle clips; read each sub's self-promo rules).
- Track per video: 3-second hold, average watch %, shares, and wishlists that day (Steamworks). Keep what holds past 3 s;
  test 2–3 hooks on the same clip.
- Reply to comments yourself; a real dev voice is the best marketing.
