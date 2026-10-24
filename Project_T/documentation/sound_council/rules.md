# Sound Council 2026-10-23: rules seat (house rules + doc, line by line)

Sources: D = audio_direction.md (round copy), R = tools/sound_generator.gd, N = sounds_measured.tsv, H = scripts/audio/sound_hooks.gd / sound.gd.
Note on the numbers: `attack_ms` has a 23 ms grain, so it cannot prove a 1–3 ms onset; `rolloff_max_hz` above ~8 kHz shows up even on
files lowpassed at 1.4 kHz (e.g. kin_bond_stone 11391, kin_bond_acorn 12166), so it looks like noise in quiet tail frames. I lean on the
centroid and treat high rolloffs as "(check)".

## 1. Top 10 findings, ranked

**1. `plant` (every Warden, Sprout, Thornwall, every gift piece) breaks "Organic, never chiptune" and the doc's spec. This is the user's complaint.**
- What it is (R:3389–3398): a 0.28 s lowpassed noise thump (110–134 Hz) + a little scrape + `_sprout_unfurl` (a bandpass sweep
  **rising 350 → 1100 Hz**, R:3397) + a **Karplus-Strong plucked note** (A3 / D4 / A3, `_pluck`, R:3392) entering at 0.42 s.
  `_layers` normalises each part first, so the pluck at gain 0.38 is as loud as the sweep (0.4).
- Rules it breaks: D:434–436 "no pitch sweeps (the rising bloop…)" and "no plucked or music-box tones… those read as 8-bit"; third
  listen D:898 (a plucked synth tone on the most-made action = the Sprout's old "pixel murmur"). It is the most frequent building sound:
  Thornwalls are planted far more often than Wardens.
- It drifts out of key: `tower_built` → `sound.play(&"plant", pos)` (H:234) uses the default `jitter := PITCH_JITTER` 0.05 (sound.gd:150,
  :185), so the plucked D/A lands up to ±5 % (~0.85 semitone) off D minor against the score.
- The pluck's own onset is 2 ms (`swell(0.002…)`, R:210) at 0.42 s, where `_sfx`'s 12 ms fade (R:276) no longer reaches.
- Doc vs recipe: D:757 "Plant a Warden | earth rumble + wood creak as the roots rise". The recipe has no rumble and no creak; the
  weight comes from the sweep and the pluck. N: plant_01..03 centroid **1023–1081 Hz**; the doc-faithful `plant_heartwood_sapling`
  (rumble + creak + low pebbles, R:839–841) is **177 Hz**. Same for every family: no family material, unlike Nurture and Evolve.
- Fix: remove the pluck and the rising sweep. New `plant`: an earth push (`_rumble` 0.35 s, ~120 Hz, 60 ms swell) + a root creak rising
  in **click rate, not pitch** (`_creak` 12 → 28 Hz, body ~260 Hz, lowpass 700) + a soil settle (`_scrape` lp 600 + 3–4 `_pebbles`
  under 700 Hz) + a low settle (`_wood_knock` ~140 Hz at 0.3 s). Add `plant_<line>` (hook: try `plant_<warden id>` → `plant_<line>`
  → `plant`) with the family's `_material(line, 0.4)` as a quiet tail (≤0.3). Thornwall: a thorny bramble creak (`_scrape` 650 like
  `hit_bramble`) over the push. Sprout: a small leafy flick (fixed band, no glide) over the push. Pass `jitter` 0.03 at most. Target
  centroid ≤ 500 Hz, in line with the Sapling's 177.

**2. Every Evolve now plays a harp strum, so Final Bloom has lost its identity, and Evolve keeps a rising sweep.**
- R:3401–3409 `_grow_bloom`: `_sprout_unfurl(0.7)` (the same 350 → 1100 Hz rising sweep) + three plucks D3–A3–D4 at 0.5 s, 50 ms
  apart (a rising strum) on all 14 `evolve_*` ids and `evolve`.
