# Maze income

## Path length only (user, 2026-10-11: "the maze bonus is confusing"; replaces the defended-cells rule below)

**The rule a player reads:** *+1 Dew for every 4 cells your route is longer than the forest's own path, up to 20 a rest.*

- **Added cells** = your route's length in whole cells minus the route the map generated (the baseline, saved with the run).
  Nothing else: no "defended" test, no coverage comparison, no unique-attacker count. Walls alone earn it, which is the
  point (maze_feel.md: walls first).
- **Measured at the route's shortest during the block:** the bonus uses the shortest your route was while nightmares
  walked in that block, so lengthening it just before the rest, or selling walls mid-block, doesn't pay. Said to the
  player as "counted while nightmares walk".
- Cap 20 Dew a block (80 added cells); the drift-one rest shares the first block's cap, as before. Deep Sleep still
  forfeits it. Winding Path and the other cards are unchanged.
- **Shown** right after the Dew total as "+N at rest" (screens_ui.md "HUD notes"). Tip: "Your route is 28 cells longer
  than the forest's path: +7 at the next rest (+1 per 4 cells, up to 20)." The Path counter's tip says the same. The
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
