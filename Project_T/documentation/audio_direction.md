# Audio Direction

Phase 4, topic 12 of `design_plan.md` (the audio half; visuals are in `art_direction.md`). Draft,
2026-09-27. Follows the dark fairytale in `story.md`.

## Pillars

1. **Warm vs cold, in sound too.** Wardens and the Heartwood sound warm, wooden and acoustic;
   nightmares sound cold, breathy and wrong. The player should hear the contrast with eyes closed.
2. **Dread builds, then breaks.** Music and ambience tighten as nightmares get closer to the
   Heartwood, and relax at every rest. Rests are the exhale.
3. **Every sound is information.** Each nightmare type has a signature sound, so players can *hear*
   a Night Hound pack or a Procession coming before they see it.
4. **Unsettling, not harsh.** Whispers, drones and silence rather than screams and jump scares.
   Nothing ear-piercing, nothing that punishes long sessions (runs are 1–2 hours).
5. **Warm, not weak.** Wardens have soft timbres (wood, water, bells) and real low end. Combat must
   feel like it lands. **Weight comes from the low end and the level, never from brightness.**
6. **Rounded, never sharp** (second listen). The whole game sounds like it's heard through moss and
   night air:
   - **No clicks, crackles or hiss textures.** No bursts of high-passed noise, no random click
     trains, no constant noise beds. Texture comes from low, soft noise (breath, earth) instead.
   - **Soft onsets.** Nothing starts instantly: at least a 3–5 ms fade-in on hits, 10 ms+ on
     everything else. The "punch" is a rounded *tock* or *thump* (300–900 Hz, plus the low body), not a snap.
   - **Dark top end.** SFX content mostly below ~3 kHz; nothing sustained above ~6 kHz. Bells and
     chimes use their lower octaves and soft mallets.
   - **Ear-fatigue check** for every sound: loop it for a minute, then play 10 minutes at 3× speed with
     a full maze. If anything stings, it's too bright.

**First listen (2026-09-27, placeholder build):** the wind was too strong with a hard hiss under it,
the music was too loud, and attacks had no impact. The sections below are revised for that; see
"Revisions from the first listen" at the end for the summary.

## Instrument palette

| Warm (the dream, Wardens, Heartwood) | Cold (nightmares, the edge) |
|---|---|
| kalimba, music box, harp, marimba | detuned drones, sub rumbles |
| wooden flutes, soft hummed choir | bowed metal and saw, reversed piano |
| felt piano, gentle bells | breathy whispers, low tremolo strings |

**Per act** (matches the palettes in `art_direction.md`):

| Act | Season | Warm lead | Cold colour |
|---|---|---|---|
| 1. Forest's Edge | spring dusk | music box, harp | faint whispers, low drone |
| 2. Deep Wood | summer night | marimba, crickets in the ambience | low strings, frog-like croaks |
| 3. Misty Hollow | autumn fog | wooden flute | bowed saw, wind through reeds |
| 4. Heartwood Glade | winter dark | bells, hummed choir | deep drones, cracking ice |

## Music: adaptive, in layers

Each drift track is written as **synced stems** that fade in and out on bar lines:

| Layer | Plays when |
|---|---|
| **Warm base** (the act's lead melody) | always during a run |
| **Dread 1** (drone, low pulse) | nightmares are in the dream |
| **Dread 2** (whispers, tremolo strings) | many nightmares, or any within the last third of the path |
| **Heartbeat** (low thump, music slightly muffled) | 5 leaves or fewer left |

| Moment | Music |
|---|---|
| **Title** | the Heartwood theme: slow, warm, a single cold note under it |
| **Rest** | **its own piece** (2026-10-04): the Heartwood theme, slow; see "The score" below |
| **Drift** | base + dread layers by intensity |
| **Boss** | **an act boss theme** + **a signature layer per boss** (12 in the pools), and the Hollow Oak's own full finale (2026-10-04; replaces "one full theme per boss", 2026-09-28); below half health a **warm counter-melody** enters. See "The score" below |
| **Choice screens** (family pick, Dream, Omen) | music drops to a soft pad; time has stopped |
| **Memory Grove** | the Heartwood theme, gentle, with music box |
| **Win / loss** | short stingers: a warm resolving chord / a slow fall into a single cold note |

## The score (2026-10-04): rest, drift, boss, and the Heartwood motif

Three distinct music states, all built from **one motif**, so the whole game (and every trailer
and short) sounds like one world. Still "rounded, never sharp": soft onsets, a dark top end, felt
mallets, bowed (not plucked) bass, no hard snares or cymbals.

### The Heartwood motif (the thread through everything)

**D – A – F** (up a fifth, down a third), in the warm lead of the act. Three notes, recognisable on
any instrument.
- **Warm form:** D – A – F, then home to D. Rest pieces, the drift base, the warm boss counter-melody.
- **Hollow form** (the nightmares' corruption of it): D – **A♭** – F. The flattened fifth (a tritone)
  in bowed bass or reversed piano. It's the cold layers' and bosses' motif: the same three notes,
  bent wrong. Players feel the threat without knowing why.
- **Hope form:** D – A – **F♯**, landing on a D **major** chord. Reserved for big wins: a boss
  dispelled, the run won, the Dawnburst, and every marketing end card.

### 1. Resting: its own piece, the exhale

- **The Heartwood theme:** a full melody built on the motif, slow (**60 bpm, 3/4**, bar 3 s), warm,
  sparse, lots of air. Not the drift base thinned: different tempo, different melody, no pulse
  underneath, no dread at all.
- **One per act, same melody in the act's warm lead:** act 1 music box + harp, act 2 marimba +
  kalimba, act 3 wooden flute + harp, act 4 soft bells + hummed choir (a hum on one vowel, no
  changing vowels: it must never sound like speech).
- **Long, clean loop:** rests can last minutes, so **60 s** (20 bars of 3 s at 60 bpm, 3/4), with an
  A section and a B section (10 bars each) so it doesn't wear thin. Notes
  ring across the loop point (the generator's tail fold).
- **Choice screens** muffle it as now. The rest bonus, Dream and Omen sounds sit on top of it.

### 2. Drifting: the layered adaptive track, per act

Keeps **72 bpm, 3/4** (bar 2.5 s), synced stems that fade on bar lines, but **16 bars (40 s)** per
loop with an A and a B half (the 20 s loop repeated too often over a block). Same stem names per act:
`mus_act<N>_base`, `_dread1`, `_dread2`, `_heartbeat`.

| Layer | Plays when | Content |
|---|---|---|
| **base** | always in a drift | the act's warm lead playing the motif and a drift melody over a gentle pulse (harp / marimba / flute / bells); the pulse is what makes it a drift and not a rest |
| **dread1** | nightmares in the dream | low drone + slow pulse, and the **Hollow form** of the motif in bowed bass every 4 bars |
| **dread2** | many nightmares, or any in the last third of the path | the act's cold colour (whispers, tremolo strings, croaks, bowed saw, ice) + a faster soft-mallet low tom pattern; tension |
| **heartbeat** | 5 leaves or fewer | low lub-dub on the beat; the music slightly muffled |

| Act | Warm lead (base) | Cold colour (dread2) | Character |
|---|---|---|---|
| 1. Forest's Edge | music box, harp | faint whispers, low drone | sparse, a lullaby with something under it |
| 2. Deep Wood | marimba, kalimba | low tremolo strings, frog-like croaks (soft, low) | warmer and busier, a summer night that isn't safe |
| 3. Misty Hollow | wooden flute, harp | bowed saw, wind through reeds | the motif blurred by fog: longer notes, more reverb |
| 4. Heartwood Glade | soft bells, hummed choir | deep drones, slow ice groans (no crackle) | the fullest base; the dread layers are heaviest here |

Acts get **slightly denser** as the run goes on (more of the motif, more counter-lines), never louder
overall: adding layers must never make the music louder (the stems are trimmed together, as now).
**Act 1 first** (full pass), then acts 2–4.

### 3. Boss: an act theme + a signature layer per boss

A **full boss track per act** with real drive, plus a **short signature layer for each of the 12
pool bosses** that sits on top (synced, 8 bars), instead of 12 full tracks. The Hollow Oak gets its
own full finale.

- **Tempo:** **96 bpm in 6/8** feel (two dotted beats per bar, bar 2.5 s: the same bar length as the
  drift, so the drift → boss crossfade lands on a bar line). Driving, rolling, never frantic.
- **Act boss theme stems** (`mus_boss_act<N>_*`): **drums** (deep felt toms and a frame drum,
  rounded; no snare, no cymbals), **bass** (bowed bass ostinato on the Hollow form of the motif),
  **theme** (the act's boss melody in its cold colour), **warm** (the counter-melody: the motif's
  Warm form in the act's warm lead, entering **below 50% boss health**: the player is winning).
- **Signature layer per boss** (`mus_boss_act<N>_sig_<enemy id>`, e.g. `sig_old_stag`, Night Mare laps `sig_night_mare_2` / `_3`; part of the act's boss set, so they loop in sync), on top of its act's theme while it lives:

| Act | Boss | Signature layer |
|---|---|---|
| 1 | The Hollow Stag | a low, slow **horn-like bowed call** + soft wooden antler knocks on the off-beats |
| 1 | The Night Mare | a **galloping hoof rhythm** on felt drums (the 6/8 fits it); **each lap adds one more layer of it** (a second rhythm, then a low drone), so its laps sound like it's speeding up without the tempo changing |
| 1 | The Scarecrow | a **crooked waltz** on a slightly detuned music box + a soft fluttering wingbeat figure (no caw) |
| 2 | The Mire Hag | bubbling **low reeds** and a lurching, off-balance figure |
| 2 | The Huntsman | a deep **bone-horn call** every 4 bars (low, soft, brass-like) + a running pack rhythm on low toms |
| 2 | The Lamplighter | a slow, cold **organ-like pad** with a soft flicker tremolo; each lantern lit adds one soft held note, snuffed = it drops |
| 3 | The Moth Queen | **tremolo shimmer** (soft bowed, low) over slow wingbeats |
| 3 | The Barrow King | a heavy **processional**: a slow, dragging low drum on the downbeat only, bowed bass dragging behind the beat; muffled iron (lowpassed, rounded), no clank |
| 3 | The Mourning Mother | a **weeping descending line** on bowed saw + a low hummed lament (one vowel, never speech-like); while she mends, the line hangs on one note |
| 4 | Hollow Oak: Thorned | a tightening figure of soft wooden taps that gets denser as saplings spread |
| 4 | Hollow Oak: Withering | a layer that **removes**: the finale's warm notes drop out one by one while it withers Wardens, returning after |
| 4 | Hollow Oak: Remembering | at 75 / 50 / 25 %, the **signature layer of the echoed boss** returns for that echo's life (a fragment, quieter, filtered "from inside the bark") |

- **The Hollow Oak finale** (`mus_boss_oak_*`, its own full track): deep wooden drums and a hummed
  drone, the act 4 bells, the Hollow form of the motif at its heaviest. Below 50 % the warm
  counter-melody enters **in full choir**. When it falls: hard stop, the boss dispel bloom, then the
  **Hope form** of the motif played whole, the only time the game plays it at full length, into the
  win.

### Transitions

- **Crossfades land on bar lines** (rest, drift and boss all use 2.5 s or 3 s bars; crossfade over one
  bar of the outgoing piece).
- **Drift → rest:** on the **last dispel of the block**, the dread layers fall away within a bar, the
  base plays a **1–2 bar resolving tail** (to a held D chord), then the rest piece fades in.
- **Rest → drift:** on Start, the rest finishes its bar, then the drift base enters on the next bar.
- **Drift → boss:** when the boss drift starts, the boss drums enter on the next bar line under the
  last drift layers, then the full theme.
- **Boss dispelled:** a hard stop, the boss dispel sound, then the **Hope form** of the motif (2–4
  bars) in the act's warm lead, then the rest. A boss that **reaches the Heartwood** (act bosses take
  their bite and leave) cuts the drums for a bar on the bite, then the theme returns, colder (warm layer off).
- **Act break:** the act_started swell, then the next act's rest piece.
- **Loss:** the loss stinger; **win:** the Oak finale's Hope form, then the win stinger.

### Build order (Sound Code)

1. **Act 1 set:** the act 1 rest piece, the act 1 drift (16 bars, 4 stems), the act 1 boss theme
   (4 stems) + the three act 1 signature layers (Stag, Night Mare, Scarecrow). Render, then send to
   the story chat for the user to hear.
2. Acts 2–3 rest + drift + boss themes and their signatures.
3. Act 4 rest + drift, the Hollow Oak finale with its 3 signature layers.

## Marketing music (2026-10-04; brief in marketing.md §9)

Same world as the game: D minor, the game's instruments, the **Heartwood motif**, rounded and never
sharp. Every cue ends **on** the end card with the motif's **Hope form**. Each cue is delivered as WAV
**stems (low / mid / top / percussion), a full mix, and a voice mix** (the full mix with 300 Hz–3 kHz
thinned by ~6 dB, for voiceovers). Made in-house: no copyright claims.

### Tempo (answer to Marketing and Trailer)

**Keep 72 bpm, 3/4 (bar 2.5 s).** It's the game's own pulse, and every trailer hit (7.5, 20, 52.5,
65 s) and section edge already lands on a downbeat. Energy rises without changing tempo: **density
and subdivision** (the pulse moves from dotted halves to quarters to eighth-note figures), **register**
(the bass drops an octave at the boss section), and **percussion** entering in layers.

### The end-card button (~1.5 s, on every short and the trailer)

The motif's **Hope form**: **D – A – F♯** on harp and music box together (quarter-note-ish, ~0.4 s
apart), landing on a soft, warm **D major chord** that rings ~0.7 s. Same notes every time, so the
series has a sound. It's the in-game motif turned hopeful, so players hear it again in the game when a
boss falls.

### 1. Trailer cue (~75 s = 30 bars at 72 bpm)

| Bars (time) | Picture | Music |
|---|---|---|
| 1–2 (0–5 s) | maze built, Warden snaps | the motif alone on music box, soft and warm; a felt pulse on each beat (the snaps sit on it) |
| 3–4 (5–10 s) | Shade close-up | **near-silence**: one cold low note (the Hollow form's A♭ in bowed bass); **hit at 7.5 s** (bar 4 downbeat) = the dispel bloom, then silence |
| 5–6 (10–15 s) | drift walks the maze | the pulse returns (quarters), dread1's drone underneath |
| 7–11 (15–27.5 s) | Soaked + Charged, Thunderclaps | building: percussion enters in layers (low toms, then frame drum); **hit at 20 s** (bar 9) = a warm boom + far thunder roll, the Thunderclap |
| 12–15 (27.5–37.5 s) | rest: Dream pick, grow, Kinship | **a breath**: half the density, the rest piece's harp and the motif's warm form, no percussion |
| 16–18 (37.5–45 s) | Sow a Ridge | rising again: a slow swell, the pulse back in eighths, the bass climbing |
| 19–24 (45–60 s) | bosses | the **act 1 boss theme** (drums, bowed bass an octave lower, the Hollow form) with the Stag's horn call; **hard stop at 52.5 s** (bar 22 downbeat) on the Stag stalling, a bar of only a low drone, then the Night Mare's gallop and the Oak's drums build back |
| 25–28 (60–70 s) | storm chain to Dawnburst | everything: the boss drive + the warm counter-melody in full + the Hope form building; **hit at 65 s** (bar 27) = the Dawnburst, the biggest moment |
| 29–30 (70–75 s) | logo, Wishlist | the **end-card button** (Hope form) resolving into **one held warm D major chord** from 70 s to the end |

### 2. Short beds (9:16, ~15–35 s)

Each starts at **full presence from frame 1** (no fade in) and ends on its end card with the button.
The cut lists' hits don't fall on bars, so each bed is **rendered per short** to its own timeline:
- the bar grid is **offset** so the bed's **main hit lands on a downbeat** (start offset = main hit
  time mod 2.5 s; the bed starts mid-bar if needed, at full presence);
- the other hits are **accent stingers** placed at their exact times, on a separate **hits stem**,
  so the editor can nudge them if a cut moves;
- the rise into the main hit spans the bars before it; after it, the bed settles and lands the button
  on the end card.

| Bed | Mood | Used by (hit times from Short Form Video, 2026-10-04) |
|---|---|---|
| **Build** | warm, steady pulse, rising as the maze grows | short 1 (28 s): snaps from 2.0 as a soft pulse, Sporelings 9.0, **main hit 12.0** (drift starts), push-in 14.0, follow 16.5. Short 4 (22 s): drift 1.0, **main hit 6.0** (the ridge rises), follow 12.0 |
| **Storm** | tension into a hit on the chain | short 2 (24 s): drift 0.5, crowd 8.5, **main hit ~10.7** (×22 + Dawnburst). If the ~2.5 s slow motion stays, hold a suspended swell from 10.5 to 13.0 and land the hit as it ends |
| **Boss** | the act 1 boss theme + the Stag's signature | short 3 (30 s): dossier 0.2–2.3 (a held low drone under it), the Stag 2.5 (drums in), **main hit ~27.0** (dispelled; ±0.6 s, so render after the final dry run) = the boss dispel bloom + Hope form |
| **Close call** | the heartbeat thinning to near-silence, one release | short 5 (~19 s): "one leaf left" 0.0 (the heartbeat alone), Husk 1.0 (dread1 under it), jump cut 9.0 (a hard cut in the bed too: a bar of near-silence), **main hit ~16.3** = the release (the dispel bloom, then the button) |

### 3. Video 0 ("why I made this", 34 s, voice mix only)

Gentle and warm: the **act 1 rest piece** (harp, music box), thinned for the voice. First snap 0.5 s on
a soft pulse; the Dream screen 9.0–11.5 (the pulse drops away); the Puffball grow 13.5 (a soft swell);
**the lift at 20.0 on "So I made one."**: the drift base enters under the pull-back, the motif's warm
form in full; another island 23.0; the chain peak ~28.1 as a gentle warm swell (not a hit, it's a
voiceover); the **end card 29.0–34.0**: the button, then the held D major chord to 34.0.

### Delivery (Sound Code)

Per cue: `marketing/<cue>_full.wav`, `_voice.wav`, `_low.wav`, `_mid.wav`, `_top.wav`, `_perc.wav`
(+ `_hits.wav` for the shorts), 44.1 kHz stereo is fine here (it's not positional). Cues: `trailer`,
`build_short1`, `build_short4`, `storm_short2`, `boss_short3`, `closecall_short5`, `video0`, and
`endcard_button`. Re-render a short when its hit times change (they're parameters, not hand-placed).

## Sound effects

### Nightmares (signature sounds)

| Nightmare | Moving | Special |
|---|---|---|
| **Shade** | soft, muffled skittering (low taps, no hiss) | — |
| **Husk** | creaking bark, heavy steps | — |
| **Mourner** / Sob | faint sobbing | breaking into Sobs: a soft, detuned low chime + small sniffles |
| **Phantom** | breathy whoosh, reversed choir | passing through a wall: a muffled whoosh (a warning cue) |
| **Night Hound** | low growl | sprinting: fast padding; a short howl the first time a pack sprints |
| **Procession** | distant chain-clink and a slow drum | Lantern Bearer dispelled: the Wraiths' confused whispering |
| **Lurker** | only a faint positional whisper until revealed | revealed: a sharp intake of breath |
| **The Hollow Stag** | deep bellow, a low roaring hush of ghost-fire | trampling: a heavy wooden collapse (low, no splinter crackle); charge: a roar |
| **The Mire Hag** | wet gurgling laugh | sinking: bog bubbles; rising: a splash |
| **Deeply Blighted** | its normal sound, pitched down, with a low haze drone | — |

### The dispel (the most important sound in the game)

Three parts, about 0.5 s, all rounded (revised after the second listen: the shriek and the crackle
were too sharp; revised again on 2026-09-30: it sounded like **thunder or lightning**).

**It must never sound like weather.** Low booms and falling, rumbling noise are the **storm
vocabulary**, reserved for the light family (Thunderclap, Thunderhead, Stormheart, the Crowned
Tempest). It lives in the mid range (~250 Hz–2.5 kHz) with **no sub or low boom** and **no downward
noise sweeps**.

**A soft burst of light, releasing a soul** (sixth listen, 2026-09-30). **Approved by the user ("sounds good now", build 2241bf41): keep it; change it only if they ask.** The fifth listen asked for
"releasing a soul"; the sung-vowel version **sounded like talking**, so there is **no voice at all**:
no vowels, no formants, no sighs, no pitch glides (vowel changes and glides are what make a sound
read as speech). Every nightmare is a dream the Hollow twisted; dispelling it sets that dream free
and its motes drift up (story.md). The sound is that **light opening and drifting away**: soothing,
airy, warm. About 0.8 s, the second half very quiet.

- **Material: tuned air.** Soft breathy noise shaped by narrow resonances tuned to the notes of the
  D chord (D, F#, A), so it glows with a pitch without being a tone, a bell or a voice. Think of a
  warm, breathy pad or light through mist, not an instrument.
- **Shape:** a gentle **gathering** (a soft reversed swell of that tuned air, ~0.15 s, the shadow
  letting go) → the **bloom** (the tuned air opening wide and warm: filter opening, a slight stereo
  spread) → it **drifts away** (thins out and fades over ~0.5 s). Soft onset, no transient, no pitch
  movement.
- **Cold to warm, without a voice:** the first ~0.1 s of the gathering is slightly out of tune and
  darker; it settles into the warm chord as it blooms. That's the soul turning from nightmare to dream.
- **Not the Firefly Jar:** the light family's hit is a short *fwump* with low body; the dispel has
  **no low body**, is tuned, airy and wider, and lasts longer.
- **Never:** a bell, chime, tinkle or sparkle; a voice; a sweep; a boom.

- **Many at once:** they blend into **one wider, warmer glow** (voice-limited, each quieter), never
  stepping up in pitch (no climbing combo).
- **Deeply Blighted:** a slower gathering and a fuller bloom (more resonances, the chord a little lower).
- **Bosses:** the stolen memory set free: the boss's own dispel, then a **large, slow bloom of
  light** (the tuned air across the whole chord, several seconds) opening into the Memory moment.
  Still no voice or choir.
- **Its opposite is the leaf lost** (the dream being taken): keep that one falling, cold and hollow,
  so the two read as a pair.

- **No music duck on normal dispels** (they're frequent; ducking on every kill pumped like a
  thunderclap). Only bosses, lost leaves and the big moments duck.
- **Size** changes the voice (bigger nightmares: a lower, slower sigh), never adds low end.

**Not a reward sound.** A dispel sounds like a nightmare ending, never like getting paid:
- **No climbing combo.** When several dispels land close together they blend into one fuller, softer
  swell (voice-limited, slightly quieter each), not a rising run of notes.
- **No Dew sound per kill.** The "+N Dew" popup is enough. Dew makes a sound only for big lump sums
  (the rest bonus, Omen rewards): a soft, low rustle of light, never a tinkle, bell or coin.
- Randomise pitch slightly.

### Wardens (warm, not weak)

**Organic, never chiptune** (third listen: the Sprout's shot sounded like "pixel murmur"; the Firefly
Jar was fine). Shots and hits sound like real materials: air, wood, stone, water, breath, earth.
This matters most for the Sprout: it's the starting Warden, so its shot is the most-heard sound in
the game. Apply the rules below to it now, and to every new Warden sound:
- **No pure oscillator tones** (sine, square, saw) as the main sound of a shot, and **no pitch sweeps**
  (the rising "bloop" droplet, laser glides). Those read as 8-bit.
- **No plucked or music-box tones** on shots; melody belongs to the music, not to combat.
- Synthesized placeholders are built from **noise shaped by material resonances** (several
  inharmonic resonant bands for wood or stone, filtered noise for air and water), never tones.
- **Final sounds are recorded foley** (or licensed foley libraries), layered and processed to fit.
  Synthesis is only a stand-in for combat sounds.

Every attack has **two parts**: a very quiet **launch** when the Warden fires (mostly air: a soft
*whff*, a sling's rush, a breath), and a **hit** when it lands. The hit carries the impact. It's
built in three layers:

- **Onset** (first ~10 ms): a rounded *tock* in the 300–900 Hz range with a 3–5 ms fade-in. It
  gives the hit its edge without stinging. (Revised: the first version asked for a 2–4 kHz snap, which
  was too sharp.)
- **Body** (~10–150 ms): a low thump, 60–150 Hz depending on the family. This is the weight, and the
  main thing that makes a hit feel strong.
- **Tail** (up to ~300 ms): the family's colour, quieter and lowpassed (below ~3 kHz).

| Family | Launch (quiet) | Hit (the impact) |
|---|---|---|
| Sporeling (spore) | soft pop + breath | a full, round "puff" with a soft low thump |
| Pebbling (stone) | sling whip | **heavy thud**: a hard wood/stone crack over a deep body |
| Dewdrop (water) | a drop falling | **splash**: a sharp droplet snap, a low "plunk", a spray tail |
| Firefly Jar (light) | a warm glow swell | a **warm bloom**: a soft *fwump* of light with a low body, no crackle; chains ripple a softer bloom down the line. **Approved on the third listen: keep.** |
| Rootling (root, pulse) | — (the pulse is the hit) | a **ground boom**: wooden knock + deep sub rumble, felt more than heard |
| **Sprout (neutral)** | a small leafy flick of air (no pluck) | a light wooden **twig tap**: noise through a couple of woody resonances, a soft low thump, no tone. **Revised on the third listen**: the plucked-tone version sounded like chiptune |
| Acorn aura | — | a soft chime when a neighbour is buffed (rare, not every tick) |
| Crit | — | the normal hit + an extra low punch + a soft, low bell (not a high ping) |
| Sunpetal / Midsummer beam | — | a warm hum that climbs in pitch as the beam ramps; no sizzle |

- **Weight by target:** hits on tanky or big nightmares (Husk, Barrow Wight, bosses) are pitched a
  little lower and fuller; hits on small ones (Sob, Creep, Wraith) lighter and higher.
- **Resisted / weak** (the grey puff / sparkle): resisted hits are dulled (softer onset, less body);
  weak hits are **fuller and louder** (more body, a little longer), not brighter. The player hears
  the matchup.
- **Level:** hits sit about 6 dB above where the first placeholder attacks sat (they were at −9 dB and
  far too quiet); launches stay low. Voice limiting (see Mix rules) keeps a full maze from turning to mush.

### Warden sound sheet (every Warden, 2026-09-27)

Every Warden gets its **own** launch and hit (ids `attack_<warden_id>` / `hit_<warden_id>`, falling
back to the family's sound when a file is missing). All of the rules above apply: rounded, organic,
foley-like, no chiptune.

**Rules for the sheet**
- **Family = material.** You can tell the family with your eyes closed: spore = air and soft fungal
  puffs; stone = rock on earth; water = real water; light = warm air and glow (the approved Firefly
  Jar sound is the template); root = earth and creaking wood; song = soft low bells and hums;
  acorn = wood and bark; wing = feathers and wingbeats; wind = moving air and spinning wood.
- **Tier = size.** A branch is the base sound grown fuller (more body, longer tail). A final form
  adds **one signature layer** only it has (listed below), so reaching it is a moment you hear.
- **Loudness × rate stays even.** A Warden that fires 6 times a second (Hummingbird) gets a tiny,
  near-subliminal peck. A Warden that fires once every 3 s (Standing Stone) gets a big, full hit.
  No Warden may dominate the mix by rate.
- **Song is the only tonal family.** The Bellflower line are bells, so they may be pitched. They
  stay low (D3–D5), soft-mallet, in the music's key (D minor pentatonic), and never form a melody
  (random notes from the chord, not a tune).
- **Continuous things loop quietly** (beams, auras, fog, spinning blades): a soft bed that fades in
  when active and out when idle, one voice per Warden type, never per tile.
- **Evolving** plays the evolve bloom, then the new form's hit once as a "first breath".
- **Final Bloom** (the first grow into each final form per run; `final_bloomed`, with gold rings and
  the name callout): the evolve bloom, then a **warm harp strum** in the music's key (the music's own
  instrument, so it feels like the score answering) over a slow swell of the **family's material**,
  then the new form's signature layer once. ~1.5 s, music ducks ~3 dB for 0.5 s. Later grows into the
  same form that run use the normal evolve. Not a chime, a choir or the dispel's tuned air.

**Starters**

| Warden | Launch | Hit / event |
|---|---|---|
| Sprout | a small leafy flick of air | a light wooden **twig tap** (noise through woody resonances + a soft low thump; no tone) |
| Thornwall | — | planting only (see Building); no attack |
| Bramble | — | nightmare brushing past: a dry, low **thorn scrape** on the damage tick (throttled per wall run) |
| Honeysuckle | — | a soft, sweet **floral sigh** when it adds Drowsy (rare; throttled) |

**Sporeling line** (spore: soft fungal air)

| Warden | Launch | Hit / event |
|---|---|---|
| Sporeling | a soft breath out | a round **puff** (air + soft low thump) |
| Driftspore | a longer, drifting breath | a double puff, the second smaller (2 stacks) |
| Puffball | a soft breath | its puff **bursts on landing over a tile**: a wide, soft *fwoomp* of spores spreading (the area poisoner). **No pop** (spores no longer pop, tower_design.md) |
| Bloomcap | a heavy mushroom-cap *thup* | cloud forming: a slow, sleepy **exhale** that settles |
| Dreamshroom | same, deeper | cloud + signature: a low **yawn-like drone** when a nightmare falls asleep |
| Fairy Ring | — | ring appearing: tiny soft earth pops. Triggered: a **spore burst** (puff + low thump) |
| Elf Circle | — | ring appearing: a faint low **hum** under the pops (signature). Triggered: bigger burst |

**Pebbling line** (stone: rock on earth; the heaviest family)

| Warden | Launch | Hit / event |
|---|---|---|
| Pebbling | a sling's short rush of air | **stone thud** on packed earth, deep body |
| Mossback | a heavy wind-up grunt of stone | a **huge muffled thud**, the heaviest single hit in the game; moss softens the top |
| Boulderback | same, lower | thud + signature: a short **ground rumble** that spreads (the splash) |
| Standing Stone | a long, low **whoom** of a stone slinging far | a deep, distant **crack of stone on stone**, lowpassed (it hits far away) |
| Moonstone | same + a faint cool shimmer of air | hit + signature: the first-hit crit adds a low, **glassy bell-stone ring** (soft, D3) |
| Cairn | a stone lifted and **lobbed**: a low grunt + an arcing air rush | a **mortar thump**: stone landing among many, a scatter of pebbles (low, soft) |
| Rockslide | same | thump + signature: a rolling **rubble settle** that fades over ~1 s |

**Dewdrop line** (water: real water)

| Warden | Launch | Hit / event |
|---|---|---|
| Dewdrop | a faint drip of air | a small **water slap** with a low plunk (no rising "bloop" tone) |
| Rain Lily | a fuller drip | a bigger splash, a wide spray tail |
| Monsoon *(not built)* | — | rain on everything in range: a soft **downpour burst** (1 s), signature low thunder-roll far off |
| Mistveil | a soft hiss-free exhale of damp air | fog forming: a low, damp **settle**; fog loop = a very quiet cold breath |
| Morning Fog *(not built)* | same | fog loop fuller and sleepier (a faint low hum under it) |
| Frostfern | a small cold breath | a splash that **stiffens**: water slap + a soft, low **ice creak** (freeze) |
| Hoarfrost | same, colder | splash + signature: a deep, slow **frost groan** as ice spreads (no sparkle, no crackle) |

**Firefly Jar line** (light: warm air and glow; Firefly Jar approved as the template)

| Warden | Launch | Hit / event |
|---|---|---|
| Firefly Jar | a warm glow swell | a warm **bloom** (approved; keep) |
| Stormcap | a heavier swell | bloom that **ripples** down the chain: each jump quieter, slightly lower |
| Thunderhead | same | ripple; every 5th strike = signature: a soft, distant **thunder roll** (low, no crack) |
| Lanternmoth | soft **moth wings** | a warm bloom with a faint glow hum (Marked) |
| Beacon *(not built)* | — | marking everything: a slow, warm **swell** like a lamp turning up |
| Sunpetal | — | beam loop: warm, airy hum like sunlight through leaves, **swelling** with the ramp |
| Midsummer | — | beam loop fuller; signature: a second, lower hum layer when it hits the one behind |
| **Static bolt** (any Warden's Charged / Static discharge; `bolt_strike`) | — | a soft, rounded **zap** in the light family's warm material: a tiny bloom + an air flick, no crackle or buzz; −10 dB, throttled 150 ms. Smaller than the Firefly Jar hit, and never a rumble (thunder stays with Thunderclap and the finals). From the story chat's spec, built f61256f8 |

**Rootling line** (root: earth and creaking wood, felt more than heard)

| Warden | Launch | Hit / event |
|---|---|---|
| Rootling | — (the pulse is the hit) | a **ground boom**: roots shifting in earth + deep sub rumble |
| Rootcurl *(not built)* | — | the pull: a long **wooden creak** + earth dragging |
| Long Way Home *(not built)* | — | pull + signature: a deep, slow **heave** of roots (3 tiles) |
| Tangleroot *(not built)* | — | the hold: roots **snapping tight** (a low wooden clench, no crack) |
| Snugroot *(not built)* | — | same, three at once, overlapping softly |
| Rootlight | — | tiles lighting: a low, warm **earth glow** swell; lit loop = a very faint warm hum |
| Starcave | — | same + signature: a faint, deep **cavern resonance** under the hum |

**Bellflower line** (song: soft low bells and hums, the one tonal family)

| Warden | Launch | Hit / event |
|---|---|---|
| Bellflower | — | a soft **bell pulse** (low, felt mallet, D4 area); every 2nd pulse a slightly sleepier, lower one (Drowsy) |
| Chime Stone | — | a low **stone chime**, duller and rounder than the bell |
| Lullaby Bell | — | a deep bell with a long hum tail; signature: a faint **hummed voice** under it |
| Dreamcatcher | a soft **thread and feather** rustle as it hangs | Caught: a low, woven **thrum** |
| Great Dreamcatcher | same | thrum + signature: a warm, muffled **shimmer** when a Caught nightmare drops a Dreamlight shard |
| Echo Hollow | — | an echo: the original Reaction's sound, **repeated 1 s later, softer and hollow** (lowpassed, from inside a log) |
| Whispering Hollow | — | same, 75%; signature: a faint **whisper** in the echo (the good kind: warm, low) |

**Acorn line** (wood and bark; support, so quiet)

| Warden | Launch | Hit / event |
|---|---|---|
| Acorn | — | a soft **woody knock** when a neighbour is buffed (rare) |
| Elder Stump *(not built)* | — | a deeper knock, rare |
| Grove Heart *(not built)* | — | a slow, warm **wooden heartbeat** when its bonus grows (rare) |
| Dewcatcher *(not built)* | — | at the drift's end: a soft **pour of water** into a cup (the Dew; one per rest, not per drift start) |
| Wellspring *(not built)* | — | interest paid: a slow **welling-up** of water, low and soft |
| Graftling | — | sounds like the Warden it copies, **muffled through bark** (lowpassed, a little softer) |
| Grafted Elder | — | same, less muffled (85%) |

**Nestling line** (wing: feathers and wingbeats; full game)

| Warden | Launch | Hit / event |
|---|---|---|
| Nestling | a short **wing flutter** | a soft feathered **strike** (a muffled thump) + the flutter home |
| Wren's Nest | quicker, lighter flutter | a smaller, quicker strike |
| Starling Murmuration | a **flock whoosh** (many wings, soft) | strikes land as a soft, overlapping patter (3 targets) |
| Magpie Perch | a heavier wingbeat | a strike + a faint **caw-less** beak tap |
| Magpie's Hoard | same | crit that pays Dew: a tiny, soft **clutter of trinkets**, low (never a coin, never a bell) |
| Hummingbird Bower | a very fast, **quiet wing hum** | pecks: tiny soft taps, near-subliminal (6 per second) |
| Jewelwing Court | hum from three birds | pecks as above; signature: the Flurry crit (every 6th) is a slightly fuller tap |

**Whirligig line** (wind: moving air and spinning wood; full game)

| Warden | Launch | Hit / event |
|---|---|---|
| Whirligig | — | a soft **gust** (low air push) that nudges |
| Gust | a spin-up of air | statuses copying across: a soft **air swirl** between the targets |
| Zephyr | same | swirl + signature: a longer, sighing **breeze** as it spreads to 5 |
| Pinwheel | — | blades loop: a soft, low **wooden whirr**; hits are soft air cuts, one per sweep |
| Windmill | — | bigger, slower whirr; signature: a low **creak of the mill** each turn |
| Samara | a spinning **maple seed whir** leaving | the pass-through hit: soft air cuts; the catch: a light **wooden clack** |
| Autumn Gale | two seeds | same; signature: a rising (in volume, not pitch) **gust** as the catch rhythm builds |

**Memory Wardens** (unique; each a small signature moment)

| Warden | Sound |
|---|---|
| The White Stag | aura loop: a very faint, warm, **breathing presence**; placing it: a soft, distant antler knock + warm swell |
| The Pond Keeper | the grab: a wet **tongue flick** (soft, low), a drag through water, a gentle plop beside the pond |
| The Moon Moth | a slow, soft **wingbeat**; its long shot: a cool, soft air rush and a muffled glow bloom |

**Ascended Wardens** (endgame, from drift 51; one per family, "a huge, unique presence")

Rules: each is **its family's material at its biggest**. Their big periodic events (every 3–6 s)
are the **loudest Warden sounds in the game**, just under a boss, and they briefly duck the music
(~3 dB, 0.5 s) like a small boss moment. Between events, a **very quiet presence loop** (one per
Warden) so you feel it's there. **Ascending** (growing into one) is its own moment: the evolve
bloom, then a slow, deep swell of the family's material, then its first event. Still rounded and
organic: big means low and wide, never bright or harsh.

| Warden | Presence loop | Event (the big sound) |
|---|---|---|
| **Sporemother** (spore) | a slow, deep **fungal breathing** | the storm: a soft, continuous spore wind that thickens as more nightmares are in it (Poisoned never wears off inside). **No pop** |
| **Tidecaller** (water) | distant, low **surf** | every 6 s the tide: a **wave** rolling along the path (a long, low water swell, panned along the stretch it covers) and a heavy wash as it pushes nightmares back |
| **Stormheart** (light) | a warm, low **storm hum** | chaining to everything: one big warm **bloom** with a rolling, far **thunder** under it (not one sound per jump; a single swell that grows with the number hit) |
| **Old Mountain** (stone) | a very low, slow **earth groan** | every 3 s a boulder: the heaviest **thud** in the game, a deep ground shake and a short rubble settle |
| **World Root** (root) | a faint **deep creak** of huge roots | every 5 s the hold: a vast, low **root heave** under everything in range (sub boom + slow wooden groan), felt more than heard |
| **The Great Bell** (song) | silent between tolls | every 6 s the **toll**: one deep, soft bell (D2–D3, felt mallet, long hum tail). If Static goes off with it, a soft warm bloom under the tail, not one sound per charge |
| **Grandmother Oak** (acorn) | a slow, warm **wooden heartbeat** and leaves stirring very low (no rustle hiss) | the Dew per drift: a soft **welling** of sap (never a coin, never a bell) |
| **Dawnwing** (wing) | great, slow **wingbeats** circling, panned as it moves | each strike: a soft, heavy feathered **thump**; when it speeds up (many nightmares), the wingbeats quicken, not the strikes' volume. How: two synced wingbeat loops (calm and busy) crossfaded by the number of nightmares in its path, not a sped-up recording (that would raise the pitch) |
| **The Tempest** (wind) | the cyclone: a low, rotating **wind roar** that follows it along the path | carrying statuses: soft **swirls** as it passes each nightmare (throttled). *Name clash:* the Crowned Reaction **Tempest** (dream_design.md) needs its own sound, a Thunderclap + Ignite, and the two should never be confused; consider renaming one |

**The Heartwood Sapling** (economy, from drift 51; no attack)

| Moment | Sound |
|---|---|
| Offered (its card) | the family bell's warmth without the bell: a slow, warm swell and a soft breath |
| Planted (2×2) | a big **rooting**: deeper and slower than a Warden's plant, the earth settling around it |
| Yield at each drift's end | a soft **welling of sap** (the same family as Grandmother Oak's, smaller). Never a coin |
| Dreamlight ripening | a slow, warm **glow swell** with a faint hummed note in key |
| Withering (a leaf lost) | a low, dry **creak** after the leaf-lost sound (soft, not a crack); recovering at a rest: a warm exhale |
| Nurture ranks | the Nurture sound (see Building) in sap and wood, a little deeper each rank like any Warden |

### Reactions (status combos; tower_design.md "Reactions")

Reactions are the **payoff** the player builds toward, so each gets its own sound, louder than a
Warden hit and under a boss. The design line is "warm light breaking cold shadow": each Reaction is
the **two statuses' materials meeting**, resolving warm. Still rounded and organic (no crackle, no
zaps, no sparkle).

- **One sound per Reaction event**, never one per target: a Thunderclap arcing to 8 nightmares is one
  sound whose size grows with the count (as with the Great Bell).
- **Throttled per Reaction type** (~0.15 s) and voice-limited, so a chain reads as a rolling swell.
- **Bosses:** same sound, the boss's reduced version plays a little smaller.

| Reaction | Statuses | Sound |
|---|---|---|
| **Thunderclap** | Damp + Static | a warm **bloom** (the Firefly material) bursting through water: a soft wet *whumpf* + a low, rolling far thunder; size grows with the arcs |
| **Ignite** | Spored + Static | the spores going up at once: a deep, soft **fwoomp** of warm air (a gas-flame whoosh, lowpassed), no fire crackle |
| **Mushrooming** | Spored + Damp | wet earth **bursting**: soft, fleshy mushroom pops (low, rounded) + a damp spore exhale for the cloud |
| **Shatter** | frozen/Held + Damp + a heavy hit | the ice **giving way**: a deep, muffled ice *thunk* and a low slide of shards settling (no glassy tinkle) |
| **Drown** | Damp + max Drowsy | a slow, soft **sink**: a low water gulp and a sleepy exhale bubbling away |
| **Pinned** | Marked + Held/Drowsy | a low, tight **held breath**: a soft wooden clench + a faint glow hum, so the player hears "the next hit counts" (the ×3 crit itself is the normal crit, heavier) |
| **Smother** | Held + Spored | a muffled, low **smothering** hum while it lasts (a quiet loop, one voice per type), the spore breath pressed tight |
| **Lightning Rod** | Marked + Static | a warm **pull**: the glow material drawn in (a soft reversed swell) landing as a low bloom on the Marked nightmare |

**Chains** (a Reaction set off by another within 1 s)
- Each link is **fuller and warmer, never higher**. Chain 2–4: the Reaction's own sound with a
  little more body and a soft warm swell under it that builds link by link. **No rising chime, no
  climbing pitch**; that reads as coins (third listen). The chain badge's "rising chime" in
  tower_design.md should become this building swell.
- **Chain 5 (surge):** a short **warm swell** with a soft low boom; the music ducks ~3 dB for 0.5 s.
- **Chain 10 (Dawnburst):** the biggest non-boss moment in the game: a deep, warm **boom of light**
  (sub + a wide soft swell), the music ducks ~8 dB for 1 s, then a **short warm music stinger** in key
  (a sustained D major chord in the warm instruments, 2–3 s), then the music returns.
- The **first chain ever** (its whisper) gets the Dream-screen "breath in" under the whisper.

**Crowned Reactions** (a Reaction + a third status; full game only, gold impact tier)

Each is the base Reaction's sound **plus a crown layer**: a slow, warm, low **choir-like swell**
(hummed "ooh", in key) shared by all eight, so the player learns "that was a Crowned one", then the
Crowned's own signature. Close to an Ascended event in size; music ducks ~3 dB for 0.5 s. They count
as 2 chain links for the chain swell too.

| Crowned | Signature layer |
|---|---|
| **Tempest** | the storm feeding itself: Thunderclap's far thunder **and** Ignite's fwoomp rolling into each other as one long, rumbling swell (its 2 s cap keeps it from droning). Must never sound like the Whirligig's Ascended "The Tempest" (a wind roar) |
| **Still Pool** | a deep, glassy-calm **water hush** as the pool forms; the pool loop is near-silent still water; a walker sleeping in it: a soft sinking sigh |
| **Fever Dream** | Smother's hum releasing at once into a warm, dizzy **exhale** that spreads (a slow, wavering sigh passing to the neighbours) |
| **Starfall** | the Static bolts **drawn in**: several soft reversed swells converging, then a column of light landing as the deepest warm **boom** of the Reactions. The boss killer should feel like it |
| **Avalanche** | the lob's landing **spreading**: a rolling ice-and-stone **rumble** moving outward (low, no tinkle) |
| **Prismstorm** | Shatter's ice thunk + warm blooms **scattering** outward with the shards (soft, overlapping, low) |
| **Nightbloom** | a violet **lullaby hum** as the cloud glows (two low sung notes in key, very soft); the cloud loop is a slow, sleepy breath |
| **Fairy Circle** | a ring of soft mushroom **pops around** the nightmare (8 quick, soft, panned in a circle); the ring loop is a faint low hum |

**Discovery cards** (first time a Reaction, Crowned or chain goes off): the Dream-screen breath in and a
soft shimmer under the card. Crowned discovery adds the crown's choir swell.

**Delivery rules** (small, rare sounds)

| Rule | Sound |
|---|---|
| Grafted Harmony (a Graftling applying two statuses) | its copied hit, muffled through bark, with **both** statuses' materials faintly under it |
| Storm Front (a Gust-carried Reaction) | the Reaction's sound wrapped in a soft **air swirl** |
| Carried Storm (a Samara seed carrying a Reaction) | the seed's whir **coloured** by the Reaction's material, and the Reaction at 50% on each nightmare it passes (throttled) |

### Building and the map

| Action | Sound |
|---|---|
| Plant a Warden | earth rumble + wood creak as the roots rise |
| Evolve | a rising bloom chime |
| **Nurture** (rank up) | a soft, rising **swell of the Warden's own family material** (spore breath, stone settling, water welling, warm glow, root creak, low bell hum, bark, wingbeat, gust), ~0.6 s, ending in a gentle settle. **Each rank is a little deeper and fuller** (about −1 semitone and a touch more body per rank, rank V/VII the fullest). Quieter and shorter than Evolve: it's frequent. |
| Nurture: choosing a Focus (rank III) | the nurture swell + a short **leaning** of the material toward the Focus: Power = heavier body, Swift = a quick double pulse, Reach = a longer airy tail, Deep = a lower, slower settle |
| Nurture a group (G / R on a selection) | the swells **stagger** with the visual bloom (nearest the Heartwood first), voice-limited so ten Wardens read as one rolling swell, not ten |
| Sell | roots withdrawing into the ground |
| Invalid placement | a muted wooden knock |
| Tend a Withered Tree / move a Mossy Boulder | a soft creak and a low wooden settle / low stone rumble |
| Route changes | a faint shimmer as the path line redraws |

### The Heartwood

| Moment | Sound |
|---|---|
| **Leaf lost** | the nightmare's lunge (dark, low whoosh), the tree groaning, a deep hollow knock as the leaf falls. Cuts through by level and ducking, not brightness |
| Low leaves (≤5) | the heartbeat layer in the music |
| Act break, leaves regrown | a warm swell, leaves rustling |

### UI

Dream screen opening: a breath in and a shimmer; card reveal chimes by rarity (Common a soft
note, Rare a hummed choir, Legendary a full choir chord). Family pick: a deep warm bell. Omen: wind.
Rest starting: the music exhales and the ambience calms. Buttons: soft wooden clicks.

### The Remember screen (unlocking Wardens with Dreamlight, 2026-09-30)

Unlocking a Warden here is **the Heartwood remembering one of its guardians**. It should feel like a
memory coming back: warm, a little magical, and clearly bigger than a button click. It's also the
sister of the dispel: there a twisted dream is set free, here a lost one comes home.

| Moment | Sound |
|---|---|
| Open the Remember screen | a slow **breath in**; the music muffles like other choice screens |
| Select / tap a node | a soft woody tap (like a button, a little warmer); no hover-only sound (touch) |
| Can't unlock (not enough Dreamlight, or its branch first) | the muted wooden knock (invalid), soft. Built: Dreamlight-short plays it (97d5e2e7) |
| **Unlock a branch form** | the **memory returning**: a warm swell travels along the gold line from the root to the node (a soft rising breath, panned along the line where it can be), then the node **blooms**: that family's **material** (spore breath, stone settling, water welling, warm glow, root creak, low bell hum, bark, wingbeat, gust) + a warm **sung note** in key, ~1 s |
| **Unlock a final form** | the same, fuller: two sung notes (a fifth), a longer bloom (~1.5 s) |
| **Unlock an Ascended form** | the same, then the **crown** layer (the shared warm choir swell of the Crowned Reactions) and a slow, deep swell of the family's material; the biggest moment on this screen (~2.5 s) |
| Dreamlight spent (the counter going down) | no separate sound (the unlock is the sound) |
| Close | a soft breath out; the music opens back up |

- Unlocks are rare and chosen, so they can be **fuller and longer** than in-run sounds.
- Every unlock uses the **Warden's own family material**, so a Rain Lily unlock sounds like water
  coming home and a Mossback like stone settling.
- **Dreamlight earned** (a boss, a shard, the Sapling ripening): a slow, warm **glow swell** with a
  faint hummed note (the same as the Sapling's ripening), so the currency has one consistent sound.

## Ambience

A night forest bed per act (wind, leaves, insects in summer, dripping in autumn fog, creaking ice
in winter), **warmer and fuller near the Heartwood** and **thinner, colder, with occasional
whispers** toward the map's edges and the start, where nightmares come from.

**Felt more than heard.** The bed sits well under everything (about −10 dB below the music; the
Music slider controls both). Rules for it:

- **No hiss and no leaf rustles.** Never a steady layer of bright noise, and (second listen) no leaf
  rustles at all: they hurt the ear. The bed is wind plus rare soft events only.
- **Wind is low and moving.** Dark (mostly below ~400 Hz), in **gusts** that rise and fall over
  several seconds, with calm stretches between them. It never sits in the midrange where the music
  and the whispers live.
- **Sparse events** over the bed: a far owl, a low creak, a whisper, all soft and lowpassed. Most of
  the time, quiet.
- **Reacts to the run:** thins out as more nightmares are on the field (the dread layers take over),
  and swells back, warmer, at every rest.
- The **Omen wind** (the choice screen gust) follows the same rules: a soft, low gust, not a roar.

## Mix rules

- **Priority:** leaf lost > boss > dispel > Warden hits > nightmare signatures > Warden launches >
  music > ambience. Combat sits **on top of** the music, never under it.
- **Levels (relative):** SFX peaks at 0 dB reference; music about −10 dB under the SFX; ambience about
  −10 dB under the music. Default settings: Sounds 100%, Music **55%** (was 80%).
- **SFX bus softening** (safety net, not a substitute for rounded sounds): a gentle high shelf
  (about −6 dB above ~6 kHz) and a soft limiter on SFX and UI, so stacked hits can't turn sharp.
- **Ducking:** the music dips ~8 dB for about a
  second under a lost leaf and boss moments (roar, charge, dispel), ~3 dB for Ascended and Crowned moments. **Not** under normal dispels (2026-09-30). The ambience ducks along with it.
- **Music by phase:** during drifts the music plays ~3 dB lower than at rests, so combat owns the
  space and the rest is the exhale. The dread layers are also quieter than the warm base; they add
  tension, not volume. Adding layers must never make the music louder overall.
- **Many Wardens:** attack sounds are **voice-limited** (a few at a time per type), randomised, and
  get quieter as more of them play, so a 40-Warden maze doesn't become noise.
- **Game speed 2×/3×:** don't pitch-shift; throttle repeated sounds instead.
- **Positional:** pan by the sound's horizontal position on screen; slight distance falloff with
  camera zoom.
- **Loudness:** music around −16 LUFS; SFX peaks no higher than −3 dBFS.
- **Buses in Godot:** Master → Music, SFX, Ambience, UI, Voice (whispers/boss lines). Each gets a
  volume slider in settings.

## Accessibility

- **Every sound cue has a visual one**: Phantom and Lurker approach indicators, the leak flash, the
  low-leaves screen tint (see `screens_ui.md`).
- Separate volume sliders per bus; a **mono** option.
- A **"Softer nightmares"** option (decided 2026-09-28: include it; built in f30db75: nightmare sounds 8 dB quieter and muffled, dread whisper layer halved) that tones down shrieks and whispers for players who find them
  too intense.
- Boss lines and whispers are already on screen as text.

## Production

- **All audio original or properly licensed for commercial use**, tracked in
  `assets/audio/LICENSES.md`. Placeholders only from CC0 sources, and listed there too.
- **Formats:** music as OGG Vorbis loops with loop points; SFX as WAV (or OGG) 44.1 kHz.
- **Naming:** `mus_<act>_<state>_<layer>.ogg`, `sfx_<group>_<name>_<variant>.wav`
  (e.g. `sfx_nightmare_shade_move_01.wav`).
- **Variants:** 3–4 per frequently heard sound (dispel, attacks, footsteps) to avoid repetition.

## Demo shopping list

**Music (~6 pieces):** title / Heartwood theme; act 1 drift (base + 3 layers); act 2 drift (base +
3 layers); rest variant for each act; boss themes (one per boss: Hollow Stag, Mire Hag, Moth Queen, Hollow Oak; not a shared theme with a
motif per boss); win and loss stingers.

**SFX (~40):** the dispel (with variants); signatures for Shade, Husk, Mourner/Sob, Phantom, Night
Hound, Procession, Hollow Stag, Mire Hag; the 4 base Warden attacks + branches in scope; plant,
evolve, sell, invalid, tend, move; leaf lost; Dew; UI set (buttons, Dream reveal by rarity, family
bell, rest); ambience beds for acts 1–2.

## Revisions from the first listen (2026-09-27)

Placeholder sounds exist (`tools/sound_generator.gd`, `assets/audio/`, `Sound` autoload,
`SoundHooks`). The first listen found three problems; the fixes are in the sections above:

| Problem | Cause in the placeholder | Change |
|---|---|---|
| Wind too strong, hard noise under it | a constant high-passed hiss ("leaves") under a midrange wind; ambience only slightly under the music | no constant hiss, sparse rustles; low gusting wind with calm gaps; ambience ~10 dB under the music (see Ambience) |
| Music too loud | every stem normalised equally, layers add up; no ducking; Music default 80% | music ~10 dB under SFX, default 55%, dread layers quieter than the base, ducking, lower during drifts (see Mix rules) |
| Attacks lack impact | only a tiny launch sound, no hit sound when the shot lands; attacks at −9 dB and under 0.1 s | launch + **hit** with transient / body / tail, family weights, hit level about 6 dB up (see Wardens) |

**Second listen (same day):** everything still too sharp, especially dispels and hits; the leaf
rustles hurt the ear.

| Problem | Cause in the placeholder | Change |
|---|---|---|
| Dispels, hits and much else too sharp | the shared "crackle" texture (high-passed click trains at 1.5–3 kHz) in the dispel, split, leaf lost, hits, tend, trample, Shade, Widow and Stag; the dispel's saw shriek; instant 1–2 ms onsets; the doc itself asked for a 2–4 kHz snap | new pillar **Rounded, never sharp**; the dispel becomes sigh → dissolve → low chime; hits get a rounded 300–900 Hz *tock* and more body instead of a snap; weak hits fuller, not brighter; soft onsets; SFX-bus high shelf + soft limiter |
| Leaf rustles hurt | crackle-based rustles in the ambience | removed; wind plus rare soft events only |

**Third listen (same day):** shots sound like "pixel murmur"; kills sound "cashy".

| Problem | Cause in the placeholder | Change |
|---|---|---|
| The Sprout's shot sounds chiptune (Firefly Jar fine) | the Sprout's shot is a plucked synth tone, pitched in a melody, fired constantly (it's the most-built Warden) | Sprout becomes a leafy flick + a wooden twig tap made from noise through woody resonances, no tone; new rule **Organic, never chiptune** for all future Warden sounds; final versions are recorded foley |
| Kills sound like coins | every kill played the dispel + a bell chime that climbed a scale in combos + a two-bell Dew tinkle | release is a warm exhale / low hum, no bell; no climbing combo; no Dew sound per kill (lump sums only, soft) |

**Fourth listen (2026-09-30):** defeating nightmares sounds too close to lightning or thunder.

| Problem | Cause in the placeholder | Change |
|---|---|---|
| The dispel sounds like thunder | a falling band of noise (the sigh) + a falling low tone 200→100 Hz with a noise swell (the "whumpf") + a release with another falling noise sweep = the recipe for distant thunder; plus a 4 dB music duck on every kill, pumping like a thunderclap; and it shares the low whumpf + rumble with Thunderclap | dispel = voiced sigh + **reversed "unravel" swell** + a warm hum; mid range only, no sub, no downward noise sweeps; no duck on normal dispels; storm sounds (booms, rumbles) reserved for the light family |

**Fifth and sixth listens (2026-09-30):** the dispel should sound like "releasing a soul" (fifth); the
sung-vowel version "sounds like they're talking; maybe a burst of light, but more soothing" (sixth).

| Problem | Cause | Change |
|---|---|---|
| The dispel sounds like talking | a voiced "haah" sigh + a sung vowel changing "ooh" → "ahh" and gliding up: vowel changes + pitch glides = speech | **no voice at all**: a soft burst of tuned air (breathy noise through resonances on D, F#, A) gathering, blooming and drifting away; cold-to-warm by settling into tune; bosses a big slow bloom, no choir |

Open question: whether every attack keeps a launch sound, or only the slower, heavier Wardens
(Pebbling, Rootling) do and the fast ones are hit-only. Default: all keep it, very quiet (mostly air).