- D:758 Evolve = "a bloom of the family's own material… a warm swell… a low, full settle"; there is no strum. The harp strum is
  Final Bloom's alone (D:494–498: "a warm harp strum… so reaching it is a moment you hear"). H:742–748 plays `final_bloom` (a 5-note
  strum, R:2264–2269) on top of an evolve that already strums: two strums at once, and the moment is no longer special.
- N: evolve_* centroid 831–1134 Hz (sprout 1134, spore 1063): brighter than their own material swells.
- Fix: drop the plucks and the unfurl sweep from `_grow_bloom`. Use the material (`_material(line, 1.0)`) + `_soft_hum([50, 57])` + the
  low thump/creak settle. Keep the strum only in `final_bloom`.

**3. The reward moments climb in pitch, which the coin rule forbids (`dream_open`, `dream_take_2`, `rest`, `dew`, dream pulses).**
- `dream_open` (H:274, on every Dream offer): a breath sweep 300 → 1400 Hz, then **six music-box notes rising A4 C5 D5 E5 G5 A5,
  50 ms apart** (R:423–427). That is a climbing chime run. N: centroid 1615 Hz, rolloff 6158: the brightest UI sound.
- `dream_take_2` (card_taken, rarity ≥ 2, H:276, and again in `_on_legendary_taken` H:1264): choir + **five CHIME bells climbing
  D4 F#4 A4 D5 F#5, 80 ms apart** (R:434–439). CHIME partials 5.4× / 8.93× put energy at 4–6 kHz.
- `rest` (H:255, every rest = the rest bonus moment): a falling noise sweep + **a rising five-note pluck arpeggio D3 A3 D4 F#4 A4**
  (R:447–451). N: centroid 1252 Hz.
- `dew` (H:262/264, the lump-sum Dew sound): white noise through a wide bandpass **gliding up 350 → 800 Hz** (R:331). N: **centroid
  2711 Hz**, the brightest non-wind SFX in the game. D:424 says "a soft, low rustle of light". It is neither soft nor low, and it rises.
- `_dream_pulse` (H:1284–1285): each Warden a picked card touches gets `dream_trigger_*` at pitch 1.0 → 1.03 → 1.06, "two small steps
  up". That is still a climb, on a reward.
