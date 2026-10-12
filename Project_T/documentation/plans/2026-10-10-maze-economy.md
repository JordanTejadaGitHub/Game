# Defended maze economy implementation plan

Goal: reward larger defended mazes with one Dew per four qualifying added cells, capped at twenty per block.
Architecture: focused RefCounted MazeEconomy helper owns generated baseline, drift snapshots, minimum observations, cumulative block claims and save data. DriftDirector delivers lifecycle hooks; HUD shows live reward and rest breakdown. No changes to cards, costs, offers or Grove access.
Approved design: user approved in-chat council recommendation, October 10 2026.

- [x] Test helper red, then implement half-cell-safe added covered route calculation; count coverage once and compare original route under the same current attackers.
- [x] Snapshot every drift start; lowering observed coverage lowers unpaid snapshots. Cumulative claims cap block at twenty, including the opening drift-one rest; saved claims cannot repeat.
- [x] Integrate baseline capture before restored towers, director sampling and payout; preserve Deep Sleep rest-cost behavior and pay no lost-run bonus.
- [x] Persist baseline and ledger via RunSaver, default safely for older saves.
- [x] Add live projected reward and itemized rest toast with existing UI styling.
- [x] Run helper, integrated economy, save, and smoke tests; independent council code review; document tuning limitations.

Constraints: all development writes/output on D:. No commits or pushes. Checkout already main; feature branch matches its committed HEAD, so no branch merge is needed.
