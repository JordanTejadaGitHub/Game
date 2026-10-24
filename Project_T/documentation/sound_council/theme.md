# Sound Council 2026-10-23: Theme seat (the dark fairytale's keeper)

Question for every sound: does it belong to this world? Are the Wardens warm, small and made of their family's
material? Are the nightmares cold, hollow and wrong without being cute, comic or gory? Is it free of other games'
sound (arcade blips, cosy-farm chimes, synth kicks, sirens)? Is the motif used where the doc says?

Each finding names what it rests on: **[doc]** audio_direction.md, **[recipe]** tools/sound_generator.gd:line,
**[num]** sounds_measured.tsv, **[hook]** scripts/audio/sound_hooks.gd / sound.gd.

## Headline: why "placing a Warden / Sprout doesn't sound right"

Every Warden, every Sprout, every Thornwall and every Heartwood gift piece plays the **same** sound, `plant_01..03`
[hook sound_hooks.gd:232-234, 1301-1302: only `plant_heartwood_sapling` exists as an own id]. That one sound is
built as a little musical reward rather than a planting [recipe 3389-3399]:

1. **A harp note on every placement** (`_pluck` A3 / D4 / A3, from 0.42 s). Placing a maze means 20 to 40 placements
   in a minute. That makes the harp play a random tune of A–D–A notes over the score, which is the "cosy-farm build
   chime" this game must not have. The doc's own rule: "No plucked or music-box tones … melody belongs to the
   music, not to combat" [doc "Wardens"]. And the doc's plant spec has no note at all: "earth rumble + wood creak as
   the roots rise" [doc "Building and the map"].
2. **The harp is detuned out of the key.** `plant` plays with the default `PITCH_JITTER` 0.05 [hook :234,
   sound.gd:17,186]. ±5 % is up to ±0.85 semitone, so the in-key note lands between notes and fights the music. This
   is the most likely reason it "doesn't sound right".
3. **A rising pitch sweep.** `_sprout_unfurl` is a band of noise gliding 350→1100 Hz [recipe 3396-3399]. This is the
   "whoop" the third listen banned ("no pitch sweeps") [doc "Wardens"; Revisions, third listen].
4. **No wood creak, no roots, no family.** The doc asks for roots rising with a wood creak. The recipe has a 110 Hz
   noise thump, a 380 Hz scrape at 0.3 gain, the sweep and the harp. A Pebbling, a Dewdrop and a Thornwall sound
   identical when planted, which breaks "Family = material".
5. **Too long and too bright for something this frequent.** 1.12 s, centroid 1023–1081 Hz [num]. Nurture is 0.65 s
   and centroid 203–850 for most families, and the Sapling's rooting is 177 Hz [num]. Every placement also fires
   `path_shimmer` (now a low earth shift, fine) [hook :1222], so the two stack on each click.

**What it should be (house language): "a Warden settling into the earth".** ≤0.5 s, no tone, no sweep, no jitter on
anything tuned, weight from the low end:
- **Body:** a soft press into soil, `_thump(0.3, 95–110 Hz, 0.06)` at full gain.
- **Earth:** a short soil settle, `_lowpass(_soil_drag(0.25), 700)` (the material already exists, [recipe 2283]) at ~0.35.
- **Roots taking hold:** `_lowpass(_creak(r, 0.3, 20, 40, 380), 700)` at ~0.4, entering at 0.05 s. This is the doc's
  "wood creak as the roots rise".
- **Family tag (last 0.15 s, quiet):** the family's own material, short, at ~0.25. Spore: a small `_puff`. Stone: a
  `_ring` stone knock ([310, 620] Hz). Water: one low plunk, `_ring([260])`. Light: a 0.2 s `_light_glow`. Root: the
  creak a little longer. Song: one soft low bell (D3, felt). Acorn: `_wood_knock(190)`. Wing: one wingbeat. Wind: a low gust.
