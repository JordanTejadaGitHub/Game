# Seat T (tower defense veteran: maze and fairness), round 2026-10-24d: all 38 nightmares

**Verdict: feels good with fixes.** The roster mostly gives each nightmare a distinct maze test, and today's shape,
flyer and leak caps hold (Phantom cap 4, flyers 4/5/6 and a third, pack 6, Few and tough 6, flyers never elite:
`drift_shapes.gd:39, 191-232`; the Pall skips pack members, bosses and elites: `enemy.gd:2484-2488`). Four things
still feel like the game cheated or a nightmare with no job. (1) **Killing a splitter late costs more leaves than
letting it in.** (2) **The Whisper Swarm** is one body that claims to be a cloud. (3) **The Hollow Stag** breaks the
"route is the player's plan" rule. (4) **The Thorned Oak's text** promises re-routing the code doesn't do. One more
is a design hole: three "dispel it first" support kinds test a target choice most boards can't make.

Scope: read `roster.md`, `enemy_design.md` (Roster, Flyers, Bosses, Stats, Drift shapes), the three earlier
verdicts, and spot-checked `drift_shapes.gd`, `drift_roller.gd`, `enemy.gd`, `enemy_spawner.gd`. Nothing run.

## Failures

| # | Nightmare | Std | What's wrong (player's view; cause) | Fix (one meaning) | Owner |
|---|---|---|---|---|---|
| 1 | **Widow** (→ 6 Creeps), **Mourner** (→ 3 Sobs), Scarecrow's death Crows | C1, C4 | A Widow that walks in costs 1 leaf. Dispel it in the last cells and its 6 Creeps (140 speed, 1 leaf each) cost up to 6. The player is punished for killing it, which reads as cheating. Mourner: 1 leaf walked in vs 3 when killed late. Outside a pack, children have no shared cap (`tag_enemy` only caps pack or Few and tough arrivals, `drift_shapes.gd:85-107`). | **The children of one dispelled parent share a leaf cap of 2** (parent `leaf_cost` + 1). Reuse `PACK_META` / `PACK_LIMIT_META` with a per-parent key. If the parent rode in a pack, the pack's cap still applies on top. Glossary: "what a nightmare breaks into takes at most 2 leaves". | Enemy Code |
| 2 | **Whisper Swarm** | A1, B1, E4 | It has no job. Since the Kinds change removed its single-target ×0.5 (enemy_design.md "Nightmare Kinds", "What changes"), it is a plain 180-health, 105-speed body: no split, no count, no code (no `whisper`/`swarm` handling in `enemy.gd`). Its Swarm badge says area attacks answer it, and its text says "a thick cloud of small motes", "drifts in by the dozen", "hits every whisper at once". All false: one area hit hits it once. A Kind badge that lies is worse than none. | Pick one: (a) make it a real crowd. It arrives as **6 motes of 30 health that move as one pack** (spawned like followers, `follower_spacing` ~0.15, one pack id, so the 6-leaf cap and the pack wipe apply). (b) Re-Kind it Fast, rename the trait, rewrite the text. I recommend (a): act 4 lacks a native crowd. | Enemy Code (data), Balancing (numbers) |
| 3 | **The Hollow Stag** | A5 | Trample knocks a Thornwall within 2 half cells down for good, and "everyone else re-routes" (`enemy_spawner.gd:774-785`). An enemy is reshaping the maze on its own, which the owner rule forbids ("no enemy or card moves, blocks or re-routes the maze"). It is the first boss of every first run. | **Trample becomes the Stag's own shortcut:** it walks through one Thornwall beside it (like the Gravecrawler's burrow, `burrow_max` 1 per trip) and the wall **stands again behind it**. Other walkers keep the route. "Never rely on one wall" stays the test. Text: "Breaks through one {warden:thornwall} each trip; the wall stands again behind it." Or the owner confirms the Stag is exempt (owner call 1). | Enemy Code; owner |
| 4 | **The Hollow Oak: Thorned** | E4, A1 | The text says Thorn-Saplings "bend the path" / "reshape the path", and the design doc says "obstacles that re-route nightmares". The code plants a sapling only *beside* the route, never on it (`enemy_spawner.gd:878-910`, `on_route` excluded), so today's path never changes: the sapling takes building room ahead of the Oak. That is correct under the route rule, but the player builds around a threat that never comes, and the text is stale. | Text (trait, ability, tip 1): "Plants Thorn-Saplings on open ground beside the path ahead: they take that ground until cleared, and wither when it's dispelled." Test in the doc: "build room near the end of the maze", not "a changing maze". | Enemy Code (.tres), Enemy types design (doc) |
| 5 | **Watcher, Weeper** ("dispel it first"), Will-o'-Wisp ("stop it before the Heartwood") | A1, A2 | The test is "target priority". But every Warden targets the nightmare closest to the goal, and only Moonstone and Standing Stone can pick a target (round 2026-10-24, W S). A Weeper walking mid-crowd is never shot first on most boards. The card asks for a choice the player can't own. | Give each a **maze-ownable** answer and say it as a fact. Weeper: its mend works only while it walks **behind** another nightmare (in route order), so a long gap in the maze strips it. Watcher: it wakes only nightmares **ahead of it**. Or keep them, cut "dispel it first" from the text, and accept them as area-damage tests (owner call 2). | Enemy Code; owner |
| 6 | **Gloamwing** | E4 | "A splash and two tolls are enough": Tolls exist only with the Keeping Time Calling (`keeping_time.gd`, `tolls_on`), so a Bellflower board without that Calling never sees a toll. It also names the answer ("build Y"). | "{soaked} and {drowsy} count together: 3 stacks in all bring it down." | Enemy Code |
| 7 | **Few and tough, act 2** (Husk) | A1, C3 | Only four kinds carry `heavy`: Husk (6), Barrow Wight (63), Ash Crawler (68), Shellbound (79). Few and tough needs a heavy non-splitter lead (`drift_roller.gd:564-574`), so every act 2 Few and tough (63% of planned slots) is "3-5 Deeply Blighted Husks", and every act 1-2 Single file is Husk-led. Same test every time. | **Move the Shellbound's intro to about drift 44** (act 2; it is the shell teacher and it's faster, so it tests differently from the slow Husk). Or tag the Lantern Bearer `heavy` for Single file only. Balancing to check the act 2 budget. | Enemy Code, Balancing Discussion |

