# Seat B (build player, roguelite veteran): round 2026-10-24d, all 38 nightmares

**Verdict: feels good with fixes.** Most of the roster gives every Calling line a nightmare it shines on and one that
tests it. Three things make a build dead or a card a trap today. Puddles still treats every flyer as "never in water",
and the act 3 default boss is a flyer. The Drowned One blanks the whole Stream line. The Ash Crawler can lead a drift
and strip Poisoned from the whole line behind it. Two default bosses still re-route the maze. That last one is an owner
call.

Lines checked: Spore Print (Windblown > Drifting Spores > Spore Season / Heavy Air; Deathcap > Rot Bloom / Sprout Beds;
Clump > Trampled > Pile-On / Trodden; Throne > Elder Cap / Retinue; Shared Caps > Feeding Ground > Windfall /
Sporefall; Host Trees > Host Grove / Spreading Caps), Lantern Light (Strung Lights > Early Lamps > Carried Lights /
Late Lanterns; Lantern Alley > Parade / Passed Torch; Bonfire > Moth to Flame > Pyre / Banked Fire; Spreading Flame >
Flint and Steel / Tinderbox; Borrowed Light > Lantern Wake > Show the Way / Full Glow; Sightline > Constellation /
North Star), Keeping Time (Carrying Tune > Hand to Hand > Peal / Change Ringing; Last Bell > Curfew / Halfway Bell;
Steady Beat > Crescendo > Midnight / Twelfth Hour; Deep Tone > Double Time / Allegro; Accompaniment > Counterpoint >
Symphony / Coda; Tenor Bell > Ensemble / Sounding Board), Puddles (Stream > Backwaters > Mudflats / Sinking Mud;
Floodgate > Spate / Silt; Black Pond > Deep End > Breaking Wave / King Tide; Undertow > Fathoms / Crushing Depth;
Riverside > Open Water / Still Water / River Mouth line). Also the Legendaries Headlong, Wild Growth, The Walking Wood
and Waymark, Hard-Won Rings, and the hit cards (First Light, Gauntlet).

## Failures

| # | Nightmare | Std | What's wrong (player feels / cause) | Fix (one meaning) | Owner |
|---|---|---|---|---|---|
| 1 | **The Moth Queen** (act 3 default boss, `resource/boss/act_3/moth_queen.tres` `is_default`), plus Night Kite, Gloamwing, Pall, Crows | D1, A2 | The Puddles Focus line's boss payoff does nothing against the act 3 boss. `puddles.gd:1418-1419` skips every flyer ("Flyers are never in water") before `_pond_time`, `_in_pond`, `_still_water`. So Fathoms never builds, and Crushing Depth, which needs Fathoms' +50%, never pierces her 16,000-health fight. The water enter/leave loop (`:872-873`), the Floodgate surge (`:1581`, `:1604`), Stream / Mudflats slows (`:1444-1445`, i = -1 for flyers) and the upstream count (`:1538`) skip flyers too. Riverside, Open Water and Still Water linger never touch a route flyer. Black Pond's spill and Undertow *do* see flyers, through `water_of` → `index_of` → `on_route()` (`:585`, `:2213`, `class_kit.gd:365`). So one line both sees and ignores the same flyer. This contradicts owner decision 4 (ddd7c619: route flyers count on the route they fly over for Calling route cards). | A **route flyer** (`on_route()`) counts as in the water it flies over for Fathoms (and Crushing Depth), Riverside / Open Water / Still Water / River Mouth, Floodgate / Spate surges and Breaking Wave's count. Slows stay as written: a flyer over water is slowed only by Sinking Mud's own flyer clause (20%; bosses half), so that card keeps its meaning. The Phantom stays out. | Roguelite Code |
| 2 | **Drowned One** (61, `special`, packable) | D1, A2 | The Puddles Stream line is all slows: Stream, Mudflats, Sinking Mud, Floodgate, Spate, Silt. Heavy Going (the dew_focus core card) also needs a slow. `ignores_slows` returns ×1.0 for every slow (`enemy_statuses.gd:639-640`) and Heavy Going returns false (`puddles.gd:1030`). A Packs drift of Drowned Ones walks through a Stream maze as if the Calling weren't there. It is also Drowsy- and Rooted-immune, so Bellflower's base Drowse misses too. It is the only nightmare that makes a whole Calling line contribute zero. | **Slows on it work at half strength** (the boss rate every Calling slow already uses, `SLOW_BOSS_SHARE`). Keep the Drowsy / Rooted immunity and the "always Soaked" trait. Text: "Always has {damp}; slows hold it only half as well." | Enemy Code (owner call 1) |
| 3 | **Ash Crawler** (68, `heavy` + `special`) | D1, C3 | `heavy` makes it a legal Single file and Few and tough lead (`drift_roller.gd:569-574`). So a Deeply Blighted Ash Crawler walks first, and every nightmare behind it crosses its 3 s ash, which removes Poisoned (`enemy.gd:2589-2590`, `3268-3272`). For that whole drift, Drifting Spores and Spore Season lose their ramp, a Deathcap burst ("2 s worth of its Poisoned") deals 0, and Rot Bloom and the Calling's dispel mushroom never fire. Inside a mix, it is a fair "dispel it early" test. As a lead, it decides the drift for one Calling. | **Drop `heavy` from `roll_tags`** (keep `special`). It never leads Single file or Few and tough and walks inside mixed drifts. Single file and Few and tough keep Husk / Barrow Wight / Shellbound as leads in acts 3-4. | Enemy Code |
| 4 | **The Night Mare** (laps), and its echo under the Remembering Oak at drift 100 | D1 (minor) | Last Bell, Halfway Bell and Midnight Bell are "once per nightmare" marks (`LAST_DONE_META`, `HALFWAY_DONE_META`, `MIDNIGHT_META`, `keeping_time.gd:290-296`, `1154-1160`) and never reset on a lap. Spore Print restarts its bursts each walk (`spore_print.gd:146`) and Puddles keys water state on `laps` (`puddles.gd:1653`). A Keeping Time capstone player at drift 100 gets one Toll on the echo and nothing on later laps. | These three marks clear on `lapped` (the same rule as Spore Print: "laps and the Waymark start it again"). | Roguelite Code |
| 5 | **The Hollow Oak (Thorned, act 4 default)** and **the Hollow Stag (act 1 default)** | A5, D1 | Thorn-Saplings "bend the path". Trample knocks down Thornwalls "for good", which can open a shorter route. Both re-route the maze on their own, and both are default bosses: every first run sees the Stag, and every first win is against the Thorned Oak. Mid-boss, the route-built cards lose their board: Waymark's two legs, Backwaters ("passes the same Dewdrop twice"), which bell is the Last / Halfway Bell (worked out in `on_board`), Gauntlet's opposite sides, Cozy Corners and Switchback bends, Passing Thread's second stretch. The common brief's rule says no enemy re-routes the maze. | Owner call 2 (below). | Owner, then Enemy Code |

