# Seat T (tower defense veteran: maze and fairness), round 2026-10-24c: more of the group-wipe moment

Footage read: `dt_0..4.mp4`, `wl_0..1.mp4` (frames in `seat_T_frames\`), the capture logs and scene JSONs. Code read:
`drift_shapes.gd`, `drift_roller.gd`, `enemy.gd` lanes, `sound.gd` `play_dispel`, `dew_popup.gd`,
`combat_callouts.gd`, `fx.gd`, starter `resource/tower/*.tres`, audio_direction.md "Dispel".

## 1. Verdict
**Feels good with fixes.** The bunched pack is the right picture, and the drift 26 board shows it. The wipe itself
is quiet, though: eight sighs that each get softer, eight "+2 Dew" popups and no beat that says "that was one pack".
The 107-nightmare big Packs come out as pillars of status glyphs that you can't read at 0.62 zoom.
More wipes should come from tighter packs along the route and from the player's corners, plus one pack-level
payoff. They should not come from more Packs drifts.

## 2. What works (keep)
- **The drift banner says the shape** ("Drift 26 of 100 · Packs", every frame of dt_1). The player can see it coming,
  which is the Kingdom Rush standard.
- **Packs of 6-8, one kind, about 5-6 s apart** read as distinct targets at 1.4 zoom (wl_0 frames 12-20 s). You can
  watch one clump enter a Bellflower ring.
- **Lanes narrow to 0.5 at turns** (`enemy.gd:278-279`). The clump tightens at the corner the player built, so the wipe
  spot is a maze decision. Keep this. It is the strongest maze link the wipe has.
- **The leak cap per pack** (`drift_shapes.gd:37-38`, 3 leaves per 8). A missed clump is a bounded, readable loss and
  never 8 leaves in 2 s. This is fairer than Bloons' stacked-lead leaks.
- **Audio rule "no climbing combo"** (audio_direction.md ~421). It's correct for the theme. Bloons' pop crunch is a reward
  sound, and this game deliberately isn't one. The beat must come from somewhere else.

## 3. Problems, ranked

**P1. A wipe has no "cleared the pack" beat.** *Feel:* the pack dies as eight separate, fading events.
`play_dispel` drops each close dispel 1.5 dB down to −6 dB (`sound.gd:56-58, 216-219`), so the eighth kill is the
quietest. Each member pays its own small share through DewPopup (`dew_popup.gd`, 0.9 s), so you get eight "+2" in one spot.
CombatCallouts has no group word (`combat_callouts.gd:14`). In Kingdom Rush one shell lands on many and makes one
boom. In Vampire Survivors one gem shower follows a chain. Here nothing marks the whole.
*Fix (one meaning: a pack wiped = every walking member of one `PACK_META` key, at least 4, dispelled within 2.5 s
of the first member's dispel; flyers and loose kinds never count):*
- Enemy Code: emit `pack_cleared(key, size, centroid)` from the spawner when the last member of a key goes.
  Split children count with their parent's key.
- Main Merger: one merged DewPopup "+N Dew" at the centroid (the sum of the members' shares) replaces the members'
  own popups for that window. The CombatCallouts word is **"Pack cleared"**, a fact, no "!", throttled 1 per 4 s.
  Add a rest report line "Packs cleared: N of M".
- Sound (through SoundHooks, Main Merger): on `pack_cleared`, one **longer warm tail** on the last dispel. Its length
  grows with size (0.6 s + 0.1 s per member, cap 1.6 s), and it never gets louder or higher in pitch. That keeps "blend
  into one wider, warmer glow" literal.
- Enemy Assets: one soft warm bloom about 1.5 cells across at the centroid, 0.35 s, where the members' motes gather.
  It goes on the Fx budget's lite path (`fx.gd:23`, 6 full per second).

**P2. Packs are snakes, not clumps, so most area Wardens hit only part of one.** *Feel:* the ring catches 4 of 8, and the
rest trickle out one at a time. In-pack spacing is half a cell at the kind's speed (`PACK_CELLS 0.5`, `drift_shapes.gd:31`).
That makes a pack of 8 3.5 cells long and 0.4 cell wide. The starter area answers are small: Bellflower pulse range
2.0 (`bellflower.tres:25`), Dewdrop splash 0.6 (`dewdrop.tres:37`). A 1.0-cell splash (Puffball, Cairn) covers
about 3 members.
*Fix:* `PACK_CELLS` **0.5 → 0.35** for Packs only. A pack of 8 is then 2.45 cells long and fits inside one
Bellflower ring on a straight path. Keep `PACK_GAP_FLOOR` 0.2 s. Do **not** narrow the lanes (Q2). Owner: Balancing Discussion
decides, Enemy Code builds. Check it against the v3 videos, as enemy_design.md "Protect the crowd feel" requires.

**P3. Big late packs are illegible and leak in a lump.** *Feel:* at drift 70, 107 nightmares make 6 packs of about 18. Each
arrives within `PACK_SPAN_MAX` 3 s (`:43, 279`), about 0.18 s apart, so 18 bodies sit in about 2.3 cells. On screen
(dt_4 frames 12-21 s) that is a column of "Z" stacks, digits and bars. No body shows, and the HUD resource panel sits
over the start. One such pack leaking costs 3 × ceil(18/8) = **9 of 15 leaves** in about 3 s. Readable on PC, a guess
on a phone.
*Fix:* cap a big pack at **14**. Use packs = max(`PACKS_BIG_COUNT` 6, ceil(count / 14)): 107 gives 8 packs of about 13-14,
and the cap is 3 × 2 = 6 leaves each. The gap floor stays 2 s. Owner: Balancing Discussion, then Enemy Code.

**P4. Glyph clutter hides the clump.** *Feel:* in any tight pack the status rows float above the bodies as a stacked
wall (wl_0 frames at 14-16 s, dt_4 throughout). That reads as noise, not as eight nightmares about to break.
*Fix:* below a view zoom of **0.9**, drop the stack digits from status dots and keep the coloured dots. Show a health bar
only once the nightmare has taken damage, and hide it again 1.5 s after it is full. Owner: Enemy Code (the enemy HUD,
`_hud_root` in `enemy.gd`). Look: UI chat.

**P5. The footage can't judge late wipes.** At drift 70 the board killed nothing. Dew stayed at 99999 and the field
held at 141 from t=15 to t=30 (`big_packs_on.log`). All Wardens sit near the start, so in wl_0 after about 20 s whole packs walk on
untouched. *Fix:* one more capture per board with a drift-strength board (rank V, about 20 Wardens at drift 70) and
Wardens on a mid-route hairpin, before anyone tunes P3. Owner: Enemy Code (asking costs nothing; the run itself
waits on the owner's go-ahead for Godot time).

## 4. The owner's five questions
1. **Pack sizes.** 6-8 is right (Legion TD 2 makes every wave a clump, and the wipe stops meaning anything). Act 1's 4-5 is
   right for starter Bellflower and Dewdrop reach. Keep 6 big packs from 48+, but cap them at 14 per pack (P3).
2. **Lanes.** 0.2 cell plus jostle is enough across the path (the sand band is about 0.55-0.6 cell, round b). The clump
   comes from along the route: PACK_CELLS 0.35 (P2). Tighter lanes would stack bodies into one blob, and the
   before/after in wl_0 already differs only a little at 1.4 zoom.
3. **Single file rarity.** 143 against about 1,000 is too rare. Single file is the drift that tests a board built only for wipes.
   Without it, "one area board answers everything" comes back, and the wipe stops being earned. Raise `SINGLE_THIN_MAX`
   **0.25 → 0.35** (`drift_roller.gd:127`). The target in Enemy Code's roller test is **at least 250 Single file per 1,000
   Packs**. If that misses, Balancing loosens `SINGLE_GAP` 1.5 → 1.25 s. Owner: Balancing Discussion.
4. **The payoff.** See P1. A merged Dew popup and "Pack cleared" (Main Merger), a longer warm tail with no pitch or
   volume climb (Sound through SoundHooks, Main Merger), the centroid bloom (Enemy Assets), `pack_cleared` (Enemy Code),
   and the rest report count (Main Merger). On a phone the merged popup and the one bloom are what read. Eight popups don't.
5. **What fights it.**
   - *Y-sort:* by node at 0.35 spacing, pack members overlap about 40% on vertical runs. That's acceptable once P4 removes the
     glyph wall. Re-judge on the P5 capture.
   - *The Pall:* covering a pack member and sharing its blows means "all but one". That's fine as a test, but a covered
     member must not block "Pack cleared" forever. Dispelling the Pall and its walker inside the window counts.
   - *Flyers:* flyers pulled out of packs is right, because loose flyers are a separate target for single-target Wardens.
     They must never count toward or against a wipe (P1 definition).
   - *Headlong* merges packs into a crowd. The player chose it, and `CROWD_MAX` is waived only there, so that's fair.
   - *Waymark:* shedding statuses mid-pack is a planned beat and doesn't cut against the wipe.

## 5. Builds and Wardens
- **Shine:** Bellflower and the Keeping Time rings at a hairpin, Dewdrop plus Firefly chains (Stormcap and Thunderhead,
  4 targets) on a Damp pack, Puffball, Cairn, Rockslide and Old Mountain splash (1.0-1.5), Morning Fog clouds (1.25).
  At PACK_CELLS 0.35 all of them catch nearly a whole pack.
- **Suffer:** pure single-target boards (Firefly Jar base, Sporeling base with no Spread) get no wipe moment. That is
  correct, as long as Single file gives them their drift (Q3).

## 6. Open questions for the owner
1. **"Pack cleared" on screen:** do you want the word, or only the merged Dew popup and the bloom? The word is a fact, not advice.
2. **The Pall:** may it cover a pack member at all, or only loose walkers?
3. **Big packs:** do you accept the cap of 14 per pack? It gives more packs per drift and fewer bodies in each.
