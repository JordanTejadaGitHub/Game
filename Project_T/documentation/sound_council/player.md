# Sound Council 2026-10-23: the player's ears (player.md)

Seat: does sound tell me what's happening? I started from the user's complaint ("placing a Warden / Sprout down
doesn't sound right") and walked the build loop, then every other event. Each finding names its evidence:
**[doc]** audio_direction.md (round copy), **[recipe]** tools/sound_generator.gd, **[num]** sounds_measured.tsv,
**[wire]** scripts/audio/sound.gd / sound_hooks.gd / gameplay scripts. I cannot hear; "(check)" = unsure.

Effective level below = file peak dB + the hook's volume_db (before buses, crowding and distance).

---

## 1. Top 10 findings, ranked

### 1. Building while paused is silent, then the sounds all land on unpause (plant, sell, tend, move, evolve, nurture)
- **What the player gets:** pause (Space, or a paused Lesson card), plant five Sprouts: nothing. Unpause: up to four
  plant sounds at once, seconds after the actions, none of them where the player is looking now. Planting more than
  four while paused: the rest are dropped (the four frozen players hold all of `plant`'s voices).
- **Evidence [wire]:** `Sound.play()` with a world position adds an AudioStreamPlayer2D under the scene,
  "In the world, so it pauses with the game" (sound.gd:177). The authors know this: Final Bloom is played
  "Unpositioned: growing works while the game is paused" (sound_hooks.gd:741) and the harvest likewise (:1046).
  But plant (:234), sell (:238), tend/move (:241), evolve (:634), nurture (:735), gift pieces (:1302), Dream pulses
  on Wardens (:1278) all pass a position. CLAUDE.md: build/clear/sell tools are `process_mode = ALWAYS` "so building
  works while paused"; LessonCards "enforce pause while visible". `MAX_VOICES` 4 counts paused players (sound.gd:166).
- **Fix:** player-action sounds (plant, plant_*, sell, tend, move, evolve*, nurture*, focus_*, the Dream pulses,
  invalid already is) must play while paused: either a `Sound.play_action(id, at, …)` that creates the
  AudioStreamPlayer2D with `process_mode = PROCESS_MODE_ALWAYS` (keeps the pan), or play them flat on the UI/SFX
  bus with a manual pan from the screen x. This alone may be most of "doesn't sound right": a first-run player
  plants during the paused lessons and hears nothing, or hears it late.

### 2. One placement sound for everything: Sprout, Thornwall, every family, gift pieces
- **What the player gets:** a 10-Dew Sprout, a Thornwall (a wall of thorns that never attacks) and a full family
  Warden all make the identical "thump, rising whoosh, harp note". The wall has no thorns, the spirit has no spirit.
  The art is a little spirit settling on a **waystone**; nothing in the sound is stone or spirit.
- **Evidence [wire]:** `plant_<warden_id>` only exists for the Heartwood Sapling (sound_hooks.gd:233, measured
  `plant_heartwood_sapling` only); everything else falls back to `plant`. **[recipe]** `_make_warden_place()`
  (sound_generator.gd:~3390): thump 110 Hz + soil scrape + `_sprout_unfurl` (band-pass noise gliding 350→1100 Hz) +
  a Karplus-Strong harp pluck on A or D, all lowpassed at 2.2 kHz. **[doc]** "Building and the map": "Plant a Warden
  | earth rumble + wood creak as the roots rise" — the recipe has neither a rumble nor a creak.
- **Fix (new specs, house language):**
  - `plant_sprout`: small and quick (~0.5 s): a soft **stone tock** of the waystone (300–600 Hz, 5 ms fade-in) + a tiny
    leafy breath settling *down* (no upward glide) + a light low thump. No harp: it's the most-placed thing in the game.
  - `plant_thornwall` (line `wall`): no spirit at all: a short **bramble push**: low root creak (`_creak`, under 700 Hz)
    + a dry woody knock + a soil settle, darker and shorter than a Warden (~0.4 s). Must not sound like a reward.
  - Family Wardens planted directly (`plant_<line>` fallback before `plant`): the stone tock + that family's material
    (reuse `_material(line, 0.6)`), ending in one soft in-key harp note (the "spirit answering") — this is where the
    note belongs, on the rarer, more valuable placement.
  - Hook: `plant_<warden_id>` → `plant_<line>` → `plant`.

### 3. A drag stroke of N Wardens sounds like one Warden
- **Evidence [wire]:** `plant_stroke()` (tower_placer.gd:2524) builds every green cell in one loop, one frame;
  each emits `tower_built`. `Sound.play` refuses a second start of the same id within `MIN_INTERVAL_MS` 45 ms
  (sound.gd:15, :162). So a 6-Thornwall stroke = one plant sound at the first cell. Same for **group grow**
  (`TowerSeller.grow_group`, tower_seller.gd:480: all evolve in one frame, the visual blooms stagger by
  `BLOOM_STAGGER` 0.06 s; the evolve hook has no stagger, so one evolve sound for ten Wardens). Nurture already
  does this right (`_on_nurtured` staggers with `BLOOM_STAGGER`, sound_hooks.gd:708).
- **Fix:** give plant and evolve the nurture treatment: count same-frame events, stagger each by the visual's
  stagger (strokes: ~0.05–0.08 s along the drag order), each -1 dB, cap ~6 audible, so a stroke reads as a quick
  rolling "tock-tock-tock" running along the line.

### 4. "Can't place here" and "can't afford it" are the same sound (and so are four other refusals)
- **Evidence [wire]:** `build_rejected` → `invalid` (:236), `RunState.dew_short` → `invalid` (:244),
  `dreamlight_short` → `invalid` (:246), Remember refusals → `invalid` (:1085). **[num]** `invalid` 0.33 s, peak -6,
  played at 0 dB on the UI bus (unpositioned) = as loud as planting. Two knocks 170/150 Hz **[recipe]** :355.
- **Why it matters:** the player can't tell by ear whether to move the cursor (blocked path / occupied cell) or wait
  for Dew. Also the clear tool's refusal (`ObstacleClearer.tool_refused`) and the Warden panel's `grow_refused`
  have **no sound** (unhooked), so some refusals knock and some are silent.
- **Fix:** keep `invalid` (muted wooden knock) for *where* (path rule, occupied, locked obstacle: hook
  `tool_refused` too), positional at the cell, -3 dB. New `short` for *not enough* (Dew or Dreamlight): a soft
  hollow **empty breath** (low airy exhale ~300 Hz, no knock, no coin), -6 dB, UI bus. One rule, two sounds.

### 5. Nurture (paid rank-ups) is ~12 dB under planting, and stone / water nurtures are sub-bass only
- **Evidence [num]:** `nurture_*` peak -9.1; hook `NURTURE_DB` -10 + 0.6×rank (sound_hooks.gd:69) ≈ -18.5 at rank
  I vs plant -6. `nurture_stone` centroid 203–213 Hz, rolloff max 215–280 Hz; `nurture_water` 262–275 / 345–366 Hz
  **[recipe]** `_rumble(0.5, 160)` / `_rumble(0.5, 250)` (sound_generator.gd:857–858). On laptop or phone speakers
  a Pebbling or Dewdrop rank-up costing 25–135 Dew makes **no audible sound**. `nurture_sprout` is the opposite:
  centroid ~1.3 kHz, rolloff max 8–9.7 kHz, the brightest nurture.
- **Fix:** `NURTURE_DB` -10 → -6 (still under evolve's -5.2 peak, still frequent-safe with the group stagger). Give
  stone a 400–900 Hz layer (a soft stone *tock* settle, like `_wood_knock` for the wooden lines) and water a
  mid "well" (a low plunk 300–600 Hz); darken sprout's air from 800 to ~500 Hz. Weight from body that small speakers
  can play, never brightness.

### 6. Selling is brighter and louder than planting, and "roots withdrawing" is a falling whoosh + pluck
- **Evidence [num]:** `sell` centroid 2225 Hz (the brightest build sound; plant ~1050, tend 825, move 676),
  rolloff max 6481, peak -5.2 at 0 dB (louder than plant's -6). **[recipe]** sound_generator.gd:350–353 is an
  old-style recipe: band-pass noise gliding 1500→250 Hz (a downward noise sweep, which the fourth listen tied to
  weather) + a KS pluck on G3. **[doc]** "Sell | roots withdrawing into the ground".
- **Fix:** sell = the plant read backwards and smaller: a short root creak pulling down (`_creak`, <700 Hz), a soil
  scrape, a low settle thump, no pluck, ~0.6 s, peak ~-9. Same sound for 100% and 50% refunds is fine (the panel
  says it). The drift-time "press again to confirm" first press is silent: add a soft `invalid`-family knock or a
  single creak as the "armed" cue (check: TowerSeller's confirm path has no signal hooked).

### 7. The placement harp note and the evolve strum are pitch-jittered out of key
- **Evidence [wire]:** `sound.play(&"plant", pos)` and `sound.play(bloom, pos)` (:234, :634) use the default
  `PITCH_JITTER` 0.05 (sound.gd:17) = up to ±0.85 semitone. **[recipe]** plant's pluck is A3/D4; `_grow_bloom`
  strums D-A-D (sound_generator.gd:~3410). The comment on `play()` itself says jitter must be off "for sounds that
  must stay in key"; rest, dispel, final bloom and Remember all pass 0.0. A slightly sour harp note over the D-minor
  rest piece, every placement, is exactly the kind of thing that "doesn't sound right" without the player knowing why.
- **Fix:** pass jitter 0.0 for plant (any variant with a note), evolve*, sell (pluck) until its pluck is removed;
  get variety from the three variants instead.

### 8. Rest starts with the brightest economy sound in the game (the Dew lump sum)
- **Evidence [num]:** `dew` centroid **2711 Hz**, rolloff max 5771, plays at every rest with a bonus (practically
  every rest) right on top of `rest` (centroid 1252, rolloff 6266; old recipe: noise gliding 1200→300 Hz + a harp
  strum, sound_generator.gd:447). **[doc]** Dew lump sums: "a soft, low rustle of light, never a tinkle"; the house
  rules ban leaf rustles. **[recipe]** :330 is band-pass noise gliding 350→800 Hz, yet it measures as the brightest
  UI-moment sound (check: the noise source's top end survives the band-pass).
- **Why it matters:** the rest should be the exhale (pillar 2). The two together put a bright airy sweep exactly where
  the music relaxes; by ear, "rest" and "Dew" blur into one shimmer.
- **Fix:** `dew` → a low warm glow swell (reuse `dreamlight_glow`'s family: tuned air on D/A under 1.5 kHz, ~-10),
  delayed ~0.6 s after `rest` so the two read as "the night is over" then "you were paid". Rebuild `rest` in the
  `_ws` style with no downward noise sweep (a breath out under 600 Hz + the strum, jitter 0).

### 9. Most nightmares arrive silently: 11 signatures for ~36 kinds
- **Evidence [wire]:** `SIGNATURES` (sound_hooks.gd:12) maps 11 EnemyData files. `resource/enemy/` also holds
  ash_crawler, barrow_king, barrow_wight, crow, dream_thief, drowned_one, gravecrawler, huntsman, lamplighter,
  moth_queen, mourning_mother, night_mare, scarecrow, shellbound, watcher, weeper, whisper_swarm, will_o_wisp
  (and spiderling / puffcaplet / duckling children). None plays anything on entering. Elites only get a pitched-down
  signature when their kind has one. **[doc]** pillar 3: "Each nightmare type has a signature sound, so players can
  *hear* … coming".
- **Fix:** add signatures in priority order: the act 2 bosses and pool bosses (Moth Queen, Night Mare, Scarecrow,
  Huntsman, Lamplighter, Barrow King, Mourning Mother: a boss with no entry sound is a missed moment), then the
  kinds that change the plan (flyers / wall-crossers, Dream Thief, Will-o'-wisp), then the rest. Until then, a
  shared cold "a nightmare is here" breath per act for unmapped kinds is better than silence.

### 10. The Calling evolution, the Waymark and several "for Sound" signals are unhooked
- **Evidence [wire]:** `DreamState.calling_grew` (dream_state.gd:631) has no listener; the Calling pick at drifts 5 /
  25 / 50 / 75 is "never taken as a card", so `card_taken`'s `dream_take_N` doesn't fire: the run's class choice gets
  only a button click. `Enemy.waymark_reached` / `MapGenerator.waymark_moved` (a Legendary!) are silent (doc says not
  done). `Tower.exposed_struck` ("the spark, for Sound too", tower.gd:24), `Tower.legacy_released`,
  `Tower.signature_fired` (only the first-ever discovery chime plays), `DreamState.card_fired` /
  `class_kit.credit` (the Calling's "credits itself" moments) all unhooked.
- **Fix:** `calling_grew` → `dream_take_1` (the Rare hummed choir) + that family's `nurture_<line>` material at
  -4, UI bus. Waymark placed: a heavy stone set into earth (low stone thud + settle); reached: one soft cold-to-warm
  shed (the dispel's gathering, shortened, -14, throttled 0.5 s). `exposed_struck`: fold into the crit layer
  (a soft low bell, already the Exposed-crit language) rather than a new sound.

---

## 2. Every other finding

| Where | Problem | Evidence | Fix |
|---|---|---|---|
| Choosing a Warden (bar) | Click = generic `ui_click` (-14.5 eff.); hotkeys 1–9 and `select_tower()` are silent; no sound distinguishes "Sprout in hand" from "wall in hand" | [wire] sound.gd:544 clicks BaseButtons only; `build_mode_changed` unhooked | A soft pick-up tock on `build_mode_changed(true)` / tower choice (same for click and hotkey), pitched by family weight; silence on cancel is fine |
| `ui_click` | 0 ms attack, rolloff max 6955 Hz on the most-heard UI sound | [num] ui_click attack_ms 0, rolloff 6955; [recipe] `_knock(420, 0.012)` | 3–5 ms fade-in, lowpass ~2 kHz (house rule: soft onsets) |
| Plant recipe | `_sprout_unfurl` is a rising noise glide 350→1100 Hz: reads as a "power-up whoosh", the rising-sweep shape the third listen banned | [recipe] `_sprout_unfurl`; [num] plant centroid ~1050, the 110 Hz thump inaudible on small speakers | Unfurl that settles (a short rise then a fall, or a fixed band ~500 Hz) and a 300–600 Hz stone tock so the body survives laptops/phones |
| Plant vs path shift | Every placement also triggers `path_shimmer` (-22 eff.); fine, but on a stroke the route updates once (hold_route), so the "earth shift" is the one sound that does match a stroke | [wire] :1222, tower_placer.gd:2530 | Keep; consider playing it ~0.3 s after the last stroke tock |
| Selecting a placed Warden | Silent (TowerSeller `tower_selected` / `selection_changed` unhooked) | [wire] grep: 0 hooks | Optional: a very soft woody tap on selection (touch players need confirmation without hover) |
| Clear tool | `tool_changed` silent; `clear_pending` (touch: first tap arms) silent; `tool_refused` silent | [wire] obstacle_clearer.gd:14–20, 0 hooks | tool on/off: a soft tock; refused: `invalid` |
| `tend` | rolloff max 5405 Hz (creak top) and -4.4 peak: clearing a tree is louder than planting a Warden | [num] tend peak -4.4, plant -6 | Hook at -3 dB, lowpass the creak ~2.5 kHz |
| `move` | Louder than plant (-4.4) | [num] | Hook -2 dB |
| Evolve | Hook 0 dB, peak arrives ~1.0–1.2 s after the click (attack_ms 720–1184) — matches the 0.8 s fireflies bloom, but there's no immediate confirmation at the click | [num] evolve_* attack_ms; [wire] :634 | Fine if the first 100 ms already carries the unfurl (check); otherwise a small tock at 0 |
| Evolve sprout | `evolve_sprout` brightest of the evolves (centroid 1134) | [num] | Darken as nurture_sprout (finding 5) |
| Nurture pitch | Each rank plays ~1 semitone **lower**; by ear a rank-up sequence goes "down", which can read as worse (good vs bad by ear) | [wire] :718 `pow(2, -(rank-1)/12)`; [doc] asks for it | Keep the spec, but add body (+0.6 dB/rank is small): add the settle thump's level per rank so lower clearly = bigger |
| Focus leans | `focus_power` / `focus_deep` rolloff max ~5 kHz, attack 23 ms on power | [num] | Lowpass 1.5 kHz |
| Heartwood Sapling plant | Good and big (peak -3.1, centroid 177) but sub-heavy: on phones the biggest placement in the game is quieter than a Sprout's | [num] | Add a 300–800 Hz wooden layer |
| Gift pieces | Use the generic `plant` (positional, so paused-silent too) | [wire] :1302 | Own `place_gift`: a stone tock + low hum; play while paused |
| Softer nightmares | Muffles and lowers `dispel` / `dispel_boss` (the player's *success* sound) and `drift_start` (the player's own Start press), but not `trample` (+2 dB, 0 ms attack, 8 dB duck: the biggest startle), `leaf_lost` (saw groan), `split` (0 ms, rolloff 5.8 kHz), `close_call`, `boss_reveal`, Reactions | [wire] sound.gd:42 `SOFTER_IDS`; [num] trample attack 0, split attack 0 | Remove dispel / drift_start from SOFTER_IDS; add trample, split, leaf_lost (−4 only, keep it readable), boss signatures, hound_howl already in |
| Trample | Instant onset (attack 0 ms), +2 dB hook, 8 dB duck: a jump-scare shape | [num] trample attack_ms 0; [wire] :225 | 10 ms fade-in; it's a warning, keep it heavy, not sudden |
| Low leaves | The ≤5-leaf warning is only the music `heartbeat` layer: a player who turns Music down (default 55%) or off loses it; visual tint exists | [wire] :448; [doc] Accessibility | Also a quiet SFX cue once when leaves first drop to ≤5 (a single low heartbeat thump, -8) |
| Dread2 / last stretch | Same: "nightmares in the last third" is music-only; `close_call` (SFX, -16 eff.) carries it for players without music — good | [wire] | Keep close_call; consider -12 |
| Boss half health | Only the music's `warm` layer changes; no SFX for the 50% ability / phase (DriftBanner has a marker) | [wire] :425 | A short cold swell at 50% on the boss (per-boss abilities that exist keep theirs) |
| Elite spawn | Pitched-down signature only (0.8); no "low haze drone" from the spec; silent for unmapped kinds | [wire] :523; [doc] Nightmares table | Add the drone layer or a shared `elite_arrive` |
| Leaf lost vs boss drain | Same file every 2 s while a boss drains, only pitch 0.8: repetitive but readable | [wire] :216 | Fine; consider alternating two variants |
| Dream offered | `dream_open` rolloff max 6158, centroid 1615: a music-box bell shimmer (6 bells) on every Dream offer — shimmer is allowed by the doc but this is the brightest choice-screen sound | [num]; [recipe] :424–428 | Lower the bells an octave |
| Legendary offered/taken | Stand-ins (flip_3 pitched + `ascend_great_bell`); `dream_take_2` may double with `card_taken` | [wire] :1259–1265 | Own Legendary sound (doc: a full choir chord); confirm the two take sounds can't stack |
| Dream pulses | Positional on Wardens while the Dream screen pauses → frozen until it closes (finding 1) | [wire] :1278 | Play flat with pan |
| `dew_catch` | rolloff max ~13.7 kHz, attack 0 ms: a tiny tick | [num] | Lowpass, fade-in (it's -16, so minor) |
| `harvest` | rolloff max 11.5 kHz | [num] | Lowpass 3 kHz |
| `hit_sprout` | The most-heard hit in the game: attack 0 ms, rolloff max 11.8–13.4 kHz, peak -3.1 | [num] | 3–5 ms fade-in, lowpass (other seats will own the detail) |
| `win` / `loss` | rolloff max ~12–13 kHz | [num] | Lowpass ~6 kHz; both otherwise fine |
| `sig_phantom` / `sig_mourner` | Brightest signatures (centroid 2118 / 1617, rolloff 10.3k / 6.3k) | [num] | Darken; Phantom's is a warning, keep its shape |
| `reaction_shatter`, `reaction_pinned`, `crowned_prismstorm`, `crowned_wide_awake`, `crown_swell` | rolloff max 8–15 kHz (glassy risk) | [num] | Lowpass; Shatter's doc says "no glassy tinkle" |
| Status completions | Only Exposed, Drowsy, Rooted have cues (by design); at -14 + file -9.1 ≈ -23, they're near-inaudible in a busy drift | [wire] :139, STATUS_DB | -10, keep the 0.3 s throttle |
| Lessons / whispers | Lesson cards and Heartwood whispers appear silently (only the first chain whisper has a sound) | [wire] :296 | A soft breath-in when a whisper/lesson appears (no voice) |
| Mono | The doc promises a mono option; Settings has Volume / Music / Sounds / Softer nightmares only | [doc] Accessibility; [wire] settings_panel.gd:143–146 | Add "Mono" (phones, one-ear players: positional pan carries plant/hit location) |
| Sliders | No preview sound while dragging Sounds / Music (check) | [wire] settings_panel.gd:659 | Play `ui_click` / a short music swell on release |

---

## 3. Missing sounds (no sound, or a stand-in)

- **Calling evolution chosen** (`calling_grew`): button click only.
- **Waymark** placed / moved (`waymark_moved`), nightmare shedding its statuses at the stone (`waymark_reached`).
- **Thornwall placement** of its own; **Sprout placement** of its own; family `plant_<line>`.
- **Drag stroke** and **group grow**: one sound for many (throttle).
- **Dew short** vs **wrong place**: no difference.
- **Clear tool** on / off / refused / touch-armed; **grow refused** (`grow_refused`); **sell armed** (drift confirm).
- **Choosing a Warden by hotkey**; entering build mode.
- **Selecting a placed Warden** (touch confirmation).
- **Nightmare signatures** for ~18 kinds including every act 2+ pool boss.
- **Boss at 50%** (SFX side).
- **Exposed strike** (`Tower.exposed_struck`), **Ascended legacy attack** (`legacy_released`), **rank V signature
  firing in play** (`signature_fired`; only the first-ever discovery chime), **Calling / card credits**
  (`card_fired`).
- **Legendary Dream**: stand-ins (doc: own choir chord).
- **Lessons / whispers** appearing.
- **Sleepwalk bump**, **Fairy ring trigger** (doc: not built, no event).

## 4. The 25 events a player most needs to hear

| # | Event | Sound now | Verdict |
|---|---|---|---|
| 1 | Pick a Warden to build | generic ui_click (hotkey: none) | weak |
| 2 | Plant a Sprout | shared `plant` (silent if paused) | weak |
| 3 | Plant a Thornwall | shared `plant` with a harp note | weak |
| 4 | Drag-plant a line | one `plant` for N | weak |
| 5 | Can't place here | `invalid` | good (but shared) |
| 6 | Can't afford | `invalid` | weak (same as 5) |
| 7 | Grow a Sprout into a family | `evolve_<line>` (one for a group; jittered) | good / weak in groups |
| 8 | Nurture a rank | `nurture_<line>` at ≈-18.5 | weak (stone/water inaudible on small speakers) |
| 9 | Sell | `sell` (bright, louder than plant) | weak |
| 10 | Clear an obstacle | `tend` / `move` | good (a bit loud) |
| 11 | The route changes | `path_shimmer` (earth shift) | good |
| 12 | Start a drift | `drift_start` + the gathering | good |
| 13 | A new kind of nightmare arrives | 11 signatures of ~36 | weak |
| 14 | A boss arrives | `boss_reveal` + signature + duck (mapped bosses only) | good / missing for pool bosses |
| 15 | A nightmare nears the Heartwood | `close_call` + dread2 | good |
| 16 | A leaf is lost | `leaf_lost` + 8 dB duck | good |
| 17 | Low leaves | music heartbeat only | weak (music-bus only) |
| 18 | A nightmare dispelled | `dispel` (approved) | good |
| 19 | A Reaction | 10/10 own sounds | good |
| 20 | A chain / Dawnburst | swell / surge / dawnburst + stinger | good |
| 21 | A Crowned Reaction | crown swell + 10/10 signatures | good |
| 22 | A status completes | 3 cues at ≈-23 | weak (too quiet in a drift) |
| 23 | A rest starts | `rest` + bright `dew` | weak |
| 24 | A Dream is offered / taken | `dream_open`, flips, takes; Calling pick missing | good / missing |
| 25 | Run won / lost | `win` / `loss` | good |

Count: 12 good, 11 weak, 2 partly missing (14, 24) — plus the unhooked signals in section 3.

## 5. What already works (keep)

- The **dispel** (approved): tuned air D/F♯/A, cluster blending, no duck, Deeply Blighted / boss variants.
- The **Firefly Jar** (approved) and the warm-bloom light material reused in `_light_glow`.
- **Leaf lost** with the 8 dB duck: the loudest, clearest bad news; boss drain as its heavier cousin.
- **Nurture's group stagger** (the model for plant and evolve), the Focus leans.
- **Reactions / Crowned / chains**: every one of the 10 + 10 has its own sound, one per event, sized by count,
  throttled; chain swell builds by body, never pitch; Dawnburst gets the duck + stinger.
- **Close calls** (SFX-side tension that survives a muted music slider), the **route earth shift** at 0.5 s throttle.
- The **drift gathering** on bar lines (the seventh pass fix for "starts abruptly").
- **No Dew sound per kill**; Dew only for lump sums.
- `invalid` as a muted wooden knock (keep it, for *where* only).
