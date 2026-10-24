# Sound Council 2026-10-23: Composer seat

Scope: every music stem, one-shot and stinger, and the musical SFX (plant, grow and bloom strums, rest and act swells, UI and Dream chimes, kin notes, Remember notes). The question for each: is it in key with the score, and does it clash with it?
Evidence tags: **[doc]** audio_direction.md, **[recipe]** tools/sound_generator.gd:N, **[num]** sounds_measured.tsv, **[hook]** scripts/audio/sound.gd or sound_hooks.gd.

## 1. Top 10 findings (ranked)

### 1. `plant`: the Warden / Sprout placement plays a detuned, randomly pitched harp note over the score (the user's example)
- **Where:** `plant_01..03`, used for every placement (Sprouts, walls, every Warden) and for gift pieces.
- **What is wrong:** The recipe [recipe 3389-3394] is a thump, a soil scrape, a rising band-passed noise sweep (`_sprout_unfurl`, 350→1100 Hz [recipe 3396-3399]) and then a Karplus-Strong pluck on A3 / D4 / A3, 0.42 s after the thump.
  - **Out of tune.** It is played with the default pitch jitter: `sound.play(&"plant", tower.global_position)` [hook sound_hooks.gd:234, :1302]. Sound.play's default is `PITCH_JITTER := 0.05` [hook sound.gd:17, :186], which is ±5 %, about ±85 cents. Every placement lands up to almost a semitone off the score's key.
  - **Off key even when in tune.** The A clashes with the B♭ bars of the rest and drift progressions (A against B♭, a semitone): 4 of 20 rest bars, 3 of 16 drift bars. The D clashes with the A-major bars (D against C♯).
  - **Off the grid.** The note lands at a random time against a 60 or 72 bpm piece.
  - **A melody where none belongs.** Maze building places dozens of walls and Sprouts, so the player hears a random, detuned A–D–A harp jangle. That breaks "melody belongs to the music" and "never form a melody" [doc Wardens; Warden sheet rules].
  - **Not what the doc asks for.** The doc specifies "earth rumble + wood creak as the roots rise" [doc Building]. The recipe has no creak and no rumble. The rising noise sweep reads as a synth whoosh, not a leaf; house rule: no sweeps. The note is a plucked-synth shot; house rule: Organic.
  - **Brighter than its siblings.** Centroid is 1023–1081 Hz [num], the brightest of the building sounds (`plant_heartwood_sapling` is 177 Hz). The attack peaks within 0–46 ms [num].
- **Fix:**
  - Rebuild it as the doc's sound: `_thump(0.28, 100–120)` + `_rumble(0.35, 140, 0.05, 0.25)` + `_lowpass(_creak(SFX_RATE, 0.35, 12, 24, 260), 700)` + the soil scrape.
  - Drop `_sprout_unfurl` from it, or replace it with `_air(0.3, 500, 0.15, 0.12)`.
  - Vary the three variants by body (thump cutoff, creak speed), never by pitch.
  - If the user wants an "answering" note, use one note only: a tuned-air low D (`_tuned_note(50, 0.6)` at −14 dB, no pluck). D is in Dm, B♭ and Gm.
  - Whatever the content, play it with jitter 0: `sound.play(id, pos, 0.0, 1.0, 0.0)` at both hook lines.

### 2. Every other tonal SFX is pitch-shifted out of the key
Each of these sounds is tuned to D / A / F♯ in the recipe, then detuned at play time:

