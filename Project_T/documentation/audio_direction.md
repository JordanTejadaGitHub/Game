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
5. **Warm, not weak.** Wardens have soft *timbres* (wood, water, bells) but sharp *transients* and
   real low end. Combat must feel like it lands. Gentle tone, firm hit.

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
| **Shade** | dry skittering, faint hiss | — |
| **Husk** | creaking bark, heavy steps | — |
| **Mourner** / Sob | faint sobbing | breaking into Sobs: a cracked chime + small sniffles |
| **Phantom** | breathy whoosh, reversed choir | passing through a wall: a muffled whoosh (a warning cue) |
| **Night Hound** | low growl | sprinting: fast padding; a short howl the first time a pack sprints |
| **Procession** | distant chain-clink and a slow drum | Lantern Bearer dispelled: the Wraiths' confused whispering |
| **Lurker** | only a faint positional whisper until revealed | revealed: a sharp intake of breath |
| **The Hollow Stag** | deep bellow, crackling ghost-fire | trampling: a wall crashing; charge: a roar |
| **The Mire Hag** | wet gurgling laugh | sinking: bog bubbles; rising: a splash |
| **Deeply Blighted** | its normal sound, pitched down, with a low haze drone | — |

### The dispel (the most important sound in the game)

Three parts, about 0.5 s: **shriek** (short, filtered, pitched by size, never harsh) → **crack**
(glass or ice crackle) → **release** (a warm chime that resolves in the music's key). Randomise pitch
slightly; when several dispels land close together, the chimes step up in pitch like a combo. Dew
landing on the leaves: a tiny tinkle.

### Wardens (warm, not weak)

Every attack has **two parts**: a small **launch** when the Warden fires, and a **hit** when it lands.
The hit carries the impact. It's built in three layers:

- **Transient** (first ~10 ms): a click or snap in the 2–4 kHz range. This is what makes it feel sharp.
- **Body** (~10–120 ms): a low thump, 60–150 Hz depending on the family. This is the weight.
- **Tail** (up to ~300 ms): the family's colour (splash, crackle, rustle), quieter.

| Family | Launch (quiet) | Hit (the impact) |
|---|---|---|
| Sporeling (spore) | soft pop + breath | a full, round "puff" with a soft low thump |
| Pebbling (stone) | sling whip | **heavy thud**: a hard wood/stone crack over a deep body |
| Dewdrop (water) | a drop falling | **splash**: a sharp droplet snap, a low "plunk", a spray tail |
| Firefly Jar (light) | a warm spark | a **crackle burst**; chains ripple a quieter crackle down the line |
| Rootling (root, pulse) | — (the pulse is the hit) | a **ground boom**: wooden knock + deep sub rumble, felt more than heard |
| Sprout (neutral) | a soft pluck | a light, bright "tock" |
| Acorn aura | — | a soft chime when a neighbour is buffed (rare, not every tick) |
| Crit | — | the normal hit + a bright ping + an extra low punch |
| Sunpetal / Midsummer beam | — | a warm hum that climbs in pitch as the beam ramps, with a soft sizzle on each tick |

- **Weight by target:** hits on tanky or big nightmares (Husk, Barrow Wight, bosses) are pitched a
  little lower and fuller; hits on small ones (Sob, Creep, Wraith) lighter and higher.
- **Resisted / weak** (the grey puff / sparkle): resisted hits are dulled (duller transient, less
  body); weak hits get a brighter transient. The player hears the matchup.
- **Level:** hits sit about 6 dB above where the first placeholder attacks sat (they were at −9 dB and
  far too quiet); launches stay low. Voice limiting (see Mix rules) keeps a full maze from turning to mush.

### Building and the map

| Action | Sound |
|---|---|
| Plant a Warden | earth rumble + wood creak as the roots rise |
| Evolve | a rising bloom chime |
| Sell | roots withdrawing into the ground |
| Invalid placement | a muted wooden knock |
| Tend a Withered Tree / move a Mossy Boulder | dry rustle and snap / stone grinding |
| Route changes | a faint shimmer as the path line redraws |

### The Heartwood

| Moment | Sound |
|---|---|
| **Leaf lost** | the nightmare's lunge (dark whoosh), the tree groaning, a leaf crackling as it falls. Must cut through everything |
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

- **No constant hiss.** Never a steady layer of bright noise: it reads as static, not forest.
  Leaves are **occasional rustles** every few seconds, scattered and panned.
- **Wind is low and moving.** Dark (mostly below ~400 Hz), in **gusts** that rise and fall over
  several seconds, with calm stretches between them. It never sits in the midrange where the music
  and the whispers live.
- **Sparse events** over the bed: a far owl, a creak, a whisper. Most of the time, quiet.
- **Reacts to the run:** thins out as more nightmares are on the field (the dread layers take over),
  and swells back, warmer, at every rest.
- The **Omen wind** (the choice screen gust) follows the same rules: a soft, low gust, not a roar.

## Mix rules

- **Priority:** leaf lost > boss > dispel > Warden hits > nightmare signatures > Warden launches >
  music > ambience. Combat sits **on top of** the music, never under it.
- **Levels (relative):** SFX peaks at 0 dB reference; music about −10 dB under the SFX; ambience about
  −10 dB under the music. Default settings: Sounds 100%, Music **55%** (was 80%).
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

Open question: whether every attack keeps a launch sound, or only the slower, heavier Wardens
(Pebbling, Rootling) do and the fast ones are hit-only. Default: all keep it, very quiet.
