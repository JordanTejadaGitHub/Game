# Enemy Design Council review

Skill: `.claude/skills/enemy-design-council`. Seat reports per round in `documentation/enemy_council/<date>/`. Newest round first; earlier rulings that still hold stay.

## Enemy Design Council, round 2026-10-24d: full roster audit (38 nightmares)

Owner: "Go over all the enemies with the enemy council, make sure they fit council standards." Standards:
`briefs/standards.md` (collected 2026-10-24). Seats B W T S, P as wording and look keeper. Reports
`seat_<letter>.md`; roster dump `roster.md`. Read-only; nothing run.

### Verdict: feels good with fixes (all five)
The systems hold in code: no damage types read anywhere, every Armoured kind has a shell and a cracked sheet,
flyer caps / grounding / the Gloamwing drop / the Pall's exclusions are built as ruled, the leak caps hold, intro
drifts 41 / 69 / 92 match the act tables, and **all 38 have their own art** (F3 passes) (S W P). Every starting
family hits every flyer from its base Warden up; only 6 forms in the roster can't hit flyers (W). Bosses meet the
text rules (P). What fails is a handful of nightmares whose ability or Kind no longer does what its card says,
two live balance bugs, and stale text and docs.

### Spot-checked by the lead
`enemy_spawner.gd:49` boss bites [6, 8, 10] (Balancing 2026-10-19); `enemy.gd:3265` Weeper mends every nightmare in
reach with no cap; `whisper_swarm.tres` kind 3 (Swarm), health 180, nothing else; `gravecrawler.tres` kind 2
(Hidden); `puddles.gd:1418` "Flyers are never in water"; `enemy_statuses.gd:640` ignores_slows; `gloamwing.tres`
prints `{soaked}` (IconInfo knows `damp`).

### A standard the lead got wrong
**A5 (route rule):** the owner's rule "the route is the player's plan" is about Dream cards (no card moves, blocks
or re-routes the maze on its own; Gravestones rejected). enemy_design.md explicitly allows maze-changing bosses
(the Hollow Stag's trample, the Hollow Oak's saplings) as long as the start keeps a route. So the Stag and the Oak
**pass**; the standard is corrected. (B T S flagged them in good faith.) Only the Thorned Oak's text is wrong: it
says saplings "bend the path" but they're planted beside the route (T).