## Near-misses (fair today, watch)

- **Dream Thief** in Packs: it is packable (no loose trait) and leads Fast templates, but the Dew it steals has no
  pack cap (`enemy_spawner.gd:811-815`). 8 leaked thieves cost 6 leaves *and* 40 Dew, which compounds into a weaker
  board. Cap stolen Dew per pack (10), or add the Dream Thief to Packs' loose list.
- **Lurker** packs: packable, hidden, 140 speed. A pack of 8 is fair under the 6-leaf cap only because adjacency
  reveals. Watch it on the phone, where "half there" is hard to see.
- **Shellbound vs Husk vs Barrow Wight:** three Armoured walkers. The Wight has its status rules; the Shellbound is
  now a faster Husk with a thicker shell. Fix 7 gives it a place; without it, it's a duplicate in act 4.
- **Husk leaf 1 vs Shellbound leaf 2** (the Shellbound has less health): C1 says 2 for "big". Either Husk 2 or
  Shellbound 1. The doc's Stats table still says Husk 2.
- **Night Mare:** laps cost 5, 7, then 9 leaves (21 over three, more than any bite). That's by design ("lapped to
  death") and the ability text gives the numbers. Its data `leaf_cost` 3 is only used by its echo.
- **Boss `leaf_cost` 5 is live for echoes** (Remembering Oak; `get_leaf_cost`, `enemy.gd:1882-1886`): three
  leaked echoes cost 15. Fair for a finale, but S should not delete the field as stale. The comment there still
  says "8 / 10 / 12".
- **Huntsman's half damage** is a second damage reduction (B2 allows only the dread shell and the Pall). It is
  readable (the ring) and answered by the maze (corners split the hounds), but it is a rule exception (owner call 3).