- Fix: `dream_open` = the breath in + one held low tuned-air chord (`_tuned_note` D4 + A4, as `discover_reaction` almost does), no run.
  Retire `dream_take_*` (the newer `dream_flip_*` / `dream_fly` already carry the pick, see #9). `rest` = the breath out + one rolled
  chord at once (all notes inside 30 ms), or no tonal layer at all (the rest piece already plays). `dew` = `_rumble`/`_air` centred
  ~300 Hz, a swell with **no glide**, lowpass 900. Pulses at one pitch.

**4. Soft onsets stop at the file's start, so later layers keep 1–3 ms attacks.**
- `_sfx` fades only the first `onset` s of the finished file (R:274–279). Inside the mix: `_ring` shapes every ring with
  `perc(0.001, …)` (R:1055, **1 ms**), `_twig` too (R:569), `_pluck` 2 ms (R:210), `_knock` 3 ms (R:1331), and `_tom` 2 ms
  plus a 1 ms noise click (R:2174–2175, every music drum).
- Where a layer starts late, nothing softens it: plant's pluck at 0.42 s, `leaf_lost`'s knock at 0.75 s (R:324), `tend`'s at 0.4 s,
  `move`'s at 0.65 s, every `nurture_*` settle knock at 0.45 s (R:877), `_pebbles` / `_earth_pops` (rings at random times), `harvest`
  droplets, `crowned_fairy_circle`'s 8 pops.
- D:22–23: "at least a 3–5 ms fade-in on hits, 10 ms+ on everything else". The music has the same rule (D:74–75, "soft onsets, felt mallets").
- Fix: give `_ring` / `_twig` a 3 ms minimum attack, `_pluck` / `_knock` / `_tom` 4 ms, and the tom's noise 3 ms. Or let `_mix` apply a
  `HIT_ONSET` ramp to every layer it places at `at > 0`. One shared change, then re-render.

**5. Two of the four starting families hit twice as bright as the approved hit.**
- N centroids: `hit_dewdrop` 1658–1687 Hz, `hit_rain_lily` 1652–1686, `hit_frostfern` ~1470, `hit_sporeling` 1351–1417. The approved
  `hit_light` is 697–740; `hit_sprout` 929–1254; `hit_bellflower` 258–400. Dewdrop and Sporeling are starters (memory: the four starting
  families), so these are among the most-heard sounds.
- Recipes: `_splash` = a noise slap lowpassed only at 1800 Hz + a spray of `_air` at 1100 Hz (R:1143–1146). `_puff` = `_air` at 900 Hz
  at 0.6 over a thump (R:1097–1098).
- Rules: D:17 "Weight comes from the low end and the level, never from brightness"; D:24 "SFX content mostly below ~3 kHz". The doc
  is partly to blame: D:455 asks for "a **sharp** droplet snap". That word contradicts pillar 6, so change it to "a soft droplet tock".
- Fix: lowpass the splash slap at ~1000 Hz, put the spray at 700 Hz and ≤0.15, and raise the low plunk (`_ring` 260 Hz) to 0.8. Lower
  `_puff`'s air to 600 Hz and let its thump lead.

**6. The Acorn's launch is a music-box note on every shot.**
- `attack_acorn` = `_bell(hz(62), MUSIC_BOX)`, 0.9 s (R:416). Acorn now has a splash attack (resource/tower/acorn.tres role "Splash damage,
  support…"), and `_on_attack` (H:883–885) plays `attack_acorn` on each release, since `acorn` is not in `QUIET_LINES` (only "wall").
- D:436 "No plucked or music-box tones on shots; melody belongs to the music". The doc row (D:586 "a soft woody knock when a neighbour
  is buffed") also describes a support Warden that no longer exists.
- Fix: `attack_acorn` = a bark *thup* (`_cap_thup(170)` or `_wood_knock(190)` lowpassed 900, 0.2 s). Update D's Acorn row to its
  splash attack.

**7. The crit punch is a sine kick on every crit.**
- `crit_punch` = a pure sine gliding 110 → 46 Hz + a tri tap (R:486–488); H:647 plays it with `crit` on every crit without its own sound.
  Crit builds (Lantern Light's Bonfire line, Starlit Aim) make crits common. N: centroid 172 Hz, so it is dark, but the material is
  a pure oscillator with a pitch glide, which D:434–435 forbids as a shot's main sound.
- Fix: `_thump(0.3, 70, 0.08)` + `_stone_thud`-style ring at ~300 Hz: a noise body, no glide. `crit` (the BELL at D4) is in spec: keep.

**8. "Speech-like" whispers vs the doc's own whisper specs (rule vs doc, the lead must rule).**
- `_whisper` (R:216–239) is noise through **two moving formants, chopped into syllables**: a vowel-shaped, syllabic sound. The sixth
  listen (D:912) found that moving vowels read as talking, and the house rule allows "one hummed vowel at most".
- Used in: mus_act1_dread2 (R:1532), mus_boss_act1_theme (R:1584), amb_act1 (R:1440–1441), `sig_lurker` (R:1250), `sig_widow`
  (R:1285), `echo_whispering_hollow` (R:716). D:57/111/116 (dread2 "faint whispers"), D:371–372 and D:580 all ask for whispers.
- Also voice-like: `sig_mourner` = saw "hitches" gliding 330 → 270 Hz with a 40 Hz wobble (sobs, R:1277–1282; N centroid 1617).
  `sig_hag` = four saw "heh" bursts, a laugh (R:1294–1299; D:374 asks for a "wet gurgling laugh"). `hound_howl` = a saw rising
  300 → 480 Hz (R:1263).
- Fix: either ratify whispers as the one allowed voice (in D, gated by Softer nightmares), or make them formant-free: fixed bandpass,
  no syllable gating, a breath swell. Replace the laugh with bog bubbles + a low wet gulp, and the sobs with a breathy tremolo (no pitch
  glide). Ask the user.

**9. Two sound paths fire on one Dream pick, plus old recipes the doc has dropped.**
- `card_taken` → `dream_take_%d` (H:275–276) and `card_chosen` → `dream_fly` (H:1270–1272). DreamState emits both on a pick
  (dream_state.gd:2973, :6397). (check: same frame.) A Legendary pick also gets `dream_take_2` from `_on_legendary_taken` (H:1264):
  the climbing CHIME run twice.
- `dream_take_0` is a lone music-box D4 (R:428); `dream_take_1` is choir + music box (R:429–433). These are the doc's old "card reveal
  chimes" (D:777), which the house rules now forbid.
- Fix: unhook `card_taken`'s `dream_take_*`. Let `dream_fly` + the flip carry the pick. Give the Legendary take its own non-climbing
  sound (the Legendary flip's tuned-air bloom, R:2393, held longer, plus `crown_swell`). Rewrite D:777–779.

**10. Old oscillator sounds left in assets/audio as fallbacks: the forbidden "bloop" is one rename away from coming back.**
- `attack_water` = a sine **rising 400 → 900 Hz** + a CHIME bell at ~900 Hz (R:394–398), word for word the third listen's "rising
  bloop droplet" + tinkle. `hit_water` has a sine droplet rising 600 → 1400 Hz (R:547). `attack_spore` is a sine falling 420 → 140 Hz
  (R:387). `attack_stone` is a noise band rising 400 → 1200 Hz (R:391; N rolloff 5.4–5.9 kHz, centroid ~1450). `hit_stone` / `hit_root`
  / `hit_spore` have sine-glide bodies + tri tocks (R:533–537).
- Today they are only reached through `_lookup_ids`' last fallback, `<prefix><line>` (H:547–552), when a Warden and its family base
  both lack a file. (check) The root line's projectile Wardens without their own launch fall back to `attack_root` (a sine knock).
- Keep `hit_light` / `attack_light` (approved), and `_hit("light")`, which Stormcap, Thunderhead, `bolt_strike` and the storm Reactions
  reuse.
- Fix: delete the water / spore / stone family `attack_*` / `hit_*` files and their recipes. Point the `<line>` fallback at the family
  base's noise-material sounds. Add a test that no `attack_<line>` / `hit_<line>` exists except light and sprout.

## 2. Every other finding

### Rule breaks
| where | problem | evidence | fix |
|---|---|---|---|
| `sell` | a falling noise sweep 1500 → 250 Hz + a pluck G3; N centroid **2225 Hz**, the second-brightest building sound | R:350–353; D:762 "roots withdrawing into the ground" | `_creak` falling in click rate + `_rumble` 140 Hz + soil `_scrape` lp 600; no pluck, no sweep |
| `attack_samara` / `attack_autumn_gale` | the brightest SFX in the game, centroid **3182–3250 Hz** | R:1199–1202 `_seed_whir`: noise bp 700 Hz damp 0.7, with only the 4.5 kHz lowpass after it | add `_lowpass(…, 1200)` twice; centre ~500 Hz |
| `plop_pond_keeper`, `attack_pond_keeper`, `dew_catch` | centroid 2227–2324 / 1730–1765 / 1795–2062 Hz | R:730–731, R:725–727, R:2231–2233: `_nburst` lowpassed once at 1000–1200 Hz (12 dB/oct) | lowpass twice at 700 Hz; let the low ring lead |
| `attack_dreamcatcher` / `attack_great_dreamcatcher` | thread "rustle" at centroid ~1710–1750; the second listen banned rustles | R:1166–1167 (`_flutter` 1400 Hz cutoff + `_air` 1100); D:892 | feather flutter at 700 Hz, no air band |
| `sig_phantom` | a noise band rising 300 → 1400 Hz; centroid 2118 | R:1257 | a fixed band ~600 Hz with a swell; keep the reversed choir |
| `hag_rise` / `_bubbles` | sine "bubbles" each gliding **up ×2.2** = rising bloops | R:1344–1351, R:1302–1304; D:434 | bubbles as `_ring` at 200–400 Hz with a 3 ms attack (as `_earth_pops`), no glide |
| `_taps` (`sig_shade`, `sig_widow`) | sine blips at 300–500 Hz, 4 ms attack | R:1306–1313 ("little low sine blips") | `_thump(0.05, 350, 0.01)`: noise taps |
| `split` | two CHIME bells A4 (+2.5 % detuned) with 5.4× / 8.93× partials; centroid 1170 | R:311–315; D:368 asks for "a soft, detuned low chime" | use BELL partials at A3, lowpass 1500 |
| `harmony_strike` | a music-box note in combat (D4 / F4 / A4) | R:2200–2201; D:436 | a tuned-air tick (`_tuned_note`, 0.3 s) or a soft `_ring` at 300 Hz |
| `kin_stage_up`, `shard_great_dreamcatcher`, `combo_found`, `dream_fly`'s tail note, `discover_signature` | music-box chimes on reward moments (rising A4 → D5 / D4 → A4 pairs in `combo_found` and `discover_signature`) | R:2197–2199, 711–713, 508–513, 2409, 2400–2406; D:899 (no chimes on rewards), D:801–802 (Dreamlight = a glow swell + hum) | `shard_great_dreamcatcher` → `dreamlight_glow` material; the pairs played together, not in steps; or `_tuned_note` |
| `kin_bond_light` / `kin_bond_wing`, `act_swell` chord, `beam`, `_glow_swell` | plain tri-oscillator tones as the main sound (glow / flute colours, act_swell's D-major tri chord) | R:2217, 2222, 3374–3376, 489–492, 1148–1153 | `_tuned_note` (breathy tuned air) or `_soft_hum`. `_glow_swell` is the Firefly template: keep it in Firefly sounds, but not in act_swell / beam |
| `harvest` | dense pitched droplets 260–480 Hz (Q≈33 rings, 1 ms onsets) poured as a reward: a near-tinkle | R:2234–2241 | fewer, lower (180–300 Hz) droplets with 3 ms onsets, or a `_sap_welling`-style pour; (check) by ear |
| `_pebbles` (scree loop, Shatter, Avalanche, Rockslide, Old Mountain, Sapling) | narrow rings at 500–1100 Hz with 1 ms onsets; D:695 / 675 say "no tinkle" | R:1132–1138 | rings 250–600 Hz with a 3 ms attack, lowpass 1200 |
| `leaf_lost` groan, `loss`, `boss_reveal`, dread drones | saw oscillators (cold, lowpassed) | R:322, 476, 2278 | in spec for cold sounds (D:37, bowed / detuned drones); no change, listed for completeness |
| music `_tom` | a 2 ms tone attack + a 1 ms noise click in every drum (boss, drive, gather, dread2) | R:2173–2176; D:75 / 150 "deep felt toms… rounded" | 5 ms attack; noise lowpassed 500 Hz with a 4 ms attack |
| `mus_act3_dread2` | the brightest music stem (centroid **1897 Hz**): a steady narrow noise "reeds" bed + a pure sine bowed saw | R:1955–1960, N; D:813–814 "never a steady layer of bright noise" | lowpass the reeds at 700 Hz and gate them in gusts; −3 dB |
| Mire Hag signature | a **square-wave** reed + a sine bubble rising 180 → 320 Hz | R:2010–2016 | a `_bowed` saw pair through a 300 Hz band, `_ring` bubbles |
| act 2 / 4 music partials | marimba 9.8× and kalimba 5.4× partials reach 7.5–8.6 kHz (short) | R:1670–1671, 1748 | cap music partials at 6 kHz like `_bell` does for SFX (check) |
| ambience owl | two pure sine "hoots" gliding 410 → 360 Hz | R:1434–1438 | `_tuned_note` 380 Hz with a breath swell |
| SFX top end | the "dark top" is a single 2-pole lowpass at 4.5 kHz, which can't hold "mostly below 3 kHz"; 9 SFX have a centroid above 2 kHz | R:19, 275; N | a 2× (4-pole) `SFX_TOP_HZ` pass, or 3.5 kHz |

### Doc ↔ recipe mismatches
| where | doc | recipe | fix |
|---|---|---|---|
| `plant` | earth rumble + wood creak (D:757) | thump + rising sweep + pluck | #1 |
| `evolve_*` | material bloom, no strum (D:758) | unfurl sweep + D-A-D strum | #2 |
| `dew` | soft, low rustle (D:424) | a rising 2.7 kHz-centroid noise sweep | #3 |
| `rest` | "the music exhales" (D:779) | a falling sweep + a rising 5-note pluck strum | #3 |
| Dream reveal | Common a soft note, Rare a hummed choir, Legendary a full choir chord (D:777) | `dream_flip_*`: music-box notes stepping up (rarity 2: D4 → A4 → D5) + tuned air | update D to the flip set and make the glints simultaneous |
| Acorn | woody knock when buffing (D:586) | a music-box launch on a splash attack | #6 |
| `act_swell` | warm swell + a wooden stretch (D:773) | a tri-oscillator chord + creak + rumble | tuned air / `_soft_hum` for the chord |
| `hit_dewdrop` | "a sharp droplet snap" (D:455) | splash centroid 1.66 kHz | change the doc word; #5 |
| Sprout launch | "a small leafy flick of air" (D:504) | as specified (R:409–415) | none: a pass |
| `drift_start` | breath in 0.5 s, −8 dB (D:187) | 0.6 s air + rumble, −8 dB (R:3371, H:130) | none: a pass |

### Doc ↔ hook mismatches
| where | doc | hook | fix |
|---|---|---|---|
| building sounds while paused | building works while paused (CLAUDE.md "Speed") | `plant`, `sell`, `tend` / `move`, `evolve_*`, `nurture_*` are positional → AudioStreamPlayer2D under the world, "so it pauses with the game" (sound.gd:171–176): silent until unpause, then late (check) | play building / UI-confirm sounds unpositioned (or `PROCESS_MODE_ALWAYS`) while paused, as `final_bloom` already is (H:741) |
| dispel pitch | "Randomise pitch slightly"; bigger = lower, slower (D:418, 425) | `play_dispel` ignores `_size_pitch` and passes jitter 0.0 (sound.gd:205–217) | approved sound: leave it, but correct D to say "variants, not pitch" |
| Softer nightmares | tones down shrieks and whispers (D:851) | `SOFTER_IDS` includes `dispel` / `dispel_boss` (approved warm release) and `drift_start` (now a warm breath) (sound.gd:41) | drop those three; add `sig_mourner` (already covered by `sig_`), `split`, and the whisper stems |
| crit | normal hit + low punch + soft low bell (D:461) | as specified, but the punch is a sine kick | #7 |
| `hit_full` / `_dull` | weak = fuller, resisted = dulled (D:466–467) | `resisted` / `weak` hard-coded false (H:938–939): `hit_full_*` and every `hit_*_dull` are dead files | delete them or rebuild for Nightmare Kinds; update D |
| `dream_take_*` + `dream_fly` | one pick sound | both fire (H:276, H:1272) | #9 |
| Legendary offered / taken | own sound | placeholder: `dream_flip_3` pitched 0.85 + `ascend_great_bell` (H:1257–1265, "placeholders until Sound has its own") | spec it in D |
| dream pulses | "never a climbing chime" | pitch 1.00 / 1.03 / 1.06 (H:1284–1285) | #3 |
| ambience | one bed per act, warmer near the Heartwood (D:806–807) | `play_ambience(&"act1")` always (H:316); one ambience file | (check) whether `set_act` swaps beds; build `amb_act2..4` |
| gift pieces | none in D | `plant` (H:1301–1302) | follows #1 (use `plant_wall` or a soft stone set) |

### Undocumented sounds (built, no spec in audio_direction.md)
`kin_bond_<family>`, `kin_bond`, `kin_stage_up`, `harmony_strike`, `whole_tree` (Kinships: no section in D);
`dew_catch`, `harvest`, `interest_ripple` (D only has the unbuilt Dewcatcher / Wellspring rows); `close_call`; `root_yank`,
`soil_drag_short/long`; `boss_reveal`; `dream_flip_0..3`, `dream_trigger_0..3`, `dream_fly`, `discover_signature`; `combo_found`;
`focus_*`; `hit_full`; `crit_punch` (implied). Each needs a row in D in the house language, or the rules above can't be checked against
a spec.

## 3. Missing sounds (event exists, no sound or a stand-in)
- `ReactionTracker.crowned_fired` (made "for Sound", reaction_tracker.gd:21): not connected. Crowned still sound through `reaction_fired`,
  but the late-crown event has nothing.
- `Tower.exposed_struck` (tower.gd:24, "for Sound too"), `Tower.legacy_released` (:49), `Tower.signature_fired` (:50): not connected
  (only `signature_discovered` is).
- Callings and their evolutions (Spore Print mushrooms / doses / Throne, Puddles water, Keeping Time pips and Tolls, Lantern Light lit
  paths, 60 evolutions): no sound ids and no hooks. `DreamState.card_fired` ("first-fire callouts") is unhooked.
- Legendary Dreams: the Waymark (stone placed / moved, a walker shedding its statuses: `waymark_reached`), Walking Wood swap, Headlong's
  compressed drift, Wild Growth ripening: none.
- Sleepwalk bump and the Fairy Circle ring trigger (D:680, D:694 say "not built yet: no event").
- Acts 2–4 ambience beds; act-specific events (crickets, drips, ice groans) (D:806).
- Lessons / onboarding cards, Heartwood gifts (beyond the reused plant).
- Not built in D's own sheet: Rootcurl / Tangleroot / Snugroot / Long Way Home / Monsoon / Morning Fog / Beacon / Dewcatcher /
  Wellspring / Grove Heart / Elder Stump (the newer roster: brood_cap, inkcap, lichenling, jarlink, prism_jar, quaker, earthshaker,
  jetreed… all fall back to their family base).

## 4. What already works (keep)
- **The dispel** (`_light_burst`, R:2297–2316): tuned air on D / F# / A, no voice, no sweep, no low body; centroid ~1.4 kHz in the
  doc's 250 Hz–2.5 kHz band. Approved: don't touch.
- **The Firefly Jar** (`attack_light`, `hit_light`, `_glow_swell`): approved. Its oscillator recipe is the one licensed exception;
  reuse it only for light-family sounds.
- **The Sprout's shot** (`attack_sprout`, `_twig`): noise through woody resonances, no tone, no glide. It is the third-listen fix done
  right, and the model for the plant rebuild.
- `plant_heartwood_sapling` (centroid 177 Hz): rumble + creak + low pebbles, exactly D:652. It is the template for #1.
- The Warden sheet's organic building blocks (`_thump`, `_air`, `_rumble`, `_flutter`, `_scrape`, `_wood_knock`): noise-only, no
  oscillator. Most Warden hits / launches from R:586 on follow the rules (Pebbling, Mossback, Cairn, Nestling, Whirligig lines; N
  centroids 190–900 Hz).
- The seventh-pass fixes are in: `path_shimmer` → a low earth shift (centroid 289), `drift_start` → the breath (542), the status
  completion cues, the ground loops, the per-act gathering, and the no-duck dispel cluster (sound.gd:208–217).
- Bellflower bells: the one tonal family, D minor notes A3–F4, lowpassed 2.5 kHz, centroid 258–400. In spec.
- Chains: `chain_swell` gets fuller, not higher (H CHAIN_SWELL_STEP_DB in dB only). Ascended events are low and wide. The leaf lost
  cuts through by ducking (H:210).
