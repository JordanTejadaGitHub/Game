# Design Plan: what still needs fleshing out

Status as of 2026-09-27. Already solid: story and tone (`story.md`), Warden roster, evolutions,
status effects and synergies (`tower_design.md`), creature roster (`enemy_design.md`), core loop
and meta outline (`game_design.md`).

What's missing is mostly **numbers and structure**: the things that turn good ideas into a run
that feels right. Topics are ordered by when the build will need them (build order in
`game_design.md`).

## Phase 1: Run pacing and economy (now; code needs it for leaves and drifts)

**Drafted in `run_design.md`** (15 drifts in 3 acts, build/sell/speed rules, Dew numbers, act 1
drift list). All questions decided; remaining work is playtest tuning.

### 1. Run structure
- How long is a run? (Target session length, e.g. 30–45 min.)
- Acts: how many, how many drifts each, a boss drift at the end of each? (Docs say both "10 drifts"
  and "a boss per act"; pick one.)
- Starting leaves; do bosses cost more than 1 leaf?
- Dream timing: after drift 1 (guaranteed base Warden), then every 2 drifts? Extra Dream after a boss?
- Win condition: survive the last boss? Endless mode after winning?

### 2. Build-phase rules (small, but every system depends on them)
- Can you build, evolve and clear during a drift, or only between drifts?
- Speed controls (pause, 2×, 3×)? Cozy players expect them.
- Selling: allowed? Refund %? Does selling a Warden re-open the path mid-drift?
- Can a placed Warden be moved?

### 3. Economy numbers
- Starting Dew (currently 60), Dew per creature, drift-clear bonus.
- Costs: Sprout, Thornwall, each base, each evolution tier, obstacle clears (Tree 5, Rock 8 now).
- Target curve: how many Wardens should a player have by drift 3 / 6 / 10? Work backwards from that.
- Interest / saving (Wellspring) and how it's capped.
- **Why clear obstacles?** Clearing currently helps creatures (it opens shortcuts); the payoff
  is building space. Should clears also give something back (Seeds, Dew, a free sapling)?
  Rename to fit the fiction (Withered Tree, Blight Bramble, Mossy Boulder)?

### 4. Drift list for the first playable
- A concrete table for act 1: drift number → creatures, counts, spacing.
- Health/speed scaling formula per drift (so drifts past the hand-made ones still work).
- When each new creature is introduced (alone first, then mixed, per `enemy_design.md`).

## Phase 2: Dreams and statuses (before build-order step 4)

### 5. Dream pool v1
- ~30 concrete Dreams for the first-playable scope (Sprout, Thornwall, Sporeling, Firefly Jar,
  Dewdrop lines + Thunderhead): name, rarity, effect, numbers, prerequisites, tags.
- Rarity weights per drift, pity rule numbers, reroll/banish rules.
- How "Sprouts grow" and "a Dream unlocks a base" interact on the Dream screen.

### 6. Status effect numbers
- Duration, stack cap and strength for Damp, Drowsy, Spored, Marked, Static, Held.
- Boss resistances (the "reduced cap/duration" in `enemy_design.md`).

## Phase 3: Meta and story delivery (before build-order step 7)

### 7. Meta-progression
- Seed formula (per drift, per cleanse, win bonus) and a target of how many runs to unlock
  everything (e.g. 15–25 hours).
- The Memory Grove unlock tree: ~30 unlocks with costs and prerequisites.
- Milestone list (these double as Steam achievements).
- Blight Levels: a list of ~10 stackable modifiers and their Seed bonus.

### 8. How the story is told
- Where lore appears: Memories unlocking story fragments? Dream-screen text? A narrator voice?
- The Hollow arc: which unlocks reveal it, and what the "reach the Hollow" true ending is in play
  terms (a final map? a special run?).
- Boss cleanse moments: one line of text each.

## Phase 4: Variety, onboarding, presentation (before the demo)

### 9. Maps and biomes
- Obstacle types beyond tree/rock, special tiles (e.g. waystones as bonus build spots, dew pools,
  blight patches).
- "New forests" meta unlock: 3–4 biomes, each with its own obstacles, look and rule twist.
- Later acts: multiple entrances? A different start/end layout?

### 10. First-run experience
- What the very first run teaches, and in what order (build, maze, cleanse, Dream, evolve).
- Which systems are hidden until later (evolution, statuses, obstacles).

### 11. Player-facing information
- Warden info panel (stats, statuses it applies/loves), creature info on hover.
- Path length readout, and "+N path" on the build ghost.
- Targeting modes (first / strongest / closest)?

### 12. Art and audio direction
- Style guide: palette, outline, size rules (Warden art direction is started in `tools/`).
- Music and SFX mood (cozy, gentle; the cleanse sound matters most).

### 13. Demo and store page
- One-line pitch and hook for the Steam page; capsule art concept.
- Demo scope for Next Fest (e.g. act 1 + one boss, a few unlocks).

## Recommended next step

**Phase 1 (topics 1–4) as one session: "Run pacing and economy".** It's what the code needs next
(leaves, drifts, costs), the four topics depend on each other, and the rest (Dream numbers, Seed
formula) is easier to tune once a run's length and income are fixed.