| Hook | Shift | What it detunes |
|---|---|---|
| `evolve_*` [hook :634] | default jitter ±5 % | the D–A–D pluck strum and D/A hum of `_grow_bloom` [recipe 3401-3411] |
| Final Bloom material [hook :748] | pitch 0.8 (−3.9 semitones) | the light, song and memory materials become ≈B♭/F (+14 cents), under the in-key D–F♯–A strum: B♭ against A, F against F♯ |
| Remember bloom material [hook :1096] | pitch 0.9 (−1.8 semitones) | sits under the in-key sung D/F/A note |
| Legendary offered [hook :1260] | `dream_flip_3` at 0.85 (−2.8 semitones) | D–A–D–F♯ becomes roughly B–F♯–B–D♯ (+19 cents) |
| Legendary taken [hook :1264] | `dream_take_2` at 0.9 | the choir and chime in roughly C major (+18 cents) |
| Nurture [hook :717, :734] | `pow(2, -(rank-1)/12)`: one semitone per rank | the tuned materials walk out of key (see below) |
| `status_exposed` (tuned A) [hook :1190] | jitter 0.03 (±0.5 semitone) | |
| Reactions [hook :1140], Crowned signatures [hook :1146] | jitter 0.03 and 0.02 | Changeling's tuned D / A♭ [recipe 3323-3326], Nightbloom's "two sung notes in key" |

The nurture walk: the tuned materials are light (D/A tuned air [recipe 3413-3416]), song (D/A hum) and memory. Rank 2 plays C♯/G♯, rank 3 C/G, rank 4 B/F♯, rank 5 B♭/F.

**Fix:**
- Jitter 0 for every sound containing a pitched note.
- For rank depth on tonal lines, step by in-key transpositions instead of semitones: 1.0 → 0.749 (A/E: down a fourth, D→A) → 0.667 (G/D) → 0.5 (an octave down). Or keep the pitch and add body (a lower octave layer, a longer tail), which is what the doc's "deeper and fuller" really asks for.
- Final Bloom and Remember: play the material at 1.0, or at 0.5 (an octave down).
- Legendary: play at 1.0 and get "low" from a separate octave-down layer.

### 3. The boss layers ignore their own boss bass: every warm A collides with the bass's A♭
- **The bass.** The boss bass ostinato is `[38, 38, 44, 41, 41, 38]` per bar (D D A♭ F F D in eighths; bars 6–7 of each 8 are B♭ F D) [recipe 1571-1576, 1829-1834].
- **The warm counter-melody** plays D–A–F at `t0 + k*2e` [recipe 1593-1594, 1859-1860]. Its A lands exactly on eighth 2, the bass's A♭: a semitone (minor 9th) on the same instant, in every even bar. Its pluck takes chord roots from `DRIFT_CHORDS` [recipe 1591, 1856], so in bars 7 and 14 it plays A over the bass's B♭.
- **Other layers built on `DRIFT_CHORDS` roots,** a different chord map from the boss bass:
  - Great Toad (Mire Hag) square-wave reed [recipe 2005-2007]
  - Barrow King bowed line [recipe 2045]
- **Warm-coloured notes sustained against the A♭ in boss signature layers:**
  - Huntsman horn on A2 (midi 45) for 3.75 s, against the bass's A♭2 in the same octave [recipe 2014-2016]
  - Old Stag horn D3→A3 [recipe 1611-1612]
  - Lamplighter held A4 [recipe 2029-2030]
  - Mourning Mother's line D–C–B♭–A [recipe 2052]

Some cold colour is intended. These are not the designed tritone: they are random semitone grinds that blur the Hollow form instead of sharpening it.

**Fix:**
- One `BOSS_HARMONY` table (D for bars 0–5, B♭ for bars 6–7) that the warm pluck, Great Toad, Barrow King and the echoes read.
- Warm motif at e, 3e, 5e: D over D, A over F (an F-major colour), F over D. The A never meets the A♭.
- Huntsman horn on D2/D3, or on A♭ itself (the hollow call).
- Lamplighter held notes D4 / F4 / D5 instead of A4 / D5 / F5.

### 4. The `rest` exhale is a D-major strum, then the tail resolves to D minor
- `rest` [recipe 455-459] is a falling noise breath plus a D–A–D–F♯–A pluck strum. It fires at `rest_started`, off the grid [hook :255].
- In the same moment `music_then(tail)` waits for the next bar line (≤2.5 s), then plays A major → **D minor** [recipe 1544-1554, 1773-1781].
- The player hears major, then a "resolution" to minor: deflating. On every ordinary rest it also spends the Hope form's D major, which the doc reserves for big wins [doc Motif].
- The same applies to `final_bloom` variant 1 (D–A–D–F♯–A [recipe 2268-2271]), heard over the D-minor rest piece; F♯ against the piece's F.
- `act_swell` (D-major triangle chord [recipe 3376-3380]) is fine after a boss's Hope form. It is not fine when an act starts without one (a resumed save).

