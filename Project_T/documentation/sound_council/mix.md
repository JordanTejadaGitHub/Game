# Sound Council 2026-10-23: mix seat (levels, priority, masking, fatigue, phones)

Scope: every sfx and music stem, with the build phase looked at closely (the user: "placing a Warden / Sprout down
doesn't sound right"). Evidence is tagged [design] audio_direction.md, [recipe] tools/sound_generator.gd,
[numbers] sounds_measured.tsv, or [wiring] scripts/audio/sound.gd / sound_hooks.gd.

**How "in-game level" is worked out below:** hook dB + `_rate_db` (−7 dB per tenfold rate) + the file's measured
RMS (mean of its variants). Bus sliders: SFX/UI 1.0 = 0 dB; Music/Ambience default 0.55 = **−5.2 dB**
(HeartwoodMemory.gd:63, 597). Music in-game = MUSIC_DB −6 + act step + phase (−3 in drifts) + stem RMS − 5.2.
The layer trim and the 0.82–1.15 weight pitch are left out. Positional sounds also lose up to ~5 dB at the map
corners (AudioStreamPlayer2D, max_distance 2200, attenuation 1.0, sound.gd:172-175). These are rough figures for
comparing sounds with each other. They are not LUFS.

---

## 1. Top 10 findings, ranked

### 1. Build sounds go silent while the game is paused, then play late [wiring] (check in a playtest)
- **Where:** `Sound.play` with a position (sound.gd:171-177) adds an AudioStreamPlayer2D under the current scene
  "so it pauses with the game". Main (main.tscn:56) has no process_mode, so it can be paused. Building, selling,
  growing and nurturing all work while paused (CLAUDE.md: the tools are `process_mode = ALWAYS`). But `plant`, `sell`,
  `evolve_*`, `nurture_*`, `tend`, `move`, `place_*` and the evolve "first breath" are all positional
  (sound_hooks.gd:234, 238, 241, 634, 734, 793).
- **Evidence:** the hooks already know this for other sounds. Final Bloom is "Unpositioned: growing works while the
  game is paused" (sound_hooks.gd:740-741), and the harvest is unpositioned because "the Dream screen pauses the game
  (and the world's positional players)" (1045-1046). The plant was never given that treatment.
- **What the player hears:** they pause (Space), plant a row of Sprouts, and hear only the unpositioned
  `path_shimmer`, a −34 dB earth rumble. When they unpause, up to 4 queued plants go off together (MAX_VOICES) at the
  wrong moment. That alone would make "placing doesn't sound right".
- **Fix:** add `always := false` to `Sound.play`; when it is set, give the AudioStreamPlayer2D
  `process_mode = PROCESS_MODE_ALWAYS` (it keeps its panning). Use it for every build-phase sound: plant, plant_*,
  sell, invalid (already UI), tend, move, evolve_*, nurture_*, focus_*, place_*, first breath, final bloom.

### 2. Planting quickly gets quieter, then silent; a drag line of 10 sounds like 1 [wiring]
- **Where:** `plant_stroke()` (tower_placer.gd:2524-2536) plants every cell of a stroke in one frame, so
  `tower_built` fires N times in that frame. `Sound.play` refuses a start within MIN_INTERVAL_MS 45 of the last one
  (sound.gd:160), so **a 10-Sprout drag line makes one plant sound**.
- **Clicking fast:** `plant` is 1.12 s long [numbers]. Each voice already playing makes the next one CROWD_DB
  −2.5 dB quieter (sound.gd:185). So the 2nd, 3rd and 4th plants inside about a second are −2.5, −5 and −7.5 dB, and
  the 5th is dropped (MAX_VOICES 4, sound.gd:166). A rest's run of Sprouts gets weaker as you go, the opposite of
  satisfying.
- **Fix:** handle a stroke the way nurture handles a group: stagger the plants along the line (about 60-80 ms apart,
  −1 dB each, floor −6 dB, at most 6 sounds; sound_hooks.gd:708-728 already does this). For player-action ids
  (plant, sell, evolve, nurture, tend, move), steal the oldest voice instead of dropping the new one, and skip
  CROWD_DB. Cut `plant` to about 0.6 s: the tail is the harp note at 0.42 s plus its 0.7 s decay
  (sound_generator.gd:3390-3393).

### 3. The plant's harp note is knocked out of tune on every placement [wiring + recipe]
- **Where:** the hook calls `sound.play(own_plant or &"plant", tower.global_position)` with no jitter argument
  (sound_hooks.gd:234), so the default PITCH_JITTER 0.05 applies (sound.gd:17, 186). That moves the in-key pluck
  (A3 / D4 / A3, sound_generator.gd:3392) by up to ±5%, about ±0.85 semitone.
- **Why it matters:** the rest piece under it is in D on the same harp. A row of Sprouts plays a wobbling,
  out-of-tune harp against the score. Only two pitches exist across the three variants (57, 62, 57), so it also
  repeats.
- **Same problem elsewhere:**
  - `evolve_*` has a D-A-D harp strum plus a D/A hum and plays with default jitter (634).
  - `sell` has a G3 pluck with default jitter.
  - `place_white_stag` uses jitter 0.03 (566).
  - Nurture's pitch drops one semitone per rank (`pow(2, -(rank-1)/12)`, 717). The tonal materials, song (D/A hum)
    and light (tuned air on D/A/D), therefore land on C#, C, B and B♭ at ranks II-V. [design] asks for "−1
    semitone per rank", which is the source of the problem.
- **Fix:**
  - Pass jitter 0.0 for every tonal build sound, the same way the dispel does (sound.gd:217).
  - Get variety from the thump and soil layers instead, and render 4 variants on chord tones: D3, A3, D4, F4.
  - For nurture's tonal families, step down in key (D → A → F → D, one octave lower at most) instead of in
    semitones. Or keep the semitone steps only on the untuned families: stone, root, water, wind, wing, wall.

### 4. Build sounds have only 4-8 dB over the rest music, in the same band and on the same instrument [numbers + wiring]
- **Levels:**
  - plant in-game ≈ **−22.6** (0 dB hook, RMS −22.6), and about −27.5 at a map corner.
  - Rest music in-game: act 1 **−30.3**, act 3 **−26.8**, act 4 −28.4. MUSIC_DB −6, +1 dB per act, slider −5.2
    dB, and the rest phase has no −3 dB offset.
  - That gives 4-8 dB of headroom, against the [design] Mix rule "music about −10 dB under the SFX".
- **Masking:**
  - `mus_rest_act3_base` is the hottest and brightest rest piece (RMS −17.6, centroid 1271 Hz; the other rests are
    −19.1 to −20.4 RMS and 642-751 Hz).
  - The plant's centroid is 1023-1081 Hz. Its tonal part is a Karplus-Strong harp pluck, the score's own instrument,
    in the score's key and register.
  - At a rest, the plant blends into the music instead of answering the click.
- **Fix:**
  - Trim `mus_rest_act3_base` by about 2.5 dB to match the other rest pieces.
  - Give the plant its own voice: drop the harp pluck, or take it an octave lower under a short warm wooden tock at
    250-400 Hz. That keeps "earth rumble + wood creak as the roots rise" [design "Building and the map"], which never
    asked for a harp.
  - Optionally add a 2 dB / 0.3 s music duck on a plant while build mode is on, throttled the way path_shimmer is.

### 5. Refusals and selling are louder than planting [numbers + wiring]
- **invalid:**
  - It plays on the UI bus at 0 dB, unpositioned (sound_hooks.gd:236, 244, 246), so in-game it is **−21.0**.
  - That is louder than a successful plant (−22.6 at the centre, about −27.5 at the edges).
  - Its top also reaches higher (rolloff 4716 Hz, against the plant's 2196 Hz).
  - It also plays for every `dew_short`, so a player trying to plant with too little Dew hears the error louder than
    the planting.
- **sell:**
  - It plays at 0 dB, so in-game it is **−20.5**. It is the brightest build sound: centroid 2225 Hz, rolloff 6481 Hz.
  - The recipe (sound_generator.gd:350-353) is a low-Q bandpass noise glide from 1500 to 250 Hz, which is a hissy
    whoosh. That brushes against "no hiss" and against the [design] "roots withdrawing into the ground".
- **Fix:**
  - invalid: −6 dB (hook `sound.ui(&"invalid", -6.0)`).
  - sell: −4 dB, glide 600→150 Hz, plus `_creak` and a soft low `_thump` (roots pulling down). Aim for a centroid
    under about 900 Hz.

### 6. Priority inversion: the dispel is quieter than many Warden hits, in the same band [numbers + wiring + design]
- **The rule:** [design] Mix rules put dispel above Warden hits.
- **In-game levels:**
  - dispel −3 dB + RMS −22.4 = **−25.3**. It drops to −31.3 inside a cluster (sound.gd:216-217).
  - hit_light (Firefly Jar, falls back to the family hit) −22.8; hit_pebbling −21.4; hit_root −21.6; hit_rootling
    −20.1; hit_mossback −19.1; hit_boulderback −18.2; hit_old_mountain −17.5 (plus its Ascended duck).
- **Masking:**
  - The dispel's centroid is 1372-1435 Hz.
  - These frequent hits sit right on top of it: hit_spore 1206, hit_sporeling 1351-1417, hit_water 1463-1498,
    hit_dewdrop 1658-1687, hit_frostfern 1468-1493, hit_rain_lily 1652-1686, hit_driftspore 1322-1400.
  - The second-listen ruling asked hits for "a rounded 300–900 Hz tock". The water-line hits miss that by 600-800 Hz.
- **Fix:**
  - Dispel hook −3 → 0 dB, keeping the cluster steps.
  - Re-voice the water and spore hit bodies down into 400-900 Hz so the 1.2-1.6 kHz band of tuned air belongs to the
    dispel (and the approved dispel itself is not touched).

### 7. The four starting families' hits are 10 dB apart [numbers]
- **In-game basic hits:** Firefly Jar (hit_light) −22.8 · Bellflower −26.3 · Sporeling −27.3 · **Dewdrop −32.7**.
- **Why Dewdrop is low:** hit_dewdrop has peak −6.0 and RMS −28 to −29.7, a crest factor of about 23 dB. That is a
  tick with almost no body, and it breaks "Warm, not weak". hit_rain_lily (crest about 22.5) and hit_frostfern (about
  21) share the same shape. A Dewdrop run sounds feeble next to a Firefly run.
- **Fix:** give hit_dewdrop / rain_lily / frostfern a body layer (a low water "plunk" `_wobble(_rumble(…))` at about
  300-500 Hz) and soften the transient. Aim for in-game RMS within ±2 dB of about −25 for all four starters.

### 8. Phones: the low-leaves heartbeat and several key sounds disappear below 150 Hz [numbers]
- **Lost entirely or nearly:**
  - `mus_act*_heartbeat`: centroid **70-71 Hz**. This is the low-leaves warning ([design] "Low leaves (≤5) → the
    heartbeat layer").
  - hit_rootling: 144-160 Hz, so the Rootling falls silent.
  - hit_boulderback 130-155, hit_full 191, crit_punch 172, focus_deep 144, family_bell 182, crowned_tempest 169,
    crowned_avalanche 179, plant_heartwood_sapling 177.
  - nurture_stone: centroid 203-213 Hz, **rolloff 215-280 Hz**, so it is nothing on a phone.
  - nurture_water: rolloff 345-366 Hz.
- **Thinned to a ghost:** dread1 stems (213-223 Hz) and boss bass/drums (177-293 Hz).
- **The plant:** its "press into the earth" is a 110-134 Hz thump. On a phone only the leafy rise and the harp are
  left.
- **Fix:** keep the weight, but add a harmonic the small speaker can carry:
  - the heartbeat: a felt-skin knock at 220-350 Hz on each beat;
  - Rootling and Boulderback: a wooden or stone tock at 250-450 Hz;
  - nurture_stone / water: a pebble settle or water well at 300-600 Hz;
  - the plant: a damp soil knock at about 250 Hz.
  - Check on a phone build. Every visual cue already exists ([design] Accessibility), so the heartbeat matters most.

### 9. Some boss music stems are 6-15 dB hotter or quieter than their siblings, and the layer trim cannot see it [numbers + wiring]
- **Where:** the layer trim (sound.gd:131-134) uses nominal gains (LAYER_GAIN, SIG_GAIN 0.5), not the stems' real
  loudness.
- **Too hot:** `mus_boss_act2_sig_lamplighter_2/3/4` have RMS **−13.0 / −12.5 / −12.4**. The other signature stems
  sit at −19 to −27 (lamplighter base −19.6). Each lantern lit pushes the whole fight up about 3 dB.
- **Wide swing:** `mus_boss_act4_sig_hollow_oak_withering` is −14.8, while `sig_hollow_oak` is **−29.9**.
  - That is a 15 dB swing inside the final boss.
  - With SIG_GAIN 0.5 the Hollow Oak's own signature lands at about −42 in-game. The final boss's voice is close to
    inaudible.
- **Also odd:** `mus_act4_dread2` is −19.3 against act 1's −26.9. Act 4 dread is 7.6 dB hotter before the +3 dB act
  step.
- **Fix:** have `_music()` normalise stems by RMS per role (theme / base ≈ −19, signature ≈ −22, dread ≈ −23) instead
  of by peak. Or add a per-stem trim table in Sound beside LAYER_GAIN. Then re-check the "+1 dB per act" growth by
  ear.

### 10. Clicks on the most frequent hits: the top end leaks past the 4.5 kHz lowpass [numbers + recipe]
- **Where:** `_sfx` lowpasses once with a 2-pole filter (Q 0.7) at SFX_TOP_HZ 4500, and hits fade in over only
  HIT_ONSET 4 ms (sound_generator.gd:18-19, 274-279).
- **Evidence (rolloff_max with attack 0 ms):**
  - hit_sprout 11.8-13.4 kHz (the most-built Warden, 1 hit per second each)
  - hit_spore 11.3-11.8k, hit_stone 11.3-11.5k
  - attack_water 13.9-14.2k
  - hit_nestling_02/03 11.5-12.0k, hit_lanternmoth 7.5-12.0k, hit_magpie_perch 13.0k
  - hit_chime_stone 12.6-13.9k, hit_dreamcatcher 7-8.4k
  - dew_catch 13.7-13.9k
  - reaction_shatter 14.1-14.9k
- **For comparison:** the approved dispel stays at about 3.1 kHz.
- **Why it matters:** in a 30-Sprout maze, hit_sprout alone tries about 30 starts a second. MAX_VOICES caps it at 4,
  but every start carries the tick, and that is the "pixel murmur" from the third listen coming back.
- **Fix:** HIT_ONSET 4 → 8 ms; run the 4500 Hz lowpass twice (24 dB/oct) in `_sfx` and `_wloop`; re-render, then
  check that every SFX rolloff_max is under about 6 kHz.

---

## 2. Every other finding

| Where | Problem | Evidence | Fix |
|---|---|---|---|
| sound.gd:41 SOFTER_IDS | "Softer nightmares" also cuts the **dispel** and boss dispel by 8 dB and muffles them. The dispel is the warm release and the game's main feedback, not a shriek | [wiring] | Drop `dispel`, `dispel_boss` from SOFTER_IDS; keep shrieks, sigs, drift_start |
| The rest moment | rest_started stacks rest (centroid 1252, rolloff 6266) + dew (**centroid 2711, the brightest SFX in the game**) + harvest (rolloff 11.6k) + dream_open (1615 / 6158) within about 1 s: the brightest cluster in the game, on the currency sounds ("nothing like coins") | [numbers] sound_hooks.gd:254-262, 1052, 274 | dew: lowpass to ~1 kHz (its low-Q bandpass lets HF through; the measured centroid contradicts "soft, low rustle"); stagger dew 0.6 s after rest; harvest lowpass |
| `_filter(noise, f, 0.5, "bp")` pattern | Low-Q 2-pole bandpasses on white noise leave most of the top up to 4.5 kHz: dew 2711, sell 2225, dream_open 1615, attack_autumn_gale / samara ~3200 | [recipe] [numbers] | Follow every noise bandpass with `_lowpass(…, 2×f)` |
| Group evolve | `grow_group` blooms: 4 overlapping 2 s evolves at 0/−2.5/−5/−7.5 dB with default jitter = a chorus of detuned harps (+3 dB over one); no group step like nurture's | sound_hooks.gd:632-638 | Reuse the nurture group stagger/step for evolve; jitter 0 |
| Boss drain | duck 4 dB / 0.6 s every 2 s (plus 0.25 s release) = music pumping about 40% of the time while a boss drains | sound_hooks.gd:217-219, sound.gd:44-45 | Duck once at the first drain, then 1.5 dB |
| SFX bus limiter (sound.gd:513-516) | leaf_lost, dispel_boss and trample share the SFX bus with every hit, so in a dense act 4 field the limiter pulls the top-priority sounds down with the hits | [wiring] (check) | Route leaf_lost / boss / trample to a "Priority" bus that sends to Master past the SFX limiter, or duck SFX hits 3 dB under leaf_lost |
| Loops (`_wloop`, sound_generator.gd:1022-1031) | 4 s loops with a **linear** crossfade of uncorrelated noise dip about 3 dB at the seam, so the breath beds pulse every 4 s. The filter runs after the fold, so the state jumps at the seam | [recipe] (check by ear) | Equal-power crossfade; filter before folding; LOOP_LEN 8 s for the breath beds |
| Loops (sound.gd:431-442) | Unpositioned: a Sunpetal off-screen plays at full loop level. 8+ can stack in act 4 (presence ×N Ascended, beams, Lit, spin, fog, smother, 5 ground loops) at −14 dB + RMS −20…−28, which sums to about −27, level with a hit | [wiring] [numbers] | Cap the loop sum (scale LOOP_DB by −1.5 dB per extra loop) or make loops positional |
| Loops' RMS spread | loop_fairy_ring −20.9, loop_still_pool −20.3, loop_sunpetal −20.6 vs loop_grandmother_oak −27.8, loop_scree −26.5: 7 dB apart, all at the same LOOP_DB | [numbers] | Normalise loops by RMS (≈ −23) |
| Signatures (sound_hooks.gd:12-17) | 1 variant each, replayed every 2.5 s per type; sig_stag (boss, +2 dB) is −15.2 in-game, sig_shade −29.9: 15 dB apart | [numbers] | 2 variants each; level them within ±3 dB (bosses +3) |
| One-variant frequent ids | sell, invalid, path_shimmer, tend, move, split, crit, crit_punch, leaf_lost, ui_click: fatiguing at a rest of 20+ actions | [numbers] variant count: 155 ids have one variant | 3 variants for invalid, tend, move, sell, path_shimmer, crit |
| crit + crit_punch | Every crit plays both (−6 / −4 dB). crit_punch at 172 Hz is −23.4 in-game, louder than the hit it rides on for many Wardens. Crit-heavy builds (Starlit Aim) make a thumping bed | sound_hooks.gd:646-647 | crit_punch −8 dB, throttle 120 ms |
| hit_full, `*_dull` | Never play: `weak` / `resisted` are hard-coded false (sound_hooks.gd:938-939). Dead assets | [wiring] | Remove them, or wire them to the defence system |
| path_shimmer | Plays on every path change, also at drift time (walkers re-routing) and on sell; it is fine and quiet (−34.4), but inaudible on phones (rumble 200 Hz + scrape 300 Hz) | [numbers] | Keep; it is the right level |
| ui_click on the Warden bar | Selecting a Sprout clicks (−30.5) but hotkeys 1-9 are silent: two ways into build mode sound different | [wiring] sound.gd:541-548 | A soft "pick up" for the selected Warden on the hotkey too (or none for both) |
| Ambience | Only `amb_act1` exists and the hook hard-codes it (sound_hooks.gd:316); [design] wants a bed per act. Its level is right (≈ −42.7 at rests) | [numbers] [design] | Per-act beds; `play_ambience(&"act%d")` on act_started |
| Music act step vs SFX | Music grows +1 dB per act and the SFX don't, so act 4 drift music is ≈ −30.4 against a dispel of −25.3: 5 dB, half the [design] 10 dB | [wiring] sound.gd:37, 409 | Grow the SFX bus +0.5 dB per act, or cap ACT_DB_STEP at 0.5 for drift sets |
| Data | Rows for mus_boss_act2_bass, sig_great_toad, sig_lamplighter_3, sig_echo_lamplighter have their columns shifted (no seconds value) | sounds_measured.tsv | Re-measure; these were read with that in mind |
| Nurture group | Fine for 10 Wardens, but the nurture swell keeps default MAX_VOICES / CROWD on top of its own −1 dB step, so the 5th onward within 0.7 s is dropped | sound_hooks.gd:718 | Voice-steal for nurture |
| Leaf lost | −17 in-game with an 8 dB duck: correctly the loudest. Keep | [numbers] | — |

## 3. Missing sounds (events with no sound or a stand-in)

- **Nightmare entry signatures for acts 3-4:** ash_crawler, barrow_wight, dream_thief, drowned_one, gravecrawler,
  shellbound, watcher, weeper, whisper_swarm, will_o_wisp (SIGNATURES lists only 11 act 1-2 ids). The late field is
  Warden hits only.
- **Signals made "for Sound" with no connection in sound_hooks.gd:** `Tower.exposed_struck`,
  `Tower.legacy_released`, `Tower.signature_fired` (only the first-ever discovery chime is hooked),
  `ReactionTracker.crowned_fired` (late crowns may be silent if they don't also come through reaction_fired; check),
  `waymark_reached` / `waymark_moved` (Waymark has no sound), `DreamState.calling_grew`, `card_fired`, and
  `sapling_planted` (plays the generic plant unless `plant_heartwood_sapling` resolves; it does via `plant_<id>`).
- **Build ghost:** nothing for entering build mode by hotkey, a drag line growing, or a stroke cell refused. Keep the
  ghost moving silently, but a stroke that partly fails should give a soft knock for the refused cells.
- **Legendary offer / take:** stand-ins (flip_3 pitched plus great_bell, sound_hooks.gd:1257-1265).
- **Lost-leaf vs boss bite:** act 1-3 boss bites (10-12 leaves at once) use the same leaf_lost sound as a single leak.

## 4. Level table: the 20 most frequent sounds (rough in-game dB)

| # | id | hook dB | rate dB | RMS | ≈ in-game | centroid Hz | variants | Notes |
|---|---|---|---|---|---|---|---|---|
| 1 | hit_sprout | −3 | 0 | −23.5 | **−26.5** | 929-1254 | 3 | rolloff 12-13k (finding 10) |
| 2 | attack_sprout | −15 | 0 | −24.7 | −39.7 | 1295-1388 | 3 | fine |
| 3 | hit_sporeling | −3 | −2.1 | −22.2 | −27.3 | 1351-1417 | 3 | in the dispel's band |
| 4 | hit_light (Firefly Jar) | −3 | −1.2 | −18.6 | **−22.8** | 697-740 | 3 | loudest starter |
| 5 | hit_dewdrop | −3 | −0.6 | −29.1 | **−32.7** | 1658-1687 | 3 | weakest starter (finding 7) |
| 6 | hit_bellflower | −3 | 0 | −23.3 | −26.3 | 258-400 | 4 | 2 s rings |
| 7 | hit_pebbling | −3 | +0.9 | −19.3 | −21.4 | 340-445 | 3 | above the dispel |
| 8 | dispel | −3 | — | −22.4 | **−25.3** (→ −31.3 clustered) | 1372-1435 | 4 | under many hits (finding 6) |
| 9 | plant | 0 | — | −22.6 | **−22.6** (≈ −27.5 at the edges) | 1023-1081 | 3 | finding 1-4 |
| 10 | path_shimmer | −10 | — | −24.4 | −34.4 | 289 | 1 | right |
| 11 | invalid (UI) | 0 | — | −21.0 | **−21.0** | 479 | 1 | louder than a plant (finding 5) |
| 12 | sell | 0 | — | −20.5 | **−20.5** | 2225 | 1 | bright, loud |
| 13 | nurture_sprout (rank I) | −9.4 | — | −26.1 | −35.5 | 1295-1339 | 2 | rolloff 8-10k |
| 14 | ui_click (UI) | −4 | — | −26.5 | −30.5 | 911 | 1 | fine |
| 15 | status_exposed/drowsy/rooted | −14 | — | −20.2…−24.5 | −34…−38.5 | 400-770 | 2 | fine |
| 16 | bolt_strike | −10 | — | −26.3 | −36.3 | 884-942 | 3 | rolloff 7-8k |
| 17 | crit + crit_punch | −6 / −4 | — | −24.6 / −19.4 | −30.6 / **−23.4** | 327 / 172 | 1 / 1 | punch too loud, phone-silent |
| 18 | reaction_* (1 caught) | −3.5 | — | −16.5…−27 | ≈ −20…−24 | 330-830 | 2 | intended above the hits |
| 19 | chain_swell (2 links) | −9 | — | −20.1 | −29.1 (→ −21.9 at 8) | 622-646 | 2 | fine |
| 20 | close_call | −8 | — | −22.0 | −30.0 | 295-304 | 2 | fine |
| — | leaf_lost | 0 | — | −17.0 | **−17.0** + 8 dB duck | 592 | 1 | top, correct |
| — | Music, rest act 1 / 3 / 4 | −6 + act − 5.2 | — | −19.1 / −17.6 / −20.2 | −30.3 / **−26.8** / −28.4 | 751 / 1271 / 642 | — | act 3 hot |
| — | Music, drift base act 1 / 4 | −9 + act − 5.2 | — | −18.9 / −19.2 | −33.1 / −30.4 | 791 / 511 | — | 5-8 dB under the dispel |
| — | Ambience at rests | −16 + 3 − 5.2 | — | −24.5 | −42.7 | 495 | — | right |

## 5. What already works (keep)

- **The dispel** (approved): stays in tune (jitter 0), a cluster gets softer and never higher, no duck on normal
  dispels. It only needs more level (finding 6), not a new recipe.
- **`_rate_db` loudness × rate:** fast Wardens get quieter per shot. Launches at −15 dB land −38 to −41 in-game, well
  under the hits, as the doc asks.
- **The music engine:** the energy trim (adding layers never gets louder), every change on a bar line, the gathering
  one-shot, the drift −3 dB phase offset, the muffle on choice screens, real-time mixing at any game speed, and no
  pitch shift at 2×/3×.
- **Nurture group stagger** with −1 dB per Warden: the model for the stroke fix.
- **path_shimmer** as a dark −34 dB earth shift, throttled to 0.5 s; **dew_catch** near-silent at −45; harmony strike
  at −40 and throttled 1.5 s; status cues at about −37.
- **Leaf lost** is the loudest event, with an 8 dB duck: the priority holds at the top.
- **The plant recipe's top end** (an extra lowpass at 2200, rolloff about 2.1k) is clean. Its problems are the wiring,
  the jitter and the harp, not brightness.
- **Ambience** sits about 12 dB under the music and thins with the field.
