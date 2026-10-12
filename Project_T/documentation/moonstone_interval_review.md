# Moonstone interval experiment and Bellflower review — 2026-10-11

Decision: Moonstone base attack interval 3.5 -> 4.5 seconds (0.2222222222 attacks/s).
Damage, range, first-hit crit and First Light unchanged. Bellflower family numbers unchanged.

## Method

27 fixed-board combat probes: seeds 7, 19, 42; drifts 61–65; four rank-IV Power candidate Wardens plus four rank-IV Bellflowers. Moonstone at 3.5, 4.0, 4.5 seconds, each without Dreams and with First Light only. Reference candidates Puffball, Resonance, Lullaby Bell without Dreams. Invulnerable Heartwood; real enemies, paid construction/growth/ranks; no mid-run spending. Runtime interval overrides avoid changing resource files between arms. Effective damage clips overkill using DamageLog.effective_share.

Outputs: D:/Projects/logs/moonstone_20261011/ (one CSV, stdout and stderr per probe). An earlier exploratory CSV at D:/Projects/logs/moonstone_20261011.csv had incorrectly parsed support arguments and is excluded.

| Interval | First Light | n | Mean candidate effective damage | Mean leaked health |
|---|---|---|---|---|
| 3.5 s | No | 3 | 778,533 | 72.6% |
| 4.0 s | No | 3 | 717,820 | 75.1% |
| 4.5 s | No | 3 | 626,544 | 77.4% |
| 3.5 s | Yes | 3 | 1,546,243 | 47.3% |
| 4.0 s | Yes | 3 | 1,382,285 | 51.9% |
| 4.5 s | Yes | 3 | 1,271,516 | 55.6% |

References (n=3 each): Resonance 681,431 effective damage / 75.5% leaked health; Lullaby Bell 367,745 / 84.6%; Puffball 223,103 / 90.1%.

4.5 s reduces candidate effective damage 19.5% without First Light and 17.8% with it. First Light still provides about twice the effective candidate damage in this setup. The slowdown is a targeted playtest adjustment, not proof the first-hit package is balanced.

## Limits

Three maps per arm, one block, fixed placement and rank policy; no confidence intervals. Map seeds matched; global crit RNG was not explicitly seeded, so stochastic combat draws are not paired. The sparse board and short generated route are not the human run's 130-cell maze; high leaked-health fractions are not win rates. Support benefit and crowd matchup differ across forms; these references cannot establish global archetype parity. No faithful replay of the 287-dirty-file export. Shutdown RID/resource leak diagnostics remain; no script/parse errors detected in the sweep.

## Bellflower review

Retain distinct roles: base Bellflower Drowsy pulse; Chime/Lullaby Charged pulses; Thrum/Resonance cone damage; Silver/Vesper single-target toll; Hush/Silence ability suppression; Dreamcatcher status preservation and shards; Echo/Whispering Hollow reaction echo.

Base Bellflower: 20.4 damage, 1 attack/s, Drowsy on every second pulse, range 2. Resonance: 198 damage, 1 attack/s, range 3, +30% against any Drowsy target and widening per Drowsy target. Ordinary Drowsy slowing has a 50% speed floor (elites 60%, bosses 70%); sleep has a 4-second cooldown and bosses cannot sleep. Control should be assessed by uptime and enabled damage, not just direct damage share.

The current report has no Reaction or status-tick damage; do not attribute its strength to the Charged or echo branches. Fixed-board Resonance is strong in this block but no broad Bellflower nerf is supported. Great Dreamcatcher description still advertises Caught +80%; several descriptions retain old stack units. Audit text against the newer status-buildup rules before changing gameplay. Earlier Brimming/Caught conclusions from October 9 are not a substitute for current-code validation.

Next playtest: same Moonstone-oriented strategy at 4.5 seconds; note opening-volley kills, repeated shots per target, pressure before acts 3/4, and Bellflower control uptime. If opening volleys still erase pressure, investigate First Light + guaranteed first-hit crit independently.