# Round 2026-10-24d: the whole roster after today's changes

**Owner asked (2026-10-24):** "Can you go over all the nightmares once you're done, make sure they fit the council
standards." So this round is not one change: it is every nightmare in `resource/enemy/*.tres` (38 files: everyday
kinds, splitter children, followers, summons, the act 1-4 boss pools, the Hollow Oak variants and the three new
route flyers), judged against the council's one question and today's systems.

**Today's changes the roster must now fit** (all committed; Enemy Code unless named):
- Drift shapes: Stream / Packs / Single file / Few and tough, big late packs sized to the window (4-8 packs,
  2.6 s each), flyer caps, Few and tough's Deeply Blighted share a 6-leaf cap, a leaked pack 6 leaves at most.
  `scripts/run/drift_shapes.gd`, `scripts/run/drift_roller.gd`; enemy_design.md "Drift shapes" (incl. "More of
  the group wipe"). Commits ae4239c6, d3ff18a9, cdd6ed4e, c7bde1ee, f952ddb7, 7ac008ac, d235a512, b49a97eb.
  Played shares (60 seeds): Packs 97-100%; Few and tough 63% / 81% / 94% (acts 2-4); Single file 89% / 72% / 47% /
  27% (acts 1-4, accepted by Balancing).
- Packs never take flyers, ROLLING, LEAP, BURROW or WANDER kinds (`DriftShapes.LOOSE_TRAITS`); Few and tough leads
  with a heavy non-splitter; Single file a heavy lead; the Pall is never rolled into Few and tough.
- Walking lanes (visual only), retuned: enemy_design.md "Walking lanes"; 614ec352; y-sort by drawn body 3e3d76e1.
- Route flyers: Night Kite (41), Gloamwing (69, drops at 3 Soaked + Drowsy), Pall (92, covers a walker, shares
  blows); grounding fix; flyer caps 4/5/6 by act; flyers never elites. enemy_design.md "Flyers"; 1770f105,
  f12c2bae, 42626120 (art), Roguelite's on_route() 05c7a86f and Hollow Wind 3de769df.
- Compact status icons in crowds (0fd6b2fb, c8672a38); the group-wipe moment: pack_wiped signal, pack_bloom
  effect, Sound's swell (d235a512, 7d29325b, Sound 43f97103).

**Earlier rounds to read** (rulings that still hold): `documentation/enemy_council_review.md` (all sections) and
`D:\Projects\logs\enemy_council\rounds\2026-10-24`, `2026-10-24b`, `2026-10-24c` (`verdict.md` each).

**For each nightmare, answer within your seat:** does it make Wardens and Dream builds feel good today? Does it fit
the shapes and lanes (packable or loose, a fit Few and tough / Single file lead, flyer rules)? Is its card text
(trait_text, intro_lines, hint, title, tips; Kind and Kind line) clear and consistent with enemy_design.md and its
.tres numbers? Is its art final or still a placeholder (`tint` / `sprite_scale` on a borrowed sheet)? Flag anything
in the .tres, code or docs that disagrees. Group the everyday kinds by act; bosses by pool. Keep each nightmare to a
line or two unless it has a real problem.

## Added by the lead (Enemy types design chat)
- **The roster in one file:** `roster.md` in this folder has every field of all 38 .tres (read it first; open a
  .tres, its SpriteFrames or code only to check something). Kind ints: 0 Armoured, 1 Flying, 2 Hidden, 3 Swarm,
  4 Fast, 5 Plain. Trait ints: 0 None, 1 Flying, 2 Rolling, 3 Trample, 4 Leap, 5 Burrow, 6 Wander.
- **The standards:** `D:\Projects\logs\enemy_council\briefs\standards.md` (A design, B Kinds and defences, C
  fairness, D builds and Wardens, E text, F look). Judge every nightmare against every standard your seat covers;
  report failures and near-misses, not passes.
- **Seat focus (each seat audits ALL 38 through its lens):**
  - **B (build player):** D1-D2 and A2: dead builds, trap cards, a nightmare that makes one board answer
    everything; every Calling line has nightmares it shines on.
  - **W (Warden roster keeper):** A2, B1, D2: each starting family's answer from its base Warden; the Kind
    matches the Warden tags that answer it; "Can't hit flyers" Wardens vs each flyer.
  - **T (tower defense veteran):** A1, A3-A6, C1-C4, E4: a distinct test per nightmare, readable at a glance,
    fair; duplicates or nightmares with no job.
  - **S (systems and code keeper):** B2-B3, C2-C3, E1 and data consistency: stale fields (`resists`, `weak_to`,
    `leaf_cost` vs the bite rules, `kind` vs behaviour), `intro_drift` / `roll_tags` vs the act tables, traits vs
    shapes, placeholder art (F3), data that contradicts enemy_design.md. Cite file and field.
  - **P (THIS ROUND: wording and look keeper, replacing pacing):** E1-E4 and F1-F2: every trait_text /
    intro_lines / hint / boss text against the text rules and what the nightmare really does; stale mechanics in
    text; look and silhouette notes.
- **Output:** `seat_<letter>.md` here, under ~1,800 words: a verdict line; a **table of failures** (nightmare,
  standard, what's wrong, the fix with one meaning, owner chat); near-misses; open owner calls. Read-only: no
  edits, no Godot, no tests.
