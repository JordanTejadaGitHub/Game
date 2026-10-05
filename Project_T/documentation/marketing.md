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
| 1 | "Your towers ARE the maze." | Time-lapse: an empty island → a winding maze; the route mist stretches longer with each Warden ("+12 path"); then a drift floods in and walks the whole maze. | Test Grove, a fixed seed, scripted placements every 0.5 s, then drift 20 at 1×. |
| 2 | "Watch this chain." | One Charged nightmare is Soaked → Thunderclap → the chain jumps across a crowd → ×10 → Dawnburst. | A late storm board (Thunderhead, Lanternmoth, Rain Lily, Monsoon), drift 60, a dense block. |
| 3 | "The first boss." | The Hollow Stag's reveal (the What's coming page), its charge down a straight corridor, the maze bending it back, dispelled at 2 % health. | Drift 25, a fair board, the camera following the Stag. |
| 4 | "The forest moves." | A Heartwood's Gift (Sow a Ridge): a ridge rises, the route mist re-routes live, nightmares take the long way. Before / after split screen. | An act break, the gift screen, then the same drift before and after. |
| 5 | "One leaf left." | A close call: the last leaf, a nightmare at the Heartwood, the tree trembling, dispelled on its doorstep. | Drift ~40, 1 leaf left (Test Grove invulnerable off), the camera on the Heartwood. |

### Voiceover scripts (the developer voices them; ~150 words a minute, so each line fits its beat)

Delivered per short: a **no-caption, music-only version** (music at about −18 dB, so the voice sits on top) plus the
captioned one. Record the voice, drop it on the timeline, done. Speak like you're showing a friend; first person is fine.

**Video 0: "Why I made this" (~34 s; posts first, once the Steam page is up; script: Marketing Discussion, the user's words)**
Name the Warcraft 3 maps only: no footage, logos or art from them. Wishlist call until the demo is live. Cut together from
several captures (export `cuts`, see `capture/video0.json`); every clip at real speed.

| Time | Line | Shot (clip) |
|---|---|---|
| 0–3 s | *"Remember the Warcraft 3 maze tower defense maps?"* | Empty island, the first Wardens snapping down (`video0_maze`, short 1's hand-built maze) |
| 3–9 s | *"Maze TD, Jungle TD. You built the maze yourself, and every tower was a wall."* | The maze growing, the route stretching ("+N path") (`video0_maze`) |
| 9–17 s | *"I love tower defense. I love roguelites like Slay the Spire and Risk of Rain 2."* | A Dream card pick at a rest, then a Sporeling growing into a Puffball (`video0_dream`) |
| 17–23 s | *"I couldn't find a game that mixed the two."* (beat) *"So I made one."* | Close on the drift in the maze, pulling back to the whole maze on "So I made one" (`video0_maze`) |
| 23–29 s | *"Single-player, at your own pace, and every run plays out differently."* | A different island, a Reaction chain across a crowd (`video0_storm`) |
| 29–34 s | *"It's called Heartwood TD. If that sounds like your thing, wishlist it on Steam."* | End card (held longer than the shorts' 1.5 s) |

**Short 1: "Your towers ARE the maze." (~28 s)**
- 0–2.5 s: *"In my game, your towers are the walls."*
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
| 0–5 s | Frame one: a staggered half-cell maze. Wardens snap down one after another; with each, the route mist bends live into a longer detour ("+N path"). | "Your Wardens are the walls." | motif, Warden snaps on the pulse |
| 5–10 s | Close on the forest edge: a Shade's eyes open and it skitters in. A spore puff hits it; it shrieks and cracks into motes. | | near-silence; **hit 7.5 s**: the dispel |
| 10–15 s | Pull back: the drift streams in and walks every bend of the maze; dispels along it. | "Now they take the long way." | pulse returns |
| 15–27.5 s | A Soaked crowd, Charged: Thunderclap callouts; Poisoned fog on the next bend. | "Soaked + Charged = Thunderclap." | build; **hit 20 s**: the Thunderclap |
| 27.5–37.5 s | A rest: the Dream pick (3 cards, one taken); a Warden grows into its branch; Kinship roots join two kin. | "Three Dreams at every rest. Take one." | breath |
| 37.5–45 s | A Heartwood's Gift (Sow a Ridge): the ridge rises, the route bends around it live. | "That ridge wasn't there a minute ago." | |
| 45–60 s | The Hollow Stag charges a straight corridor, then stalls on a bend; cut to the Night Mare's laps; the Hollow Oak rising. | "The Stag charges straight lines. Don't build any." (over the Stag only) | boss; **hit 52.5 s**: the Stag stalls |
| 60–70 s | A late storm board: one chain to ×10, Dawnburst; the Heartwood glowing gold. | | full; **hit 65 s**: the Dawnburst |
| 70–75 s | Logo, the tagline *"Grow a living maze. Hold back the nightmares."*, "Wishlist on Steam", platforms. | "Heartwood TD" (pitch.md "Title"; trademark check pending) | held chord from 70 s |

**Music:** the dedicated trailer cue (§9), not the loop stems. Cuts sit on 2.5 s bars (72 bpm 3/4) and the four hits
fall on downbeats; if Sound Discussion picks another tempo, the cuts move to its bars. Cut changes go to Sound Discussion.

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
| 5–8 screenshots | **#1 final, chosen:** `marketing/screenshots/final/screenshot_01_t12.png` (main b0efacf9, maze v4; passes at 600 px, nothing clipped) | #2–8: capture scenes still to write (Short Form Video / Trailer can reuse their boards: build ghost, Thunderclap, dispel, Dream screen, Stag, Grove) |
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

- 3–4 shorts a week; post each on TikTok and YouTube Shorts, plus X / Bluesky and a relevant subreddit when it fits
  (r/TowerDefense, r/roguelites, r/godot for dev-angle clips; read each sub's self-promo rules).
- Track per video: 3-second hold, average watch %, shares, and wishlists that day (Steamworks). Keep what holds past 3 s;
  test 2–3 hooks on the same clip.
- Reply to comments yourself; a real dev voice is the best marketing.

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