**Fix:**
- `rest`: breath only. The tail is the music's exhale, which is what the doc says ("the music exhales"). Or an open fifth D–A–D–A, no third.
- `final_bloom`: both variants as the open-fifth voicing (variant 2 already is).
- `act_swell`: an open fifth with the D-major third entering only if `MUSIC_AFTER` is set (the Hope form is playing).

### 5. The act 3 boss theme is transposed down a fourth against an untransposed bass
- `var m: int = note[1] - (5 if act == 3 else 0)` [recipe 1840] turns the Hollow motif D–A♭–F into A–E♭–C, over the same D–A♭–F bass and dread1.
- E♭4 lands over the bar 1 downbeat bass D (minor 9th). A3 lands over the B♭ bars 6–7 (semitone).
- The motif no longer sits at its home pitch, so the act 3 boss is the one place the Hollow form is unrecognisable. The theme's register, centroid 410 Hz and rolloff 937 Hz [num], suggests the −5 was a range fix.

**Fix:** −12 (an octave), never −5.

### 6. The act 2 thirds and the act 3–4 echoes are literal, not harmonic
- **Act 2 thirds.** `_third_below` uses a harmonic-minor scale with C♯ and no C [recipe 2081-2092]:
  - The melody's E gets a C♯ under it in bar 2 (F major) and bar 13 (C major): C♯ against the pad's C.
  - The melody's G gets an E under it over Gm (bars 5, 10): E against B♭, a tritone.
- **Act 3 call-and-answer and act 4 canon.** Both repeat each melody note exactly a bar later, an octave down [recipe 1745-1749], whatever chord is then playing:
  - Bar 7's C♯ is answered over bar 8's B♭ (C♯ against D).
  - Bar 6's F is answered over bar 7's A major (F against E and C♯).
  - Bar 11's A is answered over bar 12's B♭.
  - Act 4 makes this the defining texture of its drift.

**Fix:**
- Natural-minor scale with C in `_third_below`, and use C♯ only when `DRIFT_CHORDS[bar]` is `[45, 4]`.
- For canon and answer, snap the echoed note to the nearest tone of the chord it lands on, or answer at the same bar's chord tones (a third or sixth below), not a bar later.

### 7. The boss doesn't drive: its felt pulse is slower than the drift it replaces
- The doc asks for "96 bpm 6/8, two dotted beats per bar, bar 2.5 s" [doc §3 Boss]. Those numbers contradict each other: two dotted beats in 2.5 s is a dotted beat of 1.25 s, which is **48 bpm** (eighths at 144).
- The boss drums place 4 hits per bar, 6 on a phrase end [recipe 1556-1567, 1810-1826]. The drift's dread2 already plays 6 eighth-tom hits per bar [recipe 1529-1530], and the drive stem 6 or more [recipe 3470-3480].
- So drift → boss loses pulse density at the moment it should tighten. The bowed bass eighths (6 per bar) are the only motor.

**Fix:**
- Add a soft frame-drum eighth ostinato (6 per bar, accents on 1 and 4, ghost notes at 0.15–0.25) to every boss drums stem, plus a felt-tom pickup on eighth 5 of every bar.
- Ask the Sound Discussion chat to restate the tempo as "dotted beat 48 / eighths 144, two 6/8 halves per 2.5 s bar", so nobody "fixes" it to 1.25 s bars and breaks the bar-line sync.

