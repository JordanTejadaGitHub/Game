# Sound Council review, 2026-10-23 (all sounds)

Seats: T theme, R rules, M mix, C composer, P player. Reports in this folder (and documentation/sound_council/).
Evidence: audio_direction.md (+ its Revisions = the user's verdicts), tools/sound_generator.gd, scripts/audio/,
sounds_measured.tsv (619 files, ffmpeg). Nobody listened: these are "listen to these first" calls, not taste verdicts.
User's prompt for this round: "placing a Warden / Sprout down doesn't sound right".

## Verdict
The score and the approved sounds (dispel, Firefly Jar) hold up. The everyday build loop does not: the sound the
player hears most at a rest is the weakest in the game, and the reasons are concrete. Below that, a layer of older
recipes still breaks the house rules the user set in the listens (plucks, rising sweeps, climbing chimes, sine
blips), and play-time pitch jitter detunes every tonal sound against the D-minor score.

## Why placing a Warden sounds wrong (all five seats agree: T R M C P) — spot-checked
1. **Silent while paused.** Plant, sell, evolve, nurture, tend/move are positional players added to the game scene
   (`sound.gd:177`, "so it pauses with the game"). Building is allowed while paused (and Lesson cards pause), so
   placing is silent, then up to 4 queued plants fire at once on unpause. Confirmed in code. (M P)
2. **One sound for every placement.** Sprout, Thornwall, every family Warden and gift pieces all play `plant`
   (`sound_hooks.gd:234`, `:1302`); only the Heartwood Sapling has its own. (T R P)
3. **The recipe breaks two house rules.** `plant` (`sound_generator.gd:3390`, from b617deea, 2026-10-21) = a thump,
   a noise sweep rising 350→1100 Hz (third listen: no sweeps) and a plucked harp note A3/D4 (third listen: no
   plucked tones on frequent actions). Centroid ≈1050 Hz vs 177 Hz for the Sapling's rooting, which follows the doc.
   The doc's "earth rumble + wood creak as the roots rise" was never built. Confirmed. (T R C)
4. **Out of key.** Played with the default ±5 % pitch jitter (`Sound.play` PITCH_JITTER): the harp note lands up to
   ~85 cents off, on no beat, often against the bar's chord (A over B♭, D over A major). Confirmed. (T R M C)
5. **Drags and fast clicks.** A drag line plants every cell in one frame; the 45 ms throttle keeps one sound. Fast
   clicks get 2.5 dB quieter each (CROWD_DB) and the 5th is dropped. (M P)
6. **Errors louder than success.** `invalid` (−21.0 RMS) and `sell` (−20.5, brightest build sound, falling sweep +
   pluck) are louder than `plant` (−22.6). `invalid` also covers "can't afford", so two refusals sound the same. (M P T)

## Fix first (owner: Sound code implementation; design: Sound Discussion)
1. **Build sounds play while paused**: route plant / sell / evolve / nurture / tend / move through a player with
   PROCESS_MODE_ALWAYS (positional still, as Final Bloom already does). (M P)
2. **New placement sounds, no tones:** `plant_sprout` (a small twig pressed into soil: soft thump, soil settle, a
   tiny root creak, < 0.45 s), `plant_thornwall` (a bramble stake: low thump + a short, dark thorn scrape),
   `plant_<line>` for the families (the same base + a quiet tag of the family material at the end), falling back to
   `plant`. No pluck, no sweep, jitter ≤ 1 %. Group plants stagger like Nurture (BLOOM_STAGGER), each a little quieter.
   (T R C M P)
3. **Sell** = roots withdrawing (a low reverse creak and soil closing, no pluck, no sweep), quieter than plant.
   **Invalid** = a muted wooden knock (no sine), with a separate softer `cant_afford` (a hollow low knock). (T R M P)
4. **Tonal sounds never jitter**: `plant`, `evolve*`, `rest`, Dream / Remember / Legendary chimes play at pitch 1.0;
   Nurture's −1 semitone per rank only on untuned materials (stone, water, root, wind, wall), never on light, song,
   memory. (C R)
5. **`hit_sprout` reaches 12–13 kHz** (measured rolloff 11.8–13.4 kHz; every other SFX ≤ ~6.8 kHz): the twig's top is
   escaping the 4.5 kHz lowpass. It's the most-played sound in the game. Confirmed in the numbers. (M R)
6. **Coin-like climbs still in the game** (third listen): `dream_open` (six rising notes), the Legendary take (rising
   run, twice), the `rest` arpeggio (D major, spending the Hope chord), `dew` (rising sweep, centroid 2711 Hz). Make
   them swells or settles, not ladders. (R T C)
7. **Evolve**: the grow sound from b617deea ends in a D–A–D harp strum, so every evolve sounds like Final Bloom; keep
   the strum for Final Bloom only. (T R)
8. **Boss music**: the warm counter-melody's A sits on the bass's A♭ every even bar (confirmed: `[74, 81, 77]` at
   t0 + 2e vs the bass pattern's 44); act 3's theme is shifted down a fourth over an unshifted bass; act 2's thirds
   and the act 3–4 echoes clash with the next chord (my seventh-pass `_third_below` and the one-bar-late copies). (C)

## Listen first (before anything changes)
`plant_01..03`, `sell`, `invalid`, `evolve_spore`, `hit_sprout_01..03`, `dream_open`, `rest`, `dew`,
`mus_boss_act2_warm` over `mus_boss_act2_bass`, `mus_act2_base` (the thirds), `mus_act4_base` (the canon).

## Disagreements and rulings
- **Speech-like nightmare sounds** (whispers, the Mourner's sob, the Hag's cackle): R says they break "no voice";
  the doc asks for them. Ruling: the "no voice" rule came from the dispel (sixth listen); nightmare whispers are a
  designed cold colour. Keep whispers, but the cackle (comic) and the sob (speech-like) go to the user. (R T)
- **The dispel is quieter than many Warden hits** (M: −25.3 vs hits up to −17.9). The dispel is approved as a sound;
  its level is a mix call, not a redesign: raise it ~3 dB or lower the loudest hits. Owner call. (M)
- **Family hit levels**: Dewdrop's hit is ~10 dB under Firefly's; Sporeling and Dewdrop hits are twice as bright as
  the approved Firefly hit. Even them out toward the Firefly Jar's level and brightness. (M R)

## Missing sounds
- Calling evolutions (`calling_grew`), the Waymark (`waymark_moved` / `waymark_reached`), `crowned_fired`,
  `signature_fired`, `exposed_struck` and others in sound_signals.txt: no hook. (M P T)
- Entry signatures for most act 3–4 nightmares and the act 2+ pool bosses. (P M)
- One ambience bed for all acts. No title / Memory Grove music beyond the act 1 rest piece. (M T)
- Loss cuts the music in 0.15 s and ends in silence; the win flickers the act 4 rest piece (C). Breaks "never dead air".
- The doc's mono option doesn't exist; "softer nightmares" skips the trample, the biggest startle. (P)

## House rules to add to audio_direction.md (after the user agrees)
- No play-time pitch jitter on any tonal sound; jitter only on noise-built sounds.
- Anything the player does during a rest (build, sell, grow, nurture, clear) plays while paused.
- Success is never quieter than refusal; a refusal never sounds like a reward.
- Every musical SFX is in D minor and lands on the score's harmony, or is unpitched.

## What works (keep)
The dispel; the Firefly Jar; the Heartwood Sapling's rooting; the motif's placement (warm / hollow / hope); loop
seams; bar-line handovers and the gathering; the turn; the Reaction family sound language.

## Open owner calls
1. Approve the new build-sound set (fix first 1–4) before it's built.
2. The Hag's cackle and the Mourner's sob: keep or replace?
3. Dispel vs hits level.
4. Who builds it: Sound code implementation, or this chat again while it's down.