- **Per kind, ids through the existing lookup:** `plant_sprout` is the smallest (0.3 s, twig resonances
  [380/1070] from `_twig`, a tiny thump, −4 dB). `plant_thornwall` is a bramble stake pushed in (a dry low wooden
  *thunk* + a 0.15 s `_scrape(…, 650)` thorn drag; walls are the most-placed thing in the game, so this one gets the
  most care). `plant_<line>` covers the families. The hook should resolve `plant_` through `_sound_for("plant_", data)`
  (own → family base → line), not only `plant_<warden_id>`.
- Play it with jitter ≤0.03 (fine once nothing in it is tuned), peak ~−8 dB.

## 1. Top 10 findings, ranked

| # | Where | What is wrong | Evidence | Fix |
|---|---|---|---|---|
| 1 | `plant_01..03` (every Warden, Sprout, Thornwall, gift piece) | One generic planting for everything: a harp note detuned by pitch jitter, a rising noise sweep, no roots or creak, 1.12 s. It reads as a cosy reward chime, not planting | [recipe 3389-3399]; [hook :232-234, :1301]; [num] plant 1.12 s, centroid ~1050; [doc] "earth rumble + wood creak"; third-listen rules | See the headline: thump + soil + root creak + family tag, ≤0.5 s. Add `plant_sprout`, `plant_thornwall`, `plant_<line>` and a family fallback in the hook. No pluck, no sweep, no jitter on tuned parts |
| 2 | `sell` | A falling band-pass noise sweep 1500→250 Hz, then a G3 harp pluck with ±5 % jitter. It is the brightest building sound (centroid 2225, rolloff 6481), and a pluck on a Dew refund reads as a till | [recipe 350-353]; [num]; [doc] "roots withdrawing into the ground"; fourth listen: no downward noise sweeps | The plant played backwards in spirit: the root creak slowing (`_creak` 35→15 Hz ticks, body 300), `_soil_drag` lowpassed 600, the family material swell reversed and fading, ending in a soft low pull `_thump(0.25, 120)`. No note, no sweep. ≤0.6 s |
| 3 | `invalid` (refused placement, Dew short, Dreamlight short) | Two pitched sine knocks stepping down (170 then 150 Hz, each with a 1.6× downward glide). That is the arcade "uh-uh" error. It plays on every refused click | [recipe 355-358], `_knock` = sine glide + tri tap [1329-1335]; [num] rolloff 4716; [hook :236, 244, 246, 1085] | One muted wooden knock made of noise through inharmonic wood bands: `_ring(0.15, [150, 410], [0.8, 0.3], 0.03)` + `_thump(0.12, 160, 0.02)`. No second note, no glide. Like a root bumping a stone |
| 4 | `ui_click` (every button) | A sine with a pitch glide (672→420 Hz) and a triangle tap: an oscillator blip, chiptune by the third-listen rule. Rolloff 6955 Hz | [recipe 419-421]; [num]; [doc UI] "soft wooden clicks"; [hook sound.gd:548] | A wooden click made of noise: `_ring(0.06, [320, 860], [0.7, 0.25], 0.012)` + `_thump(0.05, 220, 0.01)`, lowpassed 2 kHz. A Remember node tap can share it, a little warmer |
| 5 | `evolve_<line>` (13 files) | Every grow ends in a warm harp D–A–D strum and opens with the rising unfurl sweep. The family material is one layer among five, so all 13 measure alike (2.0 s, peak −5.2, centroid 831–1134, attack 720–1184 ms). The doc reserves the harp strum for **Final Bloom**; using it on every grow takes away Final Bloom's moment | [recipe 3364-3366, 3401-3411]; [num]; [doc] Evolve = "a bloom of the family's own material … Nurture's bigger sibling", Final Bloom = "evolve bloom, then a warm harp strum" | Drop the strum from `_grow_bloom` and keep it only in `final_bloom`. Make the family material the lead layer (×2 the nurture swell, 1.0 s). Replace the unfurl sweep with a fixed-band leafy breath (`_air(0.5, 500, 0.3, 0.2)`). The bloom should peak by ~0.8 s to land with the fireflies grow (check) |
| 6 | `rest` SFX (every rest), `act_swell`, `dream_flip_3`, `win` | The rest exhale strums **D major** (D A D F♯ A) every five drifts. The Hope form / D major is reserved for a boss dispelled, the run won and the Dawnburst, so using it at every rest spends the run's most precious chord | [recipe 447-451] notes 50,57,62,66,69; [hook :255]; [doc] "Hope form … Reserved for big wins" | Rest: the warm form's open fifth (D–A–D) or the motif fragment D–A–F, with no F♯. The breath should be a fixed-band exhale, not the falling 1200→300 sweep. `act_swell` follows a boss dispel and may keep the F♯. Legendary flip: no third, or F natural |
| 7 | Nurture / Evolve material map (`nurture_<line>`, `_material`) | Five families are the same recipe, filtered air: spore (600 Hz), wind (400), sprout (800), and acorn and wall are **byte-for-byte the same recipe** (`_air(…, 300, …, 0.6)`). Stone is a 160 Hz rumble with no stone in it; water is a wobbled rumble with no water. With eyes closed you cannot tell spore from wind from bark | [recipe 856-867, 3418-3431]; [num] nurture_stone centroid 203, nurture_water 262; [doc] "Family = material … tell the family with your eyes closed" | Give each family its real material (see the material map below): stone = `_stone_grunt` + a pebble settle; water = a low `_ring([260])` plunk + `_sap_welling`-like liquid; acorn = `_wood_knock` + bark creak; wall = thorn `_scrape`; wind = a moving `_swirl`; spore = `_puff` breath; song = one soft low bell, not the choir hum |
| 8 | `sig_shade` (the act 1 basic nightmare, heard most) | "Muffled skittering" is built from **sine blips** at random 300–500 Hz (the comment says so). That is a chiptune patter, and with random pitches it reads as cute | [recipe 1242, `_taps` 1307-1313 = `_tone` sine]; [doc] "soft, muffled skittering (low taps, no hiss)" | Noise taps through low earth/wood bands (`_thump(0.05, 300, 0.01)` at random times + a faint cold `_air(…, 420)` breath under them), lowpassed 900, no tones. Cold, close and unseen |
| 9 | `sig_hag`, `hound_howl`, `sig_mourner` | Raw saw oscillators used as voices. The Hag's "heh" saw blips are a cartoon witch cackle (comic, speech-like). The howl is a saw with a pitch arc 300→480→300 Hz, a siren/theremin (sci-fi). The Mourner's saw sob with 40 Hz pitch wobble is speech-like. All three break "no voice or anything speech-like" and "never comic" | [recipe 1259-1260, 1283-1285, 1291-1296]; [num] hound_howl centroid 1124, peak −6.9, RMS −17.0 (one of the loudest signatures) | Hag: bog-wet bubbles and a slow, sucking low gurgle (`_bubbles` + `_rumble(…, 150)` with `_wobble`), no laugh rhythm. Howl: wind through a hollow, made of breath noise through two slow-moving low bands (250–600 Hz), and a far, hollow interval (D→A♭) in tuned air rather than a gliding tone. Mourner: a cold, detuned low chime-breath (the split's material) with a faint breath hitch made of noise, no pitched sob |
| 10 | `dream_open` (every rest), `dream_take_2` (Legendary) | `dream_open` ends in six music-box notes climbing 69→81 every 50 ms: a sparkle glissando, the "climbing chime" that reads as coins and cosy (rolloff 6158). The Legendary take has five CHIME (glassy partials) bells climbing an arpeggio, and the hook plays it at pitch 0.9, a minor second plus out of D | [recipe 423-427, 436-441]; [hook :274, :1264]; [num] dream_open attack 906 ms, rolloff 6158; dream_take_1 rolloff 5082; house rules "nothing that sounds like coins … no glassy tinkle" | dream_open: the breath in, then two low soft-mallet notes struck **together** (D4 + A4, like `dream_flip_1`) under a short bloom of tuned air. Legendary take: tuned air on D–A–D with the choir swell, BELL partials not CHIME, notes together not climbing, pitch 1.0 |

## 2. Every other finding

| Where | Problem | Evidence | Fix |
|---|---|---|---|
| `dew` (rest bonus, Omen reward) | A rising band-pass noise sweep 350→800 Hz; the brightest everyday sound (centroid 2711, rolloff 5771). It reads as a "whoosh-up" reward sparkle | [recipe 328-334]; [num] | Use the Grandmother Oak's sap welling (`_sap_welling`, [recipe 982]): low, slow, liquid. Lump sums only, as now |
| `win` | A D-major pluck arpeggio + three CHIME bells (glassy partials 2.76/5.4/8.93): tinkle, rolloff 11951. And the motif is not played **in order**, so the player never hears the Hope form D–A–F♯ as a melody | [recipe 466-470]; [num] | Harp + music box play D–A–F♯ ~0.4 s apart (the end-card button) into a held D major on plucks + a low choir hum. No CHIME |
| `loss` | Falls D–B♭–F–D–A, then an E♭ bell. The motif's Hollow form (D–A♭–F) is the obvious loss and is unused | [recipe 473-478]; [doc] motif | The fall as D–A♭–F in bowed bass, then the single cold low D drone; replace the E♭ bell with a bowed or tuned-air low note |
| `sig_procession` | The "chain-clink" is 5 inharmonic bells at 1000–1300 Hz: a glassy tinkle in the nightmare palette (rolloff 5879) | [recipe 1267-1271] | Muffled iron: the same rhythm as low `_ring([180, 420], …)` knocks, lowpassed 900 (the Barrow King's "muffled iron, no clank"), with the slow drum kept |
| `sig_sleepwalker` | A triangle tone gliding down 210→150 Hz: a cute "awww" sigh on a nightmare | [recipe 1287-1289]; [num] RMS −18.3 (loud for a signature) | Cold breath that drags (an `_exhale` at 300 Hz with a slow `_wobble`) + one low, hollow D/A♭ tuned-air hum. Not a gliding oscillator |
| `sig_husk` | The creak fits; the steps are sine knocks (`_knock`, 60 Hz glide) | [recipe 1244-1248] | Steps as `_thump(0.3, 80, 0.08)` + a bark `_ring([140, 330])`: heavy, dead wood |
| `sig_hound` | A saw growl with amplitude flutter: synth-ish but low and cold, acceptable as a stand-in | [recipe 1280-1281] | Later: low breath noise through a 120–300 Hz band with a growl-rate gate, no saw |
| `sig_phantom` | Reversed choir (fits) + a rising noise sweep 300→1400 Hz; centroid 2118, rolloff 10293: bright for a nightmare | [recipe 1273-1278]; [num] | Keep the reversed choir; replace the sweep with a fixed low band (500 Hz) swelling. A cold whoosh, not a riser |
| `hag_rise` | A falling noise sweep 2000→500 Hz (the weather vocabulary) | [recipe 1264-1266] | A low water slap (`_splash(1.4, 0.3)`) + bubbles |
| `attack_water_*` (family fallback) | A sine glide 400→900 Hz plus a CHIME at 900–1020 Hz: the exact "rising bloop droplet" the third listen banned; rolloff 14 kHz | [recipe 395-398]; [num] | Probably unreached (Dewdrop has `attack_dewdrop`) (check). Delete or rebuild from `attack_dewdrop` so no future Warden falls back to it |
| `hit_spore/stone/water/root_*` (family fallbacks) | Sine "body" with a 1.8× downward glide (a synth kick) + triangle tock glide; `hit_water` adds an upward glide 600→1400 (the bloop). Rolloff 11–12 kHz | [recipe 518-558]; [num] | Reached only when a family's base Warden has no own hit (check). Rebuild from the organic `_stone_thud` / `_splash` / `_puff` / `hit_rootling` so new Wardens never inherit a synth kick |
| `hit_full_*` (every weak-matchup hit) and `crit_punch` | A sine glide 150→58 Hz / 110→46 Hz: an 808-style synth kick, heard often | [recipe 501-503, 488-490] | Weight from noise: `_thump(0.4, 80, 0.1)` + `_rumble(0.3, 120, …)`. Same low end, organic |
| `attack_spore_*` (family fallback) | A sine glide 420→140 Hz "pop": a synth bloop (rolloff 3.4–4 kHz) | [recipe 386-389] | Sporeling has its own (`attack_sporeling`, air). Delete or rebuild like it (check if reached) |
| `attack_acorn` | A music-box bell on D4 as a Warden sound: "no music-box tones on shots" | [recipe 416] | Acorn has no attack; likely dead (check). Remove |
| `path_shimmer` id | The sound is now a low earth shift (good); the id still says shimmer | [recipe 3369-3370] | Rename when convenient (`route_shift`), so nobody "fixes" it back to a shimmer |
| `split` (Mourner breaking into Sobs) | CHIME partials (glassy) at A4 | [recipe 316-320]; [num] rolloff 5792 | A BELL partial set or tuned air, an octave lower (A3), detuned pair kept. Cold, not glassy |
| `combo_found`, `discover_signature`, `shard_great_dreamcatcher`, `dream_fly` | Music-box notes on discovery moments. Rare and in key, so allowed, but music box stacks up as the game's "you got something" chime | [recipe 507-513, 2395-2410] | Keep them rare; prefer two notes struck together over a step up (discover_signature already does) |
| `evolve` timing | The bloom's loudest moment comes ~1.0–1.2 s after the grow (attack_ms) while the fireflies grow animation is 0.8 s | [num] evolve attack 720–1184 ms | Pull the material bloom forward to ~0.5 s (check against the animation) |
| `nurture_sprout` | The leafy-breath nurture is the brightest nurture (centroid 1339) and Sprouts are nurtured most | [num] | Lower the band to ~550 Hz, add the twig resonance as the settle |
| `sig_stag` | A saw bellow with a moving filter: reads as a beast; fits the Hollow Stag, but rolloff 6223 | [num] | Keep the bellow; lowpass the ghost-fire hush to 1.5 kHz |
| Bellflower family | In key, low, felt; fits the song family | [recipe 689-692] | Keep |
| `rest` music set vs `rest` SFX | The rest piece already exhales; the SFX strum on top doubles the harp | [hook :255, :270] | With the fix in #6, keep it at −6 dB or drop the strum and keep only the breath |

## 3. Missing sounds (events with no sound, or a stand-in)

- **The title screen and the Memory Grove play no music at all.** `play_music` is only called from SoundHooks in a
  run [grep: no Sound calls in title / grove scripts]. Doc: title = "the Heartwood theme: slow, warm, a single cold
  note under it"; Grove = "the Heartwood theme, gentle, with music box". The first thing a Steam player hears is silence.
- **Grove planting a node, a Memory opening, Carry / loadout**: no sounds (the Grove is the meta's reward loop).
- **Plant variants:** `plant_sprout`, `plant_thornwall`, `plant_<line>` (see #1). The gift piece (`piece_placed`)
  could use its own soft "landmark settling" instead of the Warden plant.
- **The Callings, the run's class identity:** Spore Print mushrooms appearing / eaten (`MUSHROOM_POP` is visual
  only), Puddles ripples, Keeping Time pips and Tolls, Lantern Light lit / jumps. None is hooked
  (no `toll`, `mushroom`, `puddle` in sound_hooks.gd). Each is a family material at its smallest: a soft fungal pop,
  a low water ripple, one low felt bell (in key), a warm glow tick.
- **Calling evolution chosen** (`calling_grew`): not hooked. It should sound like the Remember unlock in miniature.
- **Legendaries** (doc: "visible, a build by itself"): Waymark planted / moved, a walker shedding its statuses at
  the stone, Walking Wood swap, Headlong's compressed drift, Wild Growth ripening: no hooks. The Waymark shedding is
  a good place for a short Hollow-to-warm tuned-air turn (A♭→A).
- **Tower signals made "for Sound" but not connected:** `exposed_struck`, `legacy_released`, `signature_fired`
  (sound_signals.txt; 0 matches in sound_hooks.gd).
- **Sleepwalk bump, Fairy Circle ring trigger:** the doc already notes they lack an event.
- **Heartwood Sapling planted** has its own sound, but `sapling_planted` is not hooked separately; it rides
  `tower_built` (fine) (check).

## 4. Material map (what each family / nightmare is actually made of, from the recipes)

| Family / kind | Should be (doc) | Is (recipe) | Verdict |
|---|---|---|---|
| Sprout | twig, leafy air | hit: noise burst through woody bands (`_twig`); launch: band-passed air; plant: thump + sweep + harp; nurture: air 800 Hz | Hit/launch right; plant and nurture wrong |
| Thornwall / wall | bramble, bark | plant: the generic plant; nurture = acorn's air recipe; hit_bramble: thorn scrape | Needs its own planting |
| Spore (Sporeling line) | soft fungal air, puffs | air + noise thumps (`_puff`, `_cap_thup`, `_earth_pops`) | Right in hits; nurture is plain air |
| Stone (Pebbling line) | rock on earth | `_stone_thud` (thump + inharmonic stone ring), `_mortar`, `_pebbles` | Right in hits; nurture = a rumble only |
| Water (Dewdrop line) | real water | `_splash` (noise slap + low ring + spray), creaks for frost | Right in hits; nurture = a wobbled rumble, no water |
| Light (Firefly Jar line) | warm air and glow | approved `hit_light` (tri tones + noise); `_glow_swell`; `_light_glow` tuned air | Approved; keep |
| Root (Rootling line) | earth, creaking wood | rumbles + `_creak` + thumps | Right |
| Song (Bellflower line) | soft low bells, hums | `_bell` BELL partials low, `_ring` stone chime, `_thrum` | Right; nurture = choir hum instead of a bell |
| Acorn | wood and bark | `_wood_knock` (ring + thump) | Right in hits; nurture is air |
| Wing (Nestling line) | feathers, wingbeats | `_flutter`, `_feather_strike` | Right |
| Wind (Whirligig line) | moving air, spinning wood | `_spin_up` (a gentle band sweep), `_swirl`, `_whirr_bed`, `_clack` | Right |
| Dispel | tuned air D/F♯/A | `_light_burst` tuned air | Approved; keep |
| Shade | muffled low taps | sine blips | Wrong (oscillator) |
| Husk | bark creak, heavy steps | creak + sine knocks | Half |
| Lurker | faint whisper | `_whisper` | Right |
| Phantom | breathy whoosh, reversed choir | reversed choir + a rising noise sweep | Half (sweep too bright) |
| Night Hound | low growl, howl | saw growl; saw siren howl | Synth; howl wrong |
| Procession | chain-clink, slow drum | bright inharmonic bells + sine knocks | Clink too glassy |
| Mourner | faint sobbing | pitched saw sob | Speech-like |
| Sleepwalker | (sleepy hum) | triangle glide down | Cute |
| Widow | chitter + whisper | sine taps + whisper | Taps synth |
| Hollow Stag | bellow, ghost-fire hush | saw bellow + filtered noise | Fits |
| Mire Hag | "wet gurgling laugh" | saw "heh" blips + bubbles | Comic; drop the laugh |

## 5. What already works (keep)

- **The dispel** (`dispel_*`, `dispel_elite_*`, `dispel_boss`): tuned air on D/F♯/A, no voice, no boom. Approved; untouched.
- **The Firefly Jar** (`attack_light`, `hit_light`): approved; untouched.
- **The score's motif use:** dread1 and boss bass carry the Hollow form D–A♭–F every 4 bars [recipe 1521, 1573,
  1758]; the boss warm layer answers with the warm form [1589]; the turn A♭→A into the Hope form [1646-1658] is
  exactly the doc's "never a stop". The gather (rest → drift) with its far A♭ call from act 2 is on theme.
- **Bigger every act** is built from drums, bowed bass and choir, not brightness (`_make_score_gather`, drive stem).
- **The Warden sound sheet's own hits** (stone thud, splash, puff, root rumble, feather strike, Bellflower bells):
  organic material, in the family, as the doc asks.
- **leaf_lost** (a dark lunge, a groan, a hollow knock) is cold and pairs with the dispel; **trample**, **tend**,
  **move**, **path_shimmer** (now earth) and **drift_start** (the breath-in) fit.
- **The Sapling's rooting** (`plant_heartwood_sapling`, centroid 177) shows what every plant should be: low, slow, earth.
- **Ascended / Crowned / Reactions** mostly use the house materials (thumps, rumbles, tuned air, the crown hum)
  and stay low (crowned_tempest centroid 169, starfall 354).