## Near-misses (keep, measure or watch)

- **Dread shells (Husk, Shellbound, Barrow Wight, Barrow King) tax fragment builds.** Each jump, repeat, spill and free
  hit is its own `take_damage`, and each loses up to `coat_per_hit` (`enemy.gd:3567-3571`). That includes Borrowed
  Light's third, Accompaniment / Symphony repeats at half, Black Pond's 25% spill and Retinue's half free hits. These
  Support lines run slow on a Few and tough drift of Deeply Blighted Shellbounds. The shell is a bounded pool
  (`coat_max`) and answers exist (Crushing Depth, Pyre crits, Lichenling, Elder Cap). So it is a test, not a dead
  build. Balancing should measure Borrowed Light and Accompaniment on a drift 80-85 Few and tough Shellbound drift.
- **The Mire Hag (act 2 default, drift 50)** sinks 3 cells every 6 s, or every 4 s once hurt. The Last Bell line is
  taken at the drift 25 rest, so the next boss can rise past the one bell that line is built on. Fair (her card says
  spread out), but it is the Last Bell player's worst boss. Keep.
- **The Withering Oak** withers the strongest Warden near it: the Black Pond's pond Warden, Elder Cap's throne, The
  Eldest. That is about 30% downtime ("never the same twice in a row"). A fair final test, and its card says so. Keep.
- **The Lamplighter** punishes cluster lines (Clump, Lantern Wake, Accompaniment / Sounding Board). The answers are
  snuffing, and The Walking Wood swapping a Warden out of the light. A good test, and a moment Walking Wood shines. Keep.
- **Barrow King** shrugs every 10 s, which tests every status line: Shared Caps, Riverside / Still Water, Spore Print.
  Mushroom doses refill up to 6 stacks at once and Crushing Depth / Pyre shine, so no line is dead. Keep.
- **Lurker:** any Warden within 1.5 cells reveals it (`enemy.gd:541`, `3409-3415`). In a maze, every board answers it
  for free, so it tests no build. Seat T owns the A1 side.
- **Gloamwing:** only Soaked + Drowsy bring it down. Sporeling-first and Firefly-first runs shoot it in the air
  instead (220 health, route flyer). Fair, and a moment for Dewdrop / Bellflower to shine. Keep.