- **Pall text:** it never settles on a pack member, but the intro line only names bosses and Deeply Blighted.
  Add "or a pack".
- **Hand-holding pattern (E4):** most `trait_text` lines end ": use Wardens that hit many at once / heavy hits /
  lightning if you have it / spread your Wardens". Maze advice (Night Hound "add corners", Sleepwalker "a dead end
  keeps it longer") is a fact about pathing, and fine. Advice that names a build ("hit it hard, with lightning if
  you have it", Drowned One; "use heavy hits, not many small ones", Shellbound) is closer to "build Y". Seat P
  owns the wording; I'd cut the build-naming tails first.
- **Doc drift:** enemy_design.md "Don't ship" and "Decided 2" still say a pack takes 3 leaves; the code and
  2026-10-24c say 6 (`drift_shapes.gd:39`; `PACK_LEAVES_PER` is unused but still read by the glossary).
- **Readability on a phone:** the Pall's cloth over a walker, the Lurker and the Eclipse are the three
  "is it there?" reads. Check them in the next capture.

## Per nightmare (one line each; passes unless noted)

**Act 1:** Shade, the baseline crowd. Husk: tank plus shell; leads every early Single file (fix 7). Mourner:
area test; fix 1.
**Act 2:** Night Hound: corners, loose by trait, good. Phantom: goal defence, capped, the only straight flyer,
good. Lantern Bearer + Wraith: kill-order test; Bloons-style procession; fair. Night Kite: spread anti-air,
distinct from the boss-only Crow.
**Act 3:** Lurker: detection. Will-o'-Wisp: a gift, but its "stop it" line has no ownable test (fix 5).
Gravecrawler: layered walls, the best maze test after the Hound. Sleepwalker: rewards dead ends, unique in TD.
Drowned One: anti-slow, with a Storm gift. Barrow Wight: anti-control tank. Watcher: fix 5. Ash Crawler: kill
order for spore boards. As a Few and tough elite it walks first and burns spores off everyone behind it, which is
harsh but readable. Gloamwing: fix 6.
**Act 4:** Widow: fix 1. Shellbound: fix 7 / duplicate. Whisper Swarm: fix 2. Dream Thief: near-miss. Weeper:
fix 5. Pall: good design (sharing, not halving); its text omits packs.
**Children and summons:** Sob, Creep (fix 1); Wraith (fine); Crow (route flyer, 1 leaf, fine).
**Bosses:** Stag (fix 3); Night Mare (fine, see near-miss); Scarecrow (Crows capped at 10 = the bite, fine);
Mire Hag (spread coverage, fine; her leap passes the Waymark correctly); Huntsman (owner call 3); Lamplighter
(fights Wardens, not the maze; fine); Moth Queen (long maze plus detection; the 5 s Eclipse is a fair spike);
Barrow King (fine; tip 3 "Pulls drag him back" names a Rootling form, which most boards lack); Mourning Mother
(coverage gaps, a good maze test); Oak Thorned (fix 4); Oak Withering (redundancy, good); Oak Remembering (fine;
echo leaves above).

## Compared with the genre
In Bloons TD 6 a leaking bloon costs its whole RBE (its children included), so popping a parent never raises
what a leak costs; players accept splitters because the leak scales with what got through, never with killing. Fix 1 brings us to that. Rogue Tower and Legion TD 2 never
let an enemy edit the player's maze; Kingdom Rush's boss "wall breakers" are scripted and telegraphed. Fix 3 or
an explicit exemption keeps us honest.

## Owner calls
1. **The Hollow Stag's trample:** keep it as the one exemption to "the route is the player's plan" (a wall gone
   for good), or make it a personal shortcut whose wall stands again (my pick, fix 3)?
2. **Target-priority nightmares (Watcher, Weeper):** give them maze-ownable rules (fix 5), or keep them and drop
   "dispel it first" from their text?
3. **The Huntsman's half damage:** keep it as a boss exception to "the dread shell is the only damage reduction",
   or turn it into a share like the Pall's (blows split with the nearest hound)?
4. **The Whisper Swarm:** a real crowd of 6 motes (my pick) or re-Kinded as Fast?
