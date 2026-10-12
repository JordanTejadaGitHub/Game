# Unique Dream successors — council-approved, 2026-10-10

Four Deepened cards remain active: Rolling Thunder II, Root Network II, Guiding Light II and Tender Care II. The other fourteen active II offerings are retired and replaced by independent single-pick cards. Old resources remain loaded for saved runs; a legacy II still replaces its base and keeps its old rule-level effects.

| Retired offering | Successor | Effect |
| --- | --- | --- |
| Cozy Corners II | Corner Sign | A native direct status hit after a bend adds one stack; once per bend, 3 s per Warden/target. |
| Deep Water II | Wake Ripple | Dispelling a currently drowning nightmare adds two Soaked stacks to up to three nearby living nightmares within one cell. Includes the final Drown tick. |
| Slow Waking II | Dream Residue | Actual Catch exit adds two Drowsy stacks, 3 s cooldown per catcher/target. |
| Old Friends II | Kin's Keepsake | Each stable kinship pair's first Harmony per drift earns one Dew; six Dew total per drift. Rebinding does not reset the pair. |
| Target Turnover II | Passing Thread | Changing primary targets copies one stack of the donor's fullest stackable status, with remaining duration and source; 2 s cooldown per Warden. Rooted/freeze, Asleep and Caught cannot copy. |
| Ricochet II | Crosswind | Samara direct seed hits deal 25% more after another Warden hit within one second; once per target per throw, including overlapping throws. |
| Shattering Blow II | Opening Fracture | A direct crit primes for two seconds; the next other-Warden direct hit deals 40% more; shared 3 s cooldown. The payoff cannot prime again. |
| Spore Cascade II | Shared Mycelium | Two distinct Wardens' native accepted Poisoned applications within two seconds add two stacks; shared 2 s cooldown. |
| Charged Field II | Crossed Sparks | Equivalent two-Warden native Charged cooperation adds two stacks; shared 2 s cooldown. |
| Sunlit Rest II | Fresh Beginnings | Each rest banks a free rank on the newest eligible attacking Warden planted since the previous rest; excludes Sunlit Rest recipients and respects rank plus banked-rank limits. |
| Tangled Release II | Afterroot | Natural Rooted expiry with a known source primes for two seconds; another Warden's direct hit adds two Exposed stacks; shared 4 s cooldown. |
| Hardened Bark II | Emergency Reserves | First actual leaf-loss event each block adds eight Dew. Prevented leaks, healing and max-leaf adjustments do not count. |
| Briar Trap II | Hushed Hedge | Each Thornwall gives its first adjacent grounded nightmare two Drowsy stacks each drift. Separate from Briar Trap and respects the wall Drowsy limit. |
| Watchful Rest II | Quiet Vigil | Five seconds without targets stores readiness; the next primary direct hit applies three Exposed stacks before damage. Persistent, beam and secondary hits cannot consume readiness. |

## Constraints and access

These cards retain their predecessors' rarity, family and discovery gates. Crosswind stays exclusive to Hidden branch: Samara; Opening Fracture to Sharpened; Hushed Hedge to Thorn and Bramble. Legacy II IDs remain in node grants for compatibility but are not advertised as obtainable Deepened upgrades. Other successors preserve start-pool access.

Ordinary enemy immunity, status caps and Brimming thresholds still apply. Synthetic Dream/reaction/copied stacks cannot satisfy native cooperation. Distinct Warden instances are required; repeated projectiles from one Warden cannot qualify. Poisoned cooperation tracks the actual native cohort, including Caught-paused timers, expiry and cap displacement. New cards do not require their former base card, so speculative random picks remain possible. Offer weights and seed sampling rules are unchanged.

## Implementation and validation

Focused helpers: dream_cooperation.gd, dream_path_rules.gd and dream_growth_rules.gd. Existing Tower/Enemy/Kinships hooks deliver native/direct context and true lifecycle transitions. Growth planting order/rest serial and emergency block persist through DreamState and RunSaver.

Tests: test_unique_dream_catalogue, test_dream_cooperation, test_dream_path_rules, test_dream_growth, test_unique_dream_integration, test_unique_dream_offers. Broader Dream, Grove, save, kinship and status regressions also apply. Seed sampling checked 24 fresh-profile and 24 full-Grove seeds: each profile produced 24 different pools; fresh profiles never received the three exclusive successors. These are initial tuning values, not a completed long-run balance study. Existing scene-test shutdown RID/ObjectDB/resource diagnostics remain.