### 8. The Hollow Oak finale has no material of its own, and act 4's drift already spends the climax
- **One melody for all four acts.** Every act's boss theme is `BOSS1_THEME` [recipe 1838-1852], the act 1 Stag melody re-orchestrated. The doc: "The Hollow Oak gets its own full finale" [doc §3].
- **The act 4 drift already has everything** [recipe 1720-1734]: high and low choir, strings, a drum on every bar, a sub pedal on D, the canon. The finale adds only a tom roll every 2 bars and choir on the theme. The step from the act 4 drift to the finale is smaller than the step from the act 1 drift to the act 1 boss.
- **The act 1 and act 2 drift bases are missing the doc's act-table items** [doc "Bigger every act"]:
  - Act 1 base has no felt-drum pulse and no bowed D drone [recipe 1495-1505].
  - Act 2 has no 2-drum pattern; drums start in act 3 [recipe 1724-1726].
  - So the act 1 → 2 step is mostly timbre.
- **Base RMS is flat** after normalisation [num]: act 1 −18.9, act 2 −20.3, act 3 −18.6, act 4 −19.2. All the "bigger" rests on +1 dB per act and on density.

**Fix:**
- Write a finale theme: the Hollow form in the bass, the Warm form answering in the choir, and the Hope form's F♯ withheld until the turn.
- Reserve something for the finale only: the high choir and the sub pedal belong to the finale, not the act 4 drift.
- Add the act 1 drift's felt pulse and bowed D drone, and the act 2 drift's 2-drum pattern.

### 9. The run's endings cut off, then go silent
- **Loss.** `_on_run_ended` calls `sound.stop_music()` [hook :1234], a 0.15 s fade [hook sound.gd:253], then the `loss` stinger. That is a cut-off; the user's complaint was "the music cuts off".
- **Win.** `_on_run_ended` waits `once_remaining()`, which is the queue wait + ONCE_OVERLAP. The queued `rest_act4` set therefore starts 1 s before the Hope form ends, fades in, and is cut 1 s later by `stop_music()` [hook sound.gd:265-266, 361; hooks :1227-1239]: a one-second flicker of the act 4 rest piece before the win stinger.
- **After both stingers** (4 s and 5 s) the results screen has no music: dead air until the player leaves (the title restarts `rest_act1` [hook sound.gd:115-117]).
- **The stingers' content.** `win` adds three CHIME bells (inharmonic partials 2.76 / 5.4 / 8.93 [recipe 36, 469-470]; rolloff 11951 Hz [num]): glassy tinkle. `loss` (D–B♭–F–D–A falling [recipe 474-475]) never uses the Hollow form.

**Fix:**
- Loss: duck the music and let the loss stinger start on the outgoing set's next bar line, fading the set over that bar.
- Win: cancel the queued rest set before the stinger (`_queued_set = {}`), then `win`.
- After either stinger, fade the act's rest piece (or `rest_act1`) back in at −6 dB under the results screen.
- `win` = the end-card button (D–A–F♯ on harp + music box into a held D-major chord, the marketing sound [doc end-card]), no CHIME.
- `loss` = D–A♭–F falling into the cold D2 and the E♭ bell.

### 10. UI and Dream chimes climb, glitter and ignore the chord under them
- **`dream_open`** [recipe 432-435]: a rising 6-note music-box run A–C–D–E–G–A, 50 ms apart. A climbing chime is the coin sound the third listen banned. Its C natural clashes when the rest piece is on its A-major bar. Measured: centroid 1615 Hz, rolloff 6158 Hz [num], the brightest musical UI sound.
- **Legendary `dream_take_2`** [recipe 442-447]: a rising CHIME arpeggio D–F♯–A–D–F♯. It also climbs, and the CHIME partials are glassy.
- **`dream_flip_3`** [recipe 2380]: D–A–D–F♯, D major, over the D-minor rest piece. The music is only lowpassed at 900 Hz on choice screens [hook sound.gd:20], and F♯ (370 Hz) passes that filter.
- **`stinger_dawnburst`** [recipe 963-968; hook :802]: a D-major choir on the Music bus, fired 0.9 s after the Dawnburst on no bar line, over whatever drift chord is sounding (B♭, C, Gm …), with only the 8 dB / 1 s duck. The doc wants "then the music returns" [doc Chains].

