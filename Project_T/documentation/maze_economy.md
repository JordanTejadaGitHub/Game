# Maze income

## The maze grows the Dew pot (user, 2026-10-22: "let's increase the maze payout for Dew"; replaces "Path length only" below)
The economy council (game_council rounds 2026-10-22) found the maze paid about 1% of income (+45 cells ≈ 15 Dew a block
against ≈ 1,500 from pots), so building it was never an economic choice.

**The rule a player reads:** *A longer maze makes every drift pay more: +1% Dew for every 2 cells your route is longer
than the forest's own path, up to +30%.*
- **Added cells** as before: your route's length in whole cells minus the generated baseline (saved with the run).
- **Paid every drift, as a share of that drift's Dew pot** (on each dispel's share, like the other pot multipliers in
  `get_dew_pot_multiplier`), so it grows with the acts instead of staying a flat trickle. 45 added cells = +22% ≈ +55
  Dew a drift in act 2, ≈ +280 a block.
- **Measured at the route's shortest while that drift's nightmares walk** (the same anti-farming rule: lengthening it
  mid-drift or selling walls after doesn't pay that drift).
- **Cap +30%** (60 added cells). Deep Sleep still forfeits it; Winding Path multiplies the maze share (×3 → +90% cap is
  too much: Balancing sets the card's new number).
- **Shown** on the Dew counter's forecast ("+22% maze") and the Path counter's tip ("Your route is 45 cells longer than
  the forest's path: drifts pay +22% Dew"); the build ghost's "+N path" also shows the % it would add. The rest
  report lists "Maze +280".
- **Inflation check (Balancing):** Dew is already in surplus (council: banks of 2,000-3,000). A good maze now adds up
  to +30%; consider trimming the act 2 base pots about 10-15% so a strong maze ends near today's income and a lazy one
  below it. That makes the maze matter without adding more idle Dew. Balancing decides.

The block-rest flat payout below is retired; its snapshot ledger and save fields stay for old saves.

## Path length only (user, 2026-10-11: "the maze bonus is confusing"; replaces the defended-cells rule below)

**The rule a player reads:** *+1 Dew for every 4 cells your route is longer than the forest's own path.* (No cap since 2026-10-12, user: the map's size is the limit; it was 20 a block.)

- **Added cells** = your route's length in whole cells minus the route the map generated (the baseline, saved with the run).
  Nothing else: no "defended" test, no coverage comparison, no unique-attacker count. Walls alone earn it, which is the
  point (maze_feel.md: walls first).
- **Measured at the route's shortest during the block:** the bonus uses the shortest your route was while nightmares
  walked in that block, so lengthening it just before the rest, or selling walls mid-block, doesn't pay. Said to the
  player as "counted while nightmares walk".
- No cap. **Paid at block rests only** (after drifts 5, 10, 15…), not at the short rest after drift 1 (2026-10-12: with no cap, walls built before drift 1 and sold at that rest kept their payout). Deep Sleep still
  forfeits it. Winding Path and the other cards are unchanged.
- **Shown** right after the Dew total as "+N at rest" (screens_ui.md "HUD notes"). Tip: "Your route is 28 cells longer
  than the forest's path: +7 at the next rest (+1 per 4 cells)." The Path counter's tip says the same. The
  build ghost's "+N path" tag is already the number that feeds it.
- The rest payout lists it as "Maze +7".

Everything below about qualifying / defended cells is history; the snapshot ledger and save fields stay.

# Defended maze income — October 10, 2026 (superseded above)

Every completed block can pay up to 20 extra Dew for expanding a defended maze. The base rate is one Dew per four qualifying added route cells. All profiles receive this mechanic; random Dream offers and Memory Grove exclusives are unchanged.

Qualification compares the current route with the original generated route, using the same current attacking Wardens for both coverage measurements. Qualifying cells are the smaller of added route length and added uniquely defended cells. Natural terrain, overlapping coverage, non-attacking supports and empty corridor extensions therefore cannot earn extra credit on their own. Tower minimum range is respected. Half-cell path steps are converted to whole-cell measures.

Each drift snapshots its qualifying reward at start. Shortening the route or removing defenses reduces unpaid snapshots. The rest pays the average earned rate across sampled drifts, minus earlier payment in the same block; the opening drift-one rest shares the 20-Dew cap with the drift-five rest. Repeating a claim cannot pay twice. The generated baseline and ledger persist through saves; older saves use the freshly generated baseline.

The reward is separate from drift pots, catcher shares, Omens and Rich Dew multipliers. Deep Sleep's forfeited ordinary rest income also forfeits this universal reward. Once paid, Dew remains ordinary banked currency, so interest and damage scaling from earned Dew can still interact with it.

The drift panel shows the projected next-rest maze bonus, assuming the present defenses remain through the block. The rest toast itemizes the actual maze portion of total income. Winding Path remains a stronger optional card that rewards all covered route cells. Building, clearing, growing and Nurture costs remain unchanged.

Validation: test_maze_economy, test_maze_economy_integration, test_dew_pot, test_save and headless startup. Initial values require human playtesting: compare compact upgraded defenses, expanded defended mazes and expanded empty mazes on identical seeds, recording Dew, leaves and block duration. The payout is capped to limit snowballing; longer blocks must remain enjoyable.

## Maze funding follow-up — October 10, 2026

Sprouts start at 10 Dew and retain +4 per five paid Sprouts (10,14,18,…). The 60-Dew opening can fund five Sprouts and three 3-Dew Thornwalls, leaving one Dew. Seedfall retains its own 8-Dew start and +2 escalation. Free Seedbearer/Gift Sprouts remain free.

Ordinary non-elite Act1 enemies gain a linear additional health multiplier from zero through drift10 to +5% at drift24. Bosses, elites, Act2's existing health ramp and later-act health are unchanged. Ordinary Act1 drift pots gain15% from drift11, Act2 pots gain20%; boss pots and Acts3–4 pots are unchanged. Changes apply to total kill pots, preserving reward shares and modifiers.

Evolution and Nurture prices remain unchanged so increased income leaves more room for maze expansion and additional status sources. The defended-maze reward remains separate, capped20 Dew per block. This is initial tuning, not proof that players choose larger mazes; compare coverage, walls, upgrades, ranks, survival and block duration in human playtests.

Validation: test_maze_funding, test_sprout_price, test_opening (three seeds), test_dew_pot, test_economy, test_nurture, test_maze_economy_integration and headless startup.

The road counter's hover/tap tooltip explains the maze Dew rate, cap, and next-rest forecast. A small +N Dew counter below the top-right resource row shows the same forecast, alongside any half-price clears. It updates with the route and reward ledger; it is separate from Wellspring interest.