- **Stale comments**, so nobody "fixes" route flyers back out: `firefly_lights.gd:1302` ("Flyers have no steps: no
  streaks") is false since `index_of` gives route flyers steps. `_pass_streak` (`:1371`) and Mire-Mouth
  (`spore_print.gd:948`) still skip all flyers. Roguelite Code should align these with fix 1.
- **Dispel counts are right:** a Deeply Blighted counts 3 (`dream_state.gd:395-397`, used by Hard-Won Rings, Wild
  Growth and Lantern Light, `firefly_lights.gd:781`). Splitters (Widow +6, Mourner +3, procession +4) are gifts to
  Wild Growth and Hard-Won Rings, not exploits: their budget and Dew are counted.

## Every line has a nightmare it shines on and one that tests it (after fixes 1-3)

| Line | Shines on | Tested by |
|---|---|---|
| Spore Print Spread (Drifting / Season) | Sleepwalker (extra steps), Husk, Lantern Bearer procession, long Single file | Ash Crawler (in a mix), Barrow King, Phantom, Mire Hag |
| Deathcap / Rot Bloom | Packs, Whisper Swarm, Mourner | Ash Crawler, Night Kite (fast), Few and tough |
| Clump / Pile-On / Elder Cap | Few and tough, Shellbound, Barrow Wight, bosses | Whisper Swarm, Creeps, Lamplighter, Withering Oak |
| Shared Caps / Windfall / Host Grove | Packs, Widow → Creeps (Windfall), procession | Barrow King's shrug, Drowned One (Drowsy-immune) |
| Lantern Light Spread (Strung / Alley / Parade) | Single file, Sleepwalker, Night Hound on long straights | Mire Hag, Gravecrawler (burrows past glows), Phantom |
| Bonfire / Pyre / Flint and Steel | bosses, Few and tough, shells (crits beat per-hit soak) | Whisper Swarm, Creeps |
| Borrowed Light / Show the Way / Constellation | Packs, Whisper Swarm, Widow; North Star on Deeply Blighted | Single file, shells (fragments), Lurker before it's revealed |
| Keeping Time Peal / Change Ringing | Packs, Whisper Swarm | Single file, Night Kite |
| Last Bell / Curfew | Single file, Husk, Barrow Wight | Mire Hag, Night Mare echo (fix 4), Phantom |
| Steady Beat / Midnight / Double Time | bosses, Few and tough | Whisper Swarm, Sobs |
| Accompaniment / Symphony / Ensemble | bosses, Mourning Mother (no quiet gaps) | shells (half repeats), Lamplighter |
| Puddles Stream line | Night Hound, Dream Thief, Sleepwalker, Lantern Bearer | Drowned One (after fix 2, a test, not a blank), flyers |
| Black Pond / Breaking Wave | Packs, Whisper Swarm, splitters | Single file (Undertow is the sibling answer) |
| Undertow / Fathoms / Crushing Depth | Barrow King, Shellbound, Barrow Wight, Moth Queen (after fix 1) | Night Kite (fast, little time in water), Whisper Swarm |
| Riverside / River Mouth | Few and tough, Huntsman's pack | Barrow King, Watcher (wakes Drowsy) |
| Headlong | Packs, Stream drifts | Few and tough |
| Wild Growth / Hard-Won Rings | splitters, Packs, Deeply Blighted (×3) | bosses (count 1) |
| Walking Wood | Lamplighter, Withering Oak | Hollow Oak saplings (fix 5) |
| Waymark | every walker (statuses shed at the stone) | Barrow King (does the same thing), Phantom |

No nightmare makes one board answer everything. The Phantom is answered by guarding the Heartwood, but it is capped
at 4 and has 60 health. The nearest thing to a free answer is the Lurker (near-miss above).

## Owner calls

1. **Drowned One:** slows at half strength (my pick: no Calling line goes blank; the "can't be slowed" fantasy becomes
   "barely slowed"), or keep it fully slow-immune and accept that the Stream line is blank on it.
2. **Route-changing bosses (Thorned Hollow Oak's saplings, Hollow Stag's trample):** do they fall under "the route is
   the player's plan"? Options:
   - (a) Saplings grow only on open ground beside the path and claim the cell (no building there until cleared). They
     never change the route. The Stag's trample cracks a Thornwall for 8 s instead of removing it. The cracked
     wall still blocks the path, so the route never changes, but a cracked Thornwall gives Snag and other wall cards
     nothing while it's cracked.
   - (b) Keep both as named exceptions, and have every route-built card rebuild on `path_changed` (most do today).
   - My pick is (a). The first boss and the final boss are the two fights where a player's maze plan should be tested,
     not rewritten.
3. **Ash Crawler as a lead:** drop `heavy` (my pick), or keep it leading and limit the ash to Poisoned stacks applied
   before the crawler passed (re-doses behind it survive).