**Fix:**
- `dream_open`: the breath plus one low D–A fifth (soft-mallet music box at D4 / A4), no run.
- Legendary take: choir D-major swell plus a single low BELL D3, no arpeggio.
- `dream_flip_3`: open fifth D–A–D–A, the Hope colour carried by the tuned-air burst.
- Dawnburst: duck the harmony layers (base, warm) fully for the stinger's 3 s, keeping drums and dread, and re-enter on a bar line.

## 2. Every other finding

| Where | Problem | Evidence | Fix |
|---|---|---|---|
| Gather, acts 2–4 | The "far hollow A♭" horn (44, A♭2) sounds against the bowed A2 string (45) in the same octave: a 6 Hz beating mud, not a call | recipe 3449-3450, 3456-3457 | A♭3 (56) or A♭ after the A string drops; or make the string D2–A2 and the call A♭3 |
| Rest → gather | The rest stem fades over `GATHER_FADE` 5 s with its 60 bpm melody still moving under the 72 bpm roll: two tempos for up to 5 s. The doc wants the rest's lead to *hold its last note* | hook :131, :373; doc Transitions 2 | Fade the rest over one rest bar (3 s) and let the gather open with its own held note in the act's lead (D5, ringing 5 s) |
| Karplus-Strong tuning at 22.05 kHz | The period is int(rate/f) + 0.5 samples, so music plucks drift: A4 −13 c, E4 +10 c, F4 −10 c, D4 −9.5 c. Most audible in the Hope landing (pluck A4 vs music-box A) and the act 1 rest rolls | recipe 193-214; computed from the code | Fractional delay (allpass) or n = round(rate/f − 0.5); or render music plucks at 44.1 kHz and downsample |
| Act 3 palette ("blurred by fog") | Act 3 is the brightest act, not the foggiest | num: dread2 centroid 1897 Hz / rolloff 6191 (bowed-saw pure A4 + reeds [recipe 1955-1960]); base 925 Hz; hope rolloff 6191; tail 6288 | Lowpass the saw at 1.2 kHz, put the reeds band at 350 Hz, flute lead an octave lower in the drift |
| Whispers in act 1 dread2 and the act 1 boss theme | `_whisper` is formant noise chopped into syllables: speech-like, against the house rule (the sixth listen rejected anything talking-like). The doc's act 1 palette still lists whispers, a doc/house-rule conflict for the lead to rule on | recipe 216-239, 1527, 1613-1615 | Replace with a one-vowel breathy hum (`_choir` lowpassed at 600) or the tuned air at a cold interval (D/E♭) |
| `sig_hollow_oak_withering` | The drone is `hz(31)` = G1, not D: a G pedal under the D–A♭–F bass (G vs A♭ grinding at 49/52 Hz). RMS −14.8 [num], the loudest boss layer | recipe 2059-2060 | hz(26) (D1) or hz(38) |
| Lamplighter `_2.._4` | Plain triangle tones held 40 s, RMS −12.4 to −13.0 vs the theme's −18 to −20 [num]: the loudest, most synthetic sigs; the A4 hits the bass's A♭ (see #3) | recipe 2027-2031 | Bowed or hummed (`_choir`) notes on D4 / F4 / D5, normalised to −20 RMS |
| Act 4 boss bass an octave down | Pattern −12 = D1 37 Hz / A♭1 52 Hz / B♭0 29 Hz through a 350 Hz lowpass: the Hollow motif lives only in the harmonics, and on laptops and phones (mobile goal) it vanishes | recipe 1832 | Keep the pattern at its act 1–3 pitch and add the octave below as a quiet double |
| Hope one-shot, act 4 | Its bowed A♭2→A2 (44/45) enters an octave above the act 4 bass it is "healing" (32/33) | recipe 1789-1790 vs 1832 | In act 4, A♭1→A1 with an A2 double |
| The turn | The bass doesn't "keep sounding": the whole boss set fades over TURN_FADE 0.9 s and the one-shot starts a fresh bowed A♭. It works, but the doc's continuous line is a new note | hook sound.gd:282-288; doc Transitions | Acceptable; or keep `bass` at level for 1 bar (fade the other layers) and start the one-shot 0.2 s in |
| Heartbeat in boss fights | The boss sets have no `heartbeat` stem, and `set_layer(heartbeat)` runs only in drift mode: at ≤5 leaves against a boss (the most dangerous moment) the music says nothing | hook :444-448; no `mus_boss_act*_heartbeat` [num] | Render a boss heartbeat stem (lub-dub on the dotted beats) or let the drift's heartbeat play over the boss set |
| Drum onsets | `_tom` has a 2 ms attack with a 1 ms noise click; `_felt_hoof` / `_frame_drum` 4 ms; `_knock` a 3 ms triangle tap. These are "hard onsets" in music too | recipe 2173-2176, 2110-2122, 1329-1333; num rolloffs: sig_night_mare 7730, barrow_king 7946, great_toad 8064, heartbeat 8053, sig_hollow_oak 9367 Hz (check) | 6–10 ms attacks; noise click lowpassed at 400 Hz |
| Harmony is the generic "epic minor" loop | Rest, drift, the boss warm pluck, the drive, Great Toad and Barrow King all ride one progression, i–VI–III–VII–i–iv–VI–V (Dm B♭ F C Dm Gm B♭ A). That loop is stock library music; rest and drift share it, so the rest isn't "its own piece" harmonically | recipe 39, 1459-1467 | Give the rest piece its own harmony: a D pedal with i–iv–i and VI over D, suspensions, the Picardy third only at A-section ends |
| Kalimba sparkle | Eighth-note kalimba runs in every act from 2 on, act 4 included (not in act 4's palette: bells + choir) | recipe 1750-1753 | `if act == 2` only |
| Act 4 sub pedal on D under A-major bars | D1 under A–C♯–E (bars 7, 14): a classic pedal, fine, but dread2 adds D1+A1 saws too [recipe 1966-1967]: three layers on D1, low-end mud | recipe 1734, 1966 | Drop dread2's D1 saw in act 4 (keep A1) |
| `attack_acorn` | A music-box D4 bell as a Warden shot, played with jitter 0.05: against the rule "no plucked or music-box tones on shots", and detuned | recipe 422; hook :885 (check whether Acorn uses it) | The acorn and wood material (`_wood_knock`), or jitter 0 if kept |
| `attack_light` variant 3 | Triangle pair `69+v, 76+v`: v=1 B♭/F, v=2 B/F♯, out of key, with jitter | recipe 401-405 | **Approved (Firefly Jar): do not change without the user.** If they agree: v as amplitude or timbre, pitch fixed at A/E |
| `beam` | Triangle D4/A4, "pitched up as it ramps": a continuous out-of-key glide, plain oscillator | recipe 491-494 | Ramp by brightness or level, or in-key steps |
| `act_swell`, kin `glow` and `flute`, `_glow_swell` | Plain triangle-oscillator chords: Organic rule (not blips, but synth pads) | recipe 3377-3378, 2215-2219, 1148-1153 | Tuned air (`_tuned_note`) or `_choir` instead of `"tri"` |
| `discover_reaction` | D-major music box (D–F♯–A) + a rising noise sweep, mid-drift over any chord | recipe 970-975 | Open fifth D–A; breath without the glide |
| Rest `rest` breath | A falling band-passed noise sweep 1200→300 Hz; rolloff 6266 Hz [num]: bright for an exhale | recipe 456 | Fixed-band `_exhale(1.2, 350)` |
| Boss `theme` horn swells | `_horn_call(r, 38)` at `0.3 + 0.08*act`: louder each act, fine; but the act 1 boss theme lacks them (built separately) | recipe 1853-1854 vs 1578-1585 | Add to act 1 for one family sound |
| Title | The title plays `rest_act1` exactly as the act 1 rest: no title identity, and the Hope / end-card button the marketing uses is never heard at the title | hook sound.gd:115-117 | A title one-shot: the end-card button into the rest piece on its bar line |
| Doc tempo line | "96 bpm in 6/8 … bar 2.5 s" is internally inconsistent (see #7) | doc §3 | Sound Discussion restates it |

## 3. Missing sounds and music

- **Heartbeat during boss fights** (see table).
- **Results screen bed:** silence after the win and loss stingers.
- **Choice screens:** the doc says "music drops to a soft pad". The implementation only lowpasses the running piece at 900 Hz, so the piece's melody and pulse keep moving under a "time has stopped" screen. Wanted: a sustained pad stem per rest set (`mus_rest_act<N>_pad`, the chord on D) that replaces `base` while muffled.
- **Boss reaching the Heartwood:** the drums cut for a bar [hook :409-415], with no musical "bite" accent (a low hollow-form chord hit). Optional.
- **Act-break intro:** `act_started` gives the swell, then the next act's rest piece starts at bar 1 cold. Wanted: a 1-bar "new act" pickup in the new act's lead (its instrument introducing itself) before the rest piece.
- **Waymark placement / boss-arrival flourish:** none yet (CLAUDE.md lists it as not done).
- **Calling evolution choice** (drift 5 / 25 / 50 / 75 rests) and **Legendary**: placeholders built from other sounds; Legendary is pitched out of key (#2).

## 4. What already works (keep)

- **The motif is everywhere it should be:**
  - rest and drift melodies open D5–A5–F5–D5 [recipe 1462, 1469]; the drift states it on bars 0, 4 and 12
  - dread1's hollow D–A♭–F in bowed bass every 4 bars
  - the act 1 boss theme opens D–A♭–F–E–D
  - the gather's D–A pickup
  - the Hope one-shot's A♭→A turn into D–A–F♯ on D major; the act 4 version plays it whole
- **Loops and handovers:**
  - The loops seam correctly: note stems fold their tail onto the start, drones crossfade (`_fold_loop`, recipe 2154-2166).
  - Layers change on bar lines; all stems start in the same frame.
  - The gather hands over on its exact last bar line (`next_at`).
  - The tail resolves A major → D minor, and that works after any drift bar.
- **Night Mare** lap layering (a second rhythm, then a D/A♭ tritone drone) is exactly the doc.
- **Scarecrow's** crooked, detuned waltz is the best signature: cold, playful, unmistakable.
- **Dispel** (tuned air D/F♯/A, jitter 0) and **Firefly Jar** stay approved and untouched.
- **In key:**
  - Song family hits play tonal with jitter 0 [hook :941-952]
  - Kinship bond intervals sit in D-minor pentatonic
  - Remember notes are D/F/A
  - Chain swells grow by level, never pitch
- **Act escalation plumbing:** +1 dB per act, trim on layers, a drive stem in the last block before each boss.

## Stem notes (one line each)

**Rest pieces** (60 bpm 3/4, 20 bars, 60 s): the Heartwood theme (motif, then answered; B section lifted) over one rolled chord per bar plus a faint triangle pad.
- act 1: music box + harp
- act 2: marimba
- act 3: flute + harp, fog echoes
- act 4: filtered bells with a hum under each note

**Drift stems** (72 bpm 3/4, 16 bars, 40 s):
- **base:** the waltz pulse (root–fifth–third) + pad + the drift melody in the act's lead.
  - act 2 adds strings, a bowed bass, thirds and kalimba.
  - act 3 adds the choir pad, a counter-line, the call-and-answer choir, and a tom every 2 bars.
  - act 4 adds high and low choir, a tom every bar, the canon and a D1 sub.
- **dread1:** a detuned D1 saw drone, a low thump on each downbeat, and the bowed D–A♭–F every 4 bars.
- **dread2:** the cold colour plus soft eighth toms.
  - act 1: D4/E♭4 tremolo + whispers
  - act 2: D3/E♭3 tremolo + croaks
  - act 3: a wavering pure A4 "saw" + reed noise
  - act 4: D1/A1 saws + slow creaks
- **heartbeat:** a lub-dub on every beat.
- **drive:** toms on the beats, a frame drum, and the bowed bass on chord roots every beat; eighth toms from act 2, deep downbeats from act 3, knocks in act 4, a roll every 4th bar.

**Boss stems** (2.5 s bars, 6/8):
- **drums:** toms + frame drum on eighths 0/2/3/5, a deeper pair from act 2, rolls from act 3; act 4 wooden knocks.
- **bass:** bowed eighths D D A♭ F F D (B♭ in bars 6–7); act 4 an octave down + a hummed D.
- **theme:** the cold bowed melody (Hollow form) + its low double; choir from act 3; horn swells on phrase ends.
- **warm:** D–A–F in the act's lead on even bars + root plucks (the clash in #3).

**Signature layers:**
- Stag: horn D3→A3 + knocks
- Night Mare: hooves, then a running rhythm, then a D/A♭ drone
- Scarecrow: crooked detuned music box + wings
- Mire Hag: square-wave reed on drift roots + a lurching knock
- Huntsman: A2 horn + running toms
- Lamplighter: D/A/E♭ triangle organ, then held A4 / D5 / F5
- Moth Queen: A/B♭ tremolo + wings
- Barrow King: a dragging tom + bowed roots behind the beat
- Mourning Mother: hummed D3 + a falling D–C–B♭–A (mend: a held A4)
- Oak Thorned: 3, then 6, then 9 wooden taps per bar
- Oak Withering: a G1 saw
- Oak Remembering: a hummed A2
- Echoes: the act 1–3 signatures through a 700 Hz double lowpass

**One-shots:**
- tail: A major → held D minor, 8.5 s
- hope: A♭→A bowed + D–A–F♯ → D major, 11.3 s (act 4: whole, 18.8 s)
- gather: a bowed D swell + growing tom roll + D–A pickup (+ A♭ call from act 2), 5 s to the downbeat

## Transitions and their timing

| From → to | Trigger | Timing (as implemented) |
|---|---|---|
| Title → run | the scene changes | `rest_act1` keeps playing if the run is in act 1; otherwise crossfade on the next 3 s bar line over one bar |
| Rest → drift | Start pressed (`drift_started`) | `drift_start` breath at once (−8 dB) → the gather starts on the rest's next 3 s bar line (≤3 s) while the rest fades over 5 s → the drift set starts on the gather's 5.0 s downbeat → dread1 may join from 13 s after Start, on a bar line |
| Drift → drift (auto / called early) | within a block | no change; layers on 2.5 s bar lines |
| Drift → boss (in-block) | boss drift starts | the boss set starts on the next 2.5 s bar line (drums only) while the drift fades over 1 bar → bass + theme join on the following bar line; warm joins below 50 % on a bar line |
| Rest → boss (a resumed save) | the same | the gather, then boss drums at 5.0 s, bass + theme a bar later |
| Boss bites the Heartwood | `boss_bit` | drums off on the next bar line, back after ~5 s; warm off for the rest of the fight |
| Boss dispelled → rest | the dispel | drums at once to 0; the boss set fades over 0.9 s; the hope one-shot starts immediately; the rest set starts 1 s before the hope ends |
| Drift → rest | `rest_started` | `rest` SFX (D-major strum) at once → the tail on the next 2.5 s bar line, the drift fading over 1 bar → the rest set 1 s before the tail ends |
| Act break | `act_started` | `act_swell` at once; the next act's rest piece retargets the queued handover (after a hope) or crossfades on a bar line |
| Choice screens | a screen is visible | Music bus lowpass eases to 900 Hz (~0.5 s) and back |
| Loss | `run_ended(false)` | music fades in 0.15 s, then the `loss` stinger, then silence |
| Win | `run_ended(true)` after the Oak | waits for the hope to end (the act 4 rest flickers for 1 s), music fades in 0.15 s, the `win` stinger, then silence |
