# Round 2026-10-24c: more of the group-wipe moment

Owner, 2026-10-24, after the v3 board videos: **"I like it, we can implement and commit. Also like the feel of a
big group being wiped and them bunched up like that."** Now protected in `documentation/enemy_design.md`
(Design principles, "Protect the crowd feel"). Everything in those videos is committed: drift shapes and big late
packs, the walking-lanes retune (614ec352), the Night Kite, Gloamwing and Pall.

**The one question:** how do we get **more of that moment, a big bunched group wiped at once**, without making
every drift a crowd or making one board answer everything?

## Watch (real speed, seed 4242, a real board: Thornwall maze, ranked Firefly Jars, Dewdrops, Bellflowers,
## a Firefly Jar Calling)
- `D:\Projects\logs\enemy_code\shapes_video\v3\walking_lanes_board.mp4` (before / after, Packs 26 and Stream 27).
- `D:\Projects\logs\enemy_code\shapes_video\v3\drift_types_board.mp4` (Stream 27, Packs 26, Single file 37, Few
  and tough 29, big Packs 70). Parts `dt_0..4.mp4`, `wl_0..1.mp4`; scenes `*.json` in the same folder.
- Note: the board's Wardens cluster near the start, so most hits happen there.
- Extract frames with ffmpeg into your own subfolder of this round folder (never C:):
  `D:\Projects\ffmpeg\ffmpeg-9.0.2-essentials_build\bin\ffmpeg.exe -ss <s> -t <s> -i <video> -vf "crop=w:h:x:y,fps=10,tile=5x2" <out>.png`,
  then read the PNG. No new captures (that runs Godot).

## Code and docs
- Shapes: `scripts/run/drift_shapes.gd` (PACK_SIZE 6-8, PACK_SIZE_ACT1 4-5, big Packs: PACKS_BIG_COUNT 6 packs
  when a Packs drift has more than 6 × 8 = 48 nightmares, PACK_GAP, PACK_LEAVES), `scripts/run/drift_roller.gd`
  (shape roll; SINGLE_THIN_MAX 0.25 at ~127 / ~316 / ~536). enemy_design.md "Drift shapes" and the act tables.
- Lanes: enemy_design.md "Walking lanes" (retune); `scripts/enemy/enemy.gd` `_update_lane`, `LANE_*`;
  `scripts/enemy/enemy_spawner.gd` `_jostle_lanes`, `JOSTLE_*`. Y-sort follows the node, not the drawn body.
- Flyers: enemy_design.md "Flyers" (route flyers, never in packs; the Pall covers a walker and shares its blows).
- The payoff today: the dispel crack and motes (`enemy.gd` `_cleanse` / `_burst_into_motes`), `Sound.play_dispel`
  (`scripts/audio/sound.gd` ~210: close dispels only get quieter, never a climbing chime; no Dew sound per kill),
  `SoundHooks`, `Fx` (`scripts/fx/fx.gd`: budget / lite), `DewPopup`, `DamageLog` + `CombatCallouts`,
  `CloseCalls`, Reactions and their chains (`scripts/combat/reactions.gd`). Owner rules in
  `documentation/audio_direction.md`.
- Known fact from Enemy Code's roller test: **Single file rolled 143 times against about 1,000 Packs**, because the
  25% thinning cap (SINGLE_THIN_MAX) turns most Single file rolls into Streams.
- Earlier rounds: `D:\Projects\logs\enemy_council\rounds\2026-10-24\verdict.md`, `2026-10-24b\verdict.md`.

## The owner's five questions (answer all five in your seat's terms, with exact numbers)
1. Packs and big late packs: are 6-8 a pack, act 1's 4-5, and 6 big packs from 48+ nightmares right for that feel?
2. Walking lanes: do 0.2-cell lanes plus jostle bunch enough, or should packs walk tighter so they read as one clump?
3. Single file is rare (143 vs ~1,000 Packs): fine, or should Balancing loosen the thinning cap?
4. The payoff: what makes a group wipe feel great (dispel chain sound and visuals, Dew pops, a "cleared the pack"
   beat)? Who builds each piece?
5. Anything that would fight it: y-sort overlap in tight clumps, the Pall shielding pack members, flyers pulled
   out of packs.
Rulings with exact numbers and an owner chat per change. Read-only: no code changes.

## Seat focus this round
- **B (build player):** which builds and Calling lines get the wipe moment, which never do, and whether more
  crowds would make one area board answer everything (the "one board answers every drift" problem shapes fixed).
- **W (Warden roster keeper):** which Wardens and forms deliver a group wipe (area, chains, pulses, clouds,
  bursts), per family; does any family never get the moment; does more crowding over-reward area forms.
- **T (tower defense veteran):** what makes a wipe feel great in other games (Bloons pops, Kingdom Rush artillery,
  Vampire Survivors-style chains), readability of a wipe at game zoom and on a phone, and the "cleared the pack"
  beat.
- **S (systems and code keeper):** pack sizes / gaps / big packs in code, how tight lanes can get, y-sort in
  clumps, the Pall and flyer rules vs packs, the cost of many dispels in one frame (sound voice limits, Fx budget,
  DewPopup count, the phone).
- **P (pacing and balance, plus payoff):** how often a block should have a wipe moment, Single file rarity and the
  thinning cap, Dew and leaves when packs grow, and the sound / visual payoff curve within audio_direction.md.