### Fix first (no owner call needed: bugs, or text that's false)
| # | Nightmare | Standard | Problem | Fix | Owner |
|---|---|---|---|---|---|
| 1 | every route flyer, the Moth Queen | D1, decision 4 | Puddles skips every flyer (`puddles.gd:1418`, 873, 1444, 1538, 1581): Fathoms, Crushing Depth, Riverside linger and the surge slows do nothing to the act 3 default boss, while Black Pond's spill does see flyers (B) | route flyers count as in the water they fly over (as decided 2026-10-24); ground slows stay ground-only by their own clause | Roguelite Code |
| 2 | Weeper (packs of them) | C4 | mends stack with no cap (`enemy.gd:3265`): a pack of 7-8 heals each member 10-14%/s (S W) | a nightmare is mended by one source at a time (the strongest); menders don't mend menders | Enemy Code |
| 3 | Ash Crawler | D1, C3 | tagged `heavy` and packable: it leads Single file / Few and tough or fills a pack, and its ash strips Poisoned from everything behind it, so Spore Print is off for the drift (B W) | drop `heavy` (keep `special`) and make it a loose kind (never packed, never a lead) | Enemy Code |
| 4 | Widow, Mourner | C1, C4 | outside a pack, dispelling one late costs more leaves (6 Creeps / 3 Sobs) than letting it in (1) (T) | one parent's children share a 2-leaf cap, like a pack | Enemy Code |
| 5 | Night Mare (echo at 100) | D1 | Keeping Time's once-per-nightmare marks (Last Bell, Halfway Bell, Midnight) never reset on a lap (`keeping_time.gd:290-296`, 1154-1160), unlike Spore Print and Puddles (B) | clear them on `lapped` | Roguelite Code |
| 6 | Gloamwing | E1, B1 | prints a raw `{soaked}`; says "tolls" (a Keeping Time Calling word); keeps the Flying badge after it drops (P W T) | `{damp}`; "three stacks of Soak and Drowsy together"; after the drop it shows as a walker (no Flying badge) | Enemy Code (text), Main Merger (badge) |
| 7 | Crow; Scarecrow tip 2 | E4 | "Wardens all along the path can hit it": false for "Can't hit flyers" Wardens (P) | "every Warden that hits flyers can reach them" | Enemy Code |
| 8 | Hollow Stag tip 3 | E4 | "Rain douses the ghost-fire" is the removed water weakness (S P) | replace with a fact tip (e.g. its charge on straights of 4+) | Enemy Code |
| 9 | Whisper Swarm | B1, E4 | Kind Swarm and all three lines promise a cloud area hits catch; it's one 180-health body since ×0.5 went (T S W P) | owner call below; until then nothing | Enemy Code |
| 10 | Thorned Oak | E4 | "bend the path": the saplings stand beside the route (T) | say what they do: they take building room beside the path | Enemy Code |
| 11 | Watcher, Weeper, Will-o'-Wisp | E4 | "dispel it first" asks for a target choice only Moonstone / Standing Stone can make (T W) | state the fact instead ("It wakes Drowsy nightmares within 1.5 cells"); advice after a colon may name the maze or a fact, never a Warden type, family or status (P, the no-hand-holding rule) | Enemy Code |
| 12 | several | E2, E4 | descriptions / hints repeat the title on the Phantom, Lantern Bearer, Wraith, Drowned One, Watcher, Dream Thief, Night Kite, Ash Crawler (+ ~8 partly); missing facts: the Watcher removes all Drowsy, the Night Hound sprints after 3 cells ("long" is wrong), the Drowned One and Phantom can't gain Root, the Drowned One can't gain Drowsy, Black Tears has no rate (P) | replacement text is in `seat_P.md` | Enemy Code |
| 13 | Kind lines | E4 | Fast says Soaked slows (it doesn't) and "holds" (old word for Root); Hidden says "until a Warden reveals it" (the Wisp reveals too) (P W) | Fast: corners and Rooted / Drowsy; Hidden: "until something reveals it" | Main Merger (Kind glossary) |
| 14 | Night Mare, Hollow Oak | C1, E4 | the hover panel prints "Leaves 3 / 5" (`enemy.gd:1883`, `nightmare_info.gd:107`) though they drain instead (S) | show "Drains at the Heartwood" for drainers | Main Merger (+ Enemy Code's getter) |
| 15 | icons | E4 | the Hidden icon on the Huntsman's Pack and the Lamplighter's Cold Light, Soak on Black Tears, grief shaped like Wander (P) | icons that mean their own thing | Main Merger / UI Code |
| 16 | docs | E4 | boss bites written 10 / 10 / 12 (code 6 / 8 / 10), pack 3 leaves (code 6), Stats table out of date on ~13 values (Husk leaves 1 in data), boss resist / weak columns still shown, the Night Mare "3 leaves"; CLAUDE.md still describes ×0.5 / ×1.5 resistances (S P) | enemy_design.md and standards fixed by the lead (the .tres is the source); CLAUDE.md lines to Main Merger | lead, Main Merger |
Word: **"heal"**, not "mend", in player text (P): the Weeper, the Mourning Mother, the icon.

### Owner calls (lead's pick first)
1. **Whisper Swarm:** make it **5 motes of 36 health that move as one pack** (a real Swarm; fits the crowd feel), or
   re-Kind it Plain.
2. **Gravecrawler:** keep it Hidden and **a Warden that reveals in range stops its burrow** (gives Reveals Hidden
   Wardens a job), or make it Plain.
3. **Drowned One:** slows work on it **at half strength** (it keeps its Drowsy and Root immunity), so Puddles'
   Stream line and Heavy Going aren't blanked; or keep it immune to slows.
4. **Huntsman:** its half damage while a hound is near is a second damage reduction (B2). Pick: **each blow at him
   is shared half and half with his nearest hound** (the Pall's rule), or keep it as an approved boss exception.
5. **Act 2's Few and tough is always Deeply Blighted Husks** (the only heavy kind before drift 63) (T): introduce the
   Shellbound earlier (about drift 44), or accept it.
6. **Husk leaves:** the data says 1, every doc said 2: keep 1 (lead: the data wins; docs fixed).

### Near-misses (for Balancing / Tower Discussion)
Dread shells tax fragment builds (jumps, repeats, spills): measure on a Shellbound Few and tough drift (B). Act 3
brings three Bellflower status testers in 6 drifts while Firefly Jar has almost none; Bellflower has no reveal
form (W). No starting base Warden is heavy, so in the demo Sporeling and Bellflower have no tagged answer to the
Husk (W). The Dream Thief's stolen Dew has no pack cap (T). Any Warden beside the path reveals a Lurker, so it tests
no build (B).

## Enemy Design Council, round 2026-10-24c: more of the group-wipe moment

Owner: "I like it ... Also like the feel of a big group being wiped and them bunched up like that." Question: how
do we get more of that moment without making every drift a crowd or making one board answer everything? Seats B
W T S P (P: pacing plus the payoff). Reports `seat_<letter>.md`. Read-only; nothing run. Footage: the v3 board
videos (seed 4242). Limit: the drift 70 board dispelled nothing, so no late wipe was seen (T S).

### Verdict: feels good with fixes (all five)
Packs already make the moment: one kind per pack walks at one speed and stays together, flyers and loose kinds
stay out, leak caps hold (S W). One Packs drift per block from act 2 is 3-6 wipe chances a block: often enough;
**don't add a second Packs drift** (B P). What's missing is the **payoff**: nothing knows a pack was wiped, and
a wipe sounds smaller than one dispel (all five). And the **counter-shape is too rare**: Single file plays in
about 14% of its planned slots, so area boards are seldom tested (B T W S).

### Spot-checked by the lead
- `sound.gd:54-58`: the comment promises dispels that "blend into one softer swell", but the code only makes each
  clustered dispel 1.5 dB quieter (down to -6 dB), with 4 voices and a start throttle; a wiped pack of 8 is ~2 dB
  over one dispel (P S).
- `drift_shapes.gd`: `PACK_CELLS` 0.5, `PACK_SPAN_MAX` 3.0, `PACK_LEAVES_PER` 8 (a big pack of 40 can cost 15
  leaves), `SINGLE_GAP` 1.5; `drift_roller.gd` `SINGLE_THIN_MAX` 0.25 with a Stream fallback.
- The Pall refuses bosses and Deeply Blighted but not pack members (`enemy.gd` `_update_pall`).

### Rulings
**Q1 Packs and big packs**
- Keep **6-8 a pack, 4-5 in act 1** (all five: they match the Wardens' count caps, 4-8: W).
- **Big packs:** pack count = clamp(ceil(nightmares / 14), 6, 8), so a pack stays at most 14 up to 112 nightmares
  (T 14, S 6-8 packs); `PACK_SPAN_MAX` 3.0 → 2.6 so 8 packs still fit the window with 2 s gaps (S P). Fix the
  big-pack test counting arrivals, not splitter children (S).
- **Any pack takes at most 6 leaves** (was 3 per 8 members: a pack of 40 cost 15, a whole run), the same 6 as Few
  and tough (P).
- Wardens' target caps (Firefly jumps 6, Maelstrom 8, chains 4…) stay; a ×1.5 raise on packs over 12 (W) goes to
  Balancing's sim, not shipped (B against).
- **Always a Packs drift in drifts 11-15** (P: ~12.5% of runs see none before drift 26).

**Q2 Tighter clumps**
- Lanes stay **±0.2** (all). Bunch along the route instead: **`PACK_CELLS` 0.5 → 0.4 from act 2** (act 1 keeps
  0.5) (B W; T S asked 0.35; P against any). Gate: Balancing's wipe-rate sim (below) before going to 0.35.
- Land the compact crowd icons (enemy_design.md "Status icons in crowds") **before** tightening (S).
- **Y-sort by the drawn body:** the lane moves `sprite.position` and each enemy y-sorts on it (S P6), since
  tighter clumps make node-order flicker visible.

**Q3 Single file**
- Keep `SINGLE_THIN_MAX` 0.25 (P S: thinning can't rescue late drifts of 75-240). Instead:
  - **`SINGLE_GAP` by act: 1.5 / 1.2 / 1.0 / 1.0 s.** In acts 3-4 a Stream arrives 0.1-0.4 s apart, so 1.0 s
    still reads as single file.
  - **Retry once with the Heavy template** before falling back to a Stream (P W).
  - Target: at least **60% of planned Single file slots play** in the roller test (B; T's 250 per 1,000 Packs).

**Q4 The payoff** (one moment, one fact, no reward: W P; audio_direction.md: a dispel ends a nightmare, never a
reward sound)
- **"Pack wiped"** = every walking member of a pack of 4+ dispelled, none leaked, first to last within 3 s
  (B T W S definitions merged). Enemy Code: signal `pack_wiped(key, size, centre, top_source)`.
- **Sound Code: `dispel_swell`** (the swell audio_direction.md already asks for): from the 5th dispel within 700
  ms and 3 cells it takes the place of dispel voices past the 2nd; tuned air on the D chord, wider, ~1.2 s, no
  pitch climb, no chime, no music duck; at most **+1.5 dB** over one dispel's peak, so it is fuller, not louder
  (P S; T's longer tail folds into it). It works for any crowd, not only packs.
- **Main Merger:** one **"+N Dew" popup per wipe** that counts up, in place of the members' popups; damage numbers
  merged per pack every 0.25 s; a small **"Pack ×N"** callout once per wipe; rest report **"Packs wiped: 5 of 6"**,
  with the Warden that dealt the most. **No bonus Dew** (W P).
- **Enemy Assets:** one soft warm bloom at the pack's centre, ~1.5 cells, 0.6 s (a still flash under reduced
  motion) (T).
- **Enemy Code (phone budget):** halve dispel motes past 8 dispels in 0.5 s (S).

**Q5 What fights it**
- **The Pall never settles on a pack member** (B W P; S: acceptable either way): one shielded straggler spoils the
  wipe.
- Flyers stay out of packs (all). Y-sort and icons: above.

**Who gets the moment** (B W): Lantern Light's Support line, Puddles' Black Pond and Wave, Keeping Time's Peal and
Sleeping Hall, Spore Print's Windfall and Rot Bloom, Headlong; Focus lines rarely, and that's right (Few and tough
and bosses are theirs). Sporeling's base Wardens get no wipe unless it's the Calling: Balancing checks Fairy
Ring's ring cap holds a pack of 8 (W).

### Sims for Balancing (P S W)
Wipe rate per Calling line at drifts 30 / 60 / 85 (crowd lines >= 60%, Focus lines 15-35%) at `PACK_CELLS` 0.5 /
0.4 / 0.35; worst single-pack leaf loss; planned vs played shapes per act; the ×1.5 target-cap raise on packs over
12; Fairy Ring on a pack of 8.

### Open owner calls
1. A re-capture of a late wipe (drift 70 with a board strong enough to wipe it): it runs Godot, so it waits for the
   owner's go-ahead (T S).

## Enemy Design Council, round 2026-10-24b: enemy movement

Owner: "Enemy movement looks off." Seats B (build player), W (Warden roster keeper), T (tower defense veteran),
S (systems and code), P (this round: motion and game-feel animator). Reports `seat_<letter>.md`, frames
`seat_<letter>_frames\`. Read-only; nothing run. Footage: `walking_lanes.mp4`, `drift_types_small.mp4` and the
.avi captures (seed 4242). Limit: every capture plants only Thornwalls, so attack and Calling cues were judged
from code (B W).

### Verdict: feels good with fixes (all five)
Packs now read as clumps, not beads, which is the picture crowd builds promise (B T W P). What looks off is three
motion faults, all numbers and easing, plus visual feedback still anchored to the logical position. No game rule
changed and none should (all).

### What looks off (spot-checked by the lead in `enemy.gd`)
1. **Lanes are wider than the drawn path (all five).** The sand band is about 0.55-0.6 cell wide; `LANE_MAX` 0.3
   (`enemy.gd:267`) + a body's half-width puts bodies on the path's edge and over dark grass, where dark
   nightmares lose their contrast (worst on a phone), and over obstacles at inside bends.
2. **Sideways sliding outruns the walk (all five).** A new lane is rolled anywhere in −1..1 (`:1960`) and eased
   at `LANE_EASE` 3 with no cap (`:1961`): slides start at 38-115 px/s while 13 kinds walk 35-58 px/s, facing
   forward. Slow nightmares skate sideways like on ice. This is the main "off" look.
3. **Corners whip (S P).** The sideways axis comes from the next route point (`:1963-1967`) and flips at a
   turn: outer bodies flick ~27 px in 0.3 s, inner ones slide backwards; stair paths zig-zag.
4. **Narrow gaps (T S):** `_update_lane` never reads `_gap_answer` (`:292`, `:1682`), so a squeezed walker in a
   half-cell gap is still drawn up to 19 px off centre, over the Warden beside it.
5. **Jostle (B T S P):** reach 0.4 cell is shorter than one body, so pairs stack into one dark blob (B P); the
   straight-line reach fires at every corner and pushes pairs twice (S); its clamp pins big packs to two rails
   at the path edges (T S).
6. **Feedback still lands on the logical position, up to 19 px beside the body (B W):** damage numbers and combo
   words (`damage_log.gd:425`, `combat_callouts.gd`), the Charged bolt and Live Wire (`reactions.gd:906/938/952`),
   the Lantern Light jump (`firefly_lights.gd:2640`), the Dewdrop splash ring (`tower.gd:3887`), pulse hit sheets
   (`tower.gd:3231`), the crit flare and status flashes (`enemy.gd:3106/965`), Keeping Time's ring pips
   (`keeping_time.gd:396-398`, 463), Calling threads (`class_kit.gd:448`). In a pack a number or a splash reads
   as hitting the neighbour. Projectiles, beams, the main chain, pecks and Reaction sheets are already right
   (`Tower.aim_at` → `get_body_position`, W).

### Rulings (numbers)
| Thing | Now | Ruling | Seats |
|---|---|---|---|
| `LANE_MAX` (Stream, Packs) | 0.3 | **0.2** cell | T .18, B .18, P .22, W .2, S .2 |
| `LANE_BIG` (bosses, big kinds, Few and tough elites) | 0.15 | **0.1** | T .08, B P S .10 |
| Single file | 0.1 | **0.06** | T .05, B P .06 |
| Flyers | 0.15 | **0.15** (no path edge in the air) | B T W S keep |
| New lane target | anywhere in −1..1 | **current ± 0.3-0.7**, clamped to ±1 | T B P S |
| `LANE_WANDER` | 3-6 s | **4-8 s** | B P S (T 5-9) |
| Lane easing | exponential, `LANE_EASE` 3 | **smoothstep, at least 0.8 s a move, sideways speed ≤ 0.25 × the walker's speed** | T .3, B .2, P .25, S .35 |
| Sideways axis | from the next route point, `LANE_TURN_EASE` 5 | **the rounded curve's tangent** (`_corner_curve`); fallback `LANE_TURN_EASE` 10 | S P |
| Near a turn | full lane | **lane × 0.5 within 0.5 cell of the turn's centre** | B (0.4), P |
| Narrow half-cell gap | full lane | **lane → 0** (eased at 14, exempt from the speed cap) | T S |
| `CORNER_ROUNDING` | 0.3 | **0.3** (keep) | T B W keep; P 0.4 |
| Jostle neighbours | same + next cell, straight-line 0.4 | **by route index ±1, along-route reach 0.55 cell, each pair once** | S B P |
| Jostle trigger | lanes < 0.25 cell apart | **< 0.15 cell apart** | T B |
| Jostle push | 1.2 lane units/s, clamped ±1 | **0.8**, through the same speed cap, **never past ±0.85** | B 0.8, T 0.6/±0.8, S ±1 |
| `LANE_SNAP_PX` | 0.25 | **1.0**, offset rounded to whole pixels (no pixel crawl) | S |
| Lane close-out | straight-line distance to the end | **route distance** over the last cell | S |
| Facing | from the node's travel | **keep** (with the slide capped it never needs to turn) | all |
| Y-sort | by node | **keep for now**; at 0.2 the overlap window shrinks; re-judge on the new capture | T S W |

**Where they disagreed:** jostle strength (T weaker, B and P stronger). Ruled: S's structural fixes remove the
corner false triggers and double pushes that caused both the blobs and the rails, so a moderate push (0.8) with a
±0.85 clamp answers both.

**Feedback rule:** anything drawn ON a nightmare (numbers, words, flashes, bolts, jumps, splash rings, pips,
threads) uses its drawn body position (`get_body_position`); anything on the GROUND (puddles, rings, mushrooms,
clouds) stays where the route is. No range, radius or targeting changes (W).

### Open owner calls
1. P's two ideas: a slow drift forward and back along the path (±0.08 cell, every 2-4 s) so Streams don't keep
   even spacing; a pack swaying together (one shared lane target). Lead: neither yet; re-judge on the new capture.
2. Walk-cycle speed following the drawn speed through bends (P, 0.7-1.4×): small polish, later.
3. Big Packs read as a faint smear: that's the art's translucency at density (T), an Enemy Assets question.
4. A re-capture after the fixes with real Wardens (a Firefly Jar, Dewdrop and Bellflower maze) and one Calling
   run, so the next judgement sees hits, numbers and Calling cues (B W).

## Enemy Design Council, round 2026-10-24: drift shapes, walking lanes, new flyers

Seats: B build player, W Warden roster keeper, T tower defense veteran, S systems and code keeper, P pacing and
balance. Reports: `seat_<letter>.md` beside this file. Read-only; nothing was run.

### Verdict: feels good with fixes (all five seats)
Drift shapes give every Calling line a drift it loves and one that tests it, and keep the route the player's plan
(B T P). Walking lanes don't touch builds or pacing (B P W); how they look is reviewed in round 2026-10-24b. Route
flyers are the right fix for the Phantom's lesson (T W), but three live bugs and two loose rules would make the
new flyers feel bad until fixed.

Status found by S: shapes and lanes are **already built** (`scripts/run/drift_shapes.gd`, lane code in
`enemy.gd`; parse-checked, not run); only the three flyers are design-only.

### Fix first (spot-checked by the lead)
1. **Grounded flyers skip the maze (live bug, B T W S agree).** `Enemy.ground()` sets `passed_waymark = true` and
   lands the flyer on the nearest cell of the whole route; `_rise_from_ground()` sets its path to
   `[current cell, endPath]`, a straight line (`enemy.gd:2049-2092`). So Groundroot, Earthbind and Snag turn a
   route flyer (today's Crows) into a Phantom. **Ruling:** a route flyer rises back onto its own route (the route
   index it held, two legs if a Waymark stands), and `passed_waymark` stays what it really was; only through-wall
   flyers (Phantoms) rise straight. Owner: Enemy Code.
2. **Hollow Wind breaks every flyer cap (B T P S agree).** `omen_director.gd:564-573` swaps each non-flyer arrival
   for any flyer of the block, Phantoms included. **Ruling:** Hollow Wind draws route flyers only (Crow, Night Kite,
   Gloamwing; never the Phantom or the Pall), and the flyer cap is checked at schedule time after the Omens.
   Owners: Roguelite Code (Omen), Enemy Code (cap).
3. **The cross-kind flyer cap doesn't exist yet (S).** Only per-kind `drift_max`. **Ruling:** flyers of all kinds
   at most **4 / 5 / 6** in acts 2 / 3 / 4 (P), Phantoms at most 4 within that, applied after Omens; a flyer is never
   chosen as a guaranteed or Blight elite (S). Owner: Enemy Code.
4. **Few and tough is the leaf cliff (P).** Its 3-5 Deeply Blighted cost 2 leaves each and leak together uncapped
   (8-12), while a pack is capped. Confirmed: only packs carry a cap (`run_state.gd:241-249`). Owner call (below).
5. **The Pall needs exact rules before it's built (B W T S P).** Rulings that need no owner call: it never covers a
   boss or a Deeply Blighted; its effect applies after the dread shell; no Palls in Few and tough drifts; its
   teaching drift 92 is Palls over Shades, not Husks (W). Its damage rule and targeting are owner calls.
6. **Doc errors:** Pile-On is a free-hit card at a clump, not a "3+ nightmares" card (B; `calling_paths.gd:70`);
   Groundroot / Earthbind are Rootling, not a starting family, so the Night Kite's listed counter is wrong for most
   boards (T W). Fixed in enemy_design.md.

### Where the seats disagreed, and the ruling
- **Pall damage:** B "shares each blow half and half with the Pall"; W and S "half damage, Wardens target it
  first". Ruling: owner call. The lead recommends **sharing** (no second damage reduction, which the Kinds rule
  forbids; hit cards and Focus lines keep full value; the Pall still dies first under fire).
- **Gloamwing drop:** B "3 Soaked + Drowsy counted together, never raised by Brimming"; W "Soaked for 2 s". Today
  one Dewdrop splash drops it while Bellflower needs 3 Drowsy. Lead recommends **B's version** (fair to both
  families, readable as one counter on its card).
- **Flyer share:** W adds "at most a third of a rolled drift's arrivals" on top of the cap. Lead: adopt it; it
  costs nothing and keeps small drifts from being mostly flyers.

### Builds and Wardens
- **Shine:** Packs for crowd capstones, spill / waves, jumps, Tolls, Reactions; Single file for Spread lines,
  doses, streaks, long mazes; Few and tough for Focus lines, hit cards, boss capstones (Calling hits halve only on
  `is_boss`, `class_kit.gd:499`, so Deeply Blighted get full value: B).
- **Suffer:** dispel-count engines on Few and tough (Wild Growth, Hard-Won Rings); Calling ground setups ignore
  every flyer (`class_kit.index_of` returns -1 for flyers: Puddles' water, Spore Print's mushrooms, Keeping Time's
  primes; Lantern Light is fine: W S); the 6 forms that can't hit flyers (Fairy Ring / Elf Circle, Brood Cap /
  Hatchery, Undercurrent / Maelstrom: W). Every starting family answers flyers from its base Warden up (W).
- Only Moonstone and Standing Stone can pick targets, so "target priority" is no counter for most boards (W S).

### Numbers for Balancing
Flyer cap 4 / 5 / 6 by act, a third of arrivals at most; teaching drifts 41 with 4 Night Kites (not 6); the
gate's leak count to include bodies and health leaked, not only leaves (P); sims: flyers <= 25% of leaves lost
over 41-100, Few and tough worst decile <= 6 leaves, drifts 51-60 per shape, the intros 41 / 69 / 92, Hollow Wind
/ Moth Night / Leaf Fall blocks (P).

### Owner calls (all decided)
1. **Few and tough leaks: DECIDED (owner 2026-10-24): a Few and tough drift's Deeply Blighted take at most 6 leaves together.**
2. **Pall: DECIDED (owner 2026-10-24, ddd7c619): it shares each blow half and half with the walker it covers.**
3. **Gloamwing: DECIDED (ddd7c619): it drops at 3 stacks of Soaked and Drowsy counted together.**
4. **Route flyers: DECIDED (ddd7c619): they count on the route they fly over for maze and Calling route cards.**
5. **Dispel-count Legendaries: DECIDED (owner 2026-10-24) and already built (7573c842): a Deeply Blighted counts as 3 dispels.**
