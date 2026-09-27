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
| **Rest** | the act's warm base alone, calmer tempo; the exhale |
| **Drift** | base + dread layers by intensity |
| **Boss** | a boss theme per boss (Hollow Stag: heavy drums and bowed bass; Mire Hag: bubbling low reeds and a crooked waltz). Below half health a **warm counter-melody** enters: the player is winning |
| **Choice screens** (family pick, Dream, Omen) | music drops to a soft pad; time has stopped |
| **Memory Grove** | the Heartwood theme, gentle, with music box |
| **Win / loss** | short stingers: a warm resolving chord / a slow fall into a single cold note |

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
were too sharp):

1. **Sigh:** the nightmare's cold breath going out of it. A short, breathy, falling exhale (a low vocal
   formant, lowpassed near 1.5 kHz), pitched by size. Unsettling, not a scream.
2. **Dissolve:** a soft, muffled *whumpf* as the shadow comes apart: low body (~100–200 Hz) with a
   gentle airy swell. No glass or ice crackle.
3. **Release:** the dream settling: a quiet, warm exhale or a low hummed tone in the music's key,
   fading over ~0.5 s. **No bell or chime** (third listen: chimes read as coins).

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

### Building and the map

| Action | Sound |
|---|---|
| Plant a Warden | earth rumble + wood creak as the roots rise |
| Evolve | a rising bloom chime |
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
- **Ducking:** the music dips ~4 dB for about half a second under a dispel, and ~8 dB for about a
  second under a lost leaf and boss moments (roar, charge, dispel). The ambience ducks along with it.
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
- A **"Softer nightmares"** option that tones down shrieks and whispers for players who find them
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
3 layers); rest variant for each act; boss theme (Hollow Stag, Mire Hag, or one shared theme with a
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

Open question: whether every attack keeps a launch sound, or only the slower, heavier Wardens
(Pebbling, Rootling) do and the fast ones are hit-only. Default: all keep it, very quiet (mostly air).
