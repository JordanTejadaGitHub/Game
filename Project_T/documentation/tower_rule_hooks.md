# Tower Code rule hooks (for card_text_audit.csv's code column)

Owner: Tower Code. Generated from main (2026-10-02): every Dream rule id read in scripts/tower, scripts/combat and scripts/enemy, with where it's read, the line, and the values of the constants that line uses. Some sections are Kinship trait ids (read through kin_share), not cards; effects computed inside DreamState getters (get_bolt_multiplier, get_ignite_multiplier, …) show only the getter here: their numbers are in dream_state.gd. Regenerate after rule changes.

## __catalogue_cards
- `scripts/tower/tower.gd:2978`: `if not _any_rule(&"__catalogue_cards", CATALOGUE_HIT_RULES):`
  - const CATALOGUE_HIT_RULES: Array[StringName] = [&"mycelium", &"fireflies_in_the_grass", &"resonance"]

## __hit_cards
- `scripts/tower/tower.gd:1345`: `if _dream_state == null or (_shiny.is_empty() and not _any_rule(&"__hit_cards", HIT_CARD_RULES)):`
  - const HIT_CARD_RULES: Array[StringName] = [&"patient_aim", &"crush", &"crowd_breaker", &"shiny_things"]

## acorn_cache
- `scripts/tower/tower.gd:1020`: `if not speed and tower_data.get_id() == "acorn" and _rule_stacks(&"acorn_cache") > 0:`
- `scripts/tower/tower.gd:1021`: `base = 0.05 + (ACORN_CACHE_AURA - 0.05) * _rule_power(&"acorn_cache")  # Tag resonance scales the card's part`
  - const ACORN_CACHE_AURA := 0.10  # Acorn Cache: the Acorn's aura (dream_audit.md)

## backspin
- `scripts/tower/seed_boomerang.gd:126`: `if _returning and dreams and dreams.has_rule(&"backspin") \`
- `scripts/tower/seed_boomerang.gd:127`: `and randf() < _tower.get_crit_chance(enemy) + BACKSPIN_CRIT * dreams.rule_power(&"backspin"):`
  - const BACKSPIN_CRIT := 0.40  # dream_audit.md (was 0.25)

## bad_dreams
- `scripts/tower/tower.gd:2397`: `if _dream_state and _has_rule(&"bad_dreams"):`
- `scripts/tower/tower.gd:2398`: `bad_dreams = 2 if _rule_level(&"bad_dreams") > 0 else 1`

## big_family
- `scripts/tower/tower.gd:574`: `speed += DreamState.BIG_FAMILY_SPEED * _rule_power(&"big_family")  # Big Family: a Sprout near a Kinship pair`
  - const BIG_FAMILY_SPEED := 0.45  # Sprouts within BIG_FAMILY_CELLS of a Kinship pair
- `scripts/tower/tower.gd:1231`: `_big_family = tower_data.get_id() == "sprout" and _rule_stacks(&"big_family") > 0 and _near_kin_pair()`

## bramble_oath
- `scripts/tower/tower.gd:1035`: `if BRAMBLE_OATH_WARDENS.has(tower_data.get_id()) and _rule_stacks(&"bramble_oath") > 0:`
  - const BRAMBLE_OATH_WARDENS := ["bramble", "honeysuckle"]

## called_shot
- `scripts/tower/tower.gd:1546`: `if _has_rule(&"called_shot") and _dream_state.called_shot(self, enemy):`

## carried_on_the_wind
- `scripts/tower/tower.gd:2947`: `var full_copy := _rule_stacks(&"carried_on_the_wind") > 0  # Carried on the Wind (Entwined): full stacks`

## chain_bloom
- `scripts/tower/tower.gd:1899`: `if _has_rule(&"chain_bloom"):`

## charged_feathers
- `scripts/tower/tower.gd:2809`: `if _has_rule(&"charged_feathers"):`

## conductive_soil
- `scripts/tower/tower.gd:2282`: `if storm or (_dream_state and _has_rule(&"conductive_soil")):`
- `scripts/combat/reactions.gd:478`: `if dreams and dreams.has_rule(&"conductive_soil") and tower:`

## crowd_breaker
- `scripts/tower/tower.gd:1321`: `const HIT_CARD_RULES: Array[StringName] = [&"patient_aim", &"crush", &"crowd_breaker", &"shiny_things"]`
  - const HIT_CARD_RULES: Array[StringName] = [&"patient_aim", &"crush", &"crowd_breaker", &"shiny_things"]
- `scripts/tower/tower.gd:1357`: `if is_area and _rule_stacks(&"crowd_breaker") > 0 and _area_count > 1:`
- `scripts/tower/tower.gd:1358`: `multiplier *= 1.0 + minf(DreamState.CROWD_BREAKER_PER * _area_count, DreamState.CROWD_BREAKER_MAX) * _rule_power(&"crowd_breaker")`
  - const CROWD_BREAKER_MAX := 0.45
  - const CROWD_BREAKER_PER := 0.05  # An area attack, per nightmare it hits

## crush
- `scripts/tower/tower.gd:1321`: `const HIT_CARD_RULES: Array[StringName] = [&"patient_aim", &"crush", &"crowd_breaker", &"shiny_things"]`
  - const HIT_CARD_RULES: Array[StringName] = [&"patient_aim", &"crush", &"crowd_breaker", &"shiny_things"]
- `scripts/tower/tower.gd:1350`: `if is_area and _rule_stacks(&"crush") > 0:`
- `scripts/tower/tower.gd:1356`: `multiplier *= 1.0 + DreamState.CRUSH_BONUS[_rule_level(&"crush")] * _rule_power(&"crush")`
  - const CRUSH_BONUS: Array[float] = [0.30, 0.45]  # Area attacks vs a nightmare touching CRUSH_CROWD+ others (II)

## dawnbreak
- `scripts/combat/reactions.gd:843`: `if dreams == null or not dreams.has_rule(&"dawnbreak"):`
- `scripts/combat/reactions.gd:849`: `other.take_damage(other.max_health * share, "", true, false, null, &"dawnbreak")`
- `scripts/enemy/enemy.gd:137`: `&"dawnbreak", &"echo"]`

## deep_stillness
- `scripts/combat/reactions.gd:665`: `var deep_still := 1 if dreams and dreams.has_rule(&"deep_stillness") else 0`

## deep_water
- `scripts/combat/reactions.gd:652`: `if dreams and dreams.has_rule(&"deep_water"):`
- `scripts/combat/reactions.gd:653`: `level = 1 + dreams.rule_level(&"deep_water")`

## deep_well
- `scripts/tower/dew_catch.gd:119`: `var cap := data.rest_interest_max + (DEEP_WELL_CAP if dreams and dreams.has_rule(&"deep_well") else 0)`
  - const DEEP_WELL_CAP := 30  # Deep Well (Seed card): each Wellspring's interest cap +30

## dew_bowl
- `scripts/tower/tower.gd:2550`: `+ DewCatch.DEW_BOWL_STEP * _rule_stacks(&"dew_bowl") \`
  - const DEW_BOWL_STEP := 0.15  # Dew Bowl (Seed card): +15% catch per stack

## dew_trail
- `scripts/tower/tower.gd:2541`: `return tower_data.catch_radius + (DewCatch.WIDE_BOWL_STEP if _rule_stacks(&"dew_trail") > 0 else 0.0) + FOCUS_WIDE * choice_count(Focus.WIDE)`
  - const FOCUS_WIDE := 0.2  # Wide, per rank: aura reach / catch radius (+1 cell over five ranks)
  - const WIDE_BOWL_STEP := 0.5  # Dew Trail (any level): +0.5 cells catch radius (Wide Bowl merged into it)
- `scripts/tower/tower.gd:2555`: `if share > 0.0 and _rule_stacks(&"dew_trail") > 0 and enemy.statuses.has(EnemyStatuses.DAMP):`
  - const DAMP := &"damp"
- `scripts/tower/tower.gd:2556`: `share += DewCatch.DEW_TRAIL[_rule_level(&"dew_trail")] * _rule_power(&"dew_trail")`
  - const DEW_TRAIL := [0.30, 0.50]  # Dew Trail / II: more when the caught nightmare is Damp (dream_audit.md)
- `scripts/tower/tower_placer.gd:269`: `+ (DewCatch.WIDE_BOWL_STEP if dream_state.has_rule(&"dew_trail") else 0.0))  # Dew Trail widens the catch`
  - const WIDE_BOWL_STEP := 0.5  # Dew Trail (any level): +0.5 cells catch radius (Wide Bowl merged into it)

## dust_devil
- `scripts/tower/tower.gd:2960`: `var devil := kin_share(&"dust_devil", "a")`
- `scripts/tower/tower.gd:2964`: `_kin_fired(&"dust_devil")`
- `scripts/tower/tower.gd:3032`: `if _kin_roll(kin_share(&"dust_devil", "b")) and struck.size() > 1:`
- `scripts/combat/kinships.gd:55`: `&"dust_devil": ["Dust Devil", "wind", "gust", "pinwheel", false],`

## eddy
- `scripts/tower/tower.gd:2951`: `if tower_data.line == "wind" and _rule_stacks(&"eddy") > 0:`
- `scripts/tower/tower.gd:2954`: `var copies := others.size() if tower_data.line == "wind" and _rule_stacks(&"eddy") > 0 else mini(attack_data.spread_targets, others.size())`

## elder_kin
- `scripts/tower/tower.gd:671`: `if is_instance_valid(_kin) and _rule_stacks(&"elder_kin") > 0:`
- `scripts/tower/tower.gd:675`: `court += DreamState.ELDER_KIN_SHARE * _rule_power(&"elder_kin") * partner.rank`
  - const ELDER_KIN_SHARE := 0.25  # Ranked Wardens in a Kinship share this much of their rank bonuses

## encore
- `scripts/tower/tower.gd:2436`: `var encore := _dream_state != null and _has_rule(&"encore")`

## endless_night
- `scripts/combat/reactions.gd:625`: `var level := 1 if dreams and dreams.has_rule(&"endless_night") else 0`
- `scripts/combat/reactions.gd:632`: `if id == &"nightbloom" and dreams and dreams.has_rule(&"endless_night"):`

## eternal_static
- `scripts/tower/tower.gd:1692`: `if _has_rule(&"eternal_static"):`

## eye_of_the_tempest
- `scripts/combat/reactions.gd:476`: `var eye := tempest and dreams != null and dreams.has_rule(&"eye_of_the_tempest")`

## falling_stars
- `scripts/combat/reactions.gd:339`: `var level := 1 if dreams and dreams.has_rule(&"falling_stars") else 0`

## fever_pitch
- `scripts/combat/reactions.gd:261`: `var level := 1 if dreams and dreams.has_rule(&"fever_pitch") else 0`

## fireflies_in_the_grass
- `scripts/tower/tower.gd:1322`: `const CATALOGUE_HIT_RULES: Array[StringName] = [&"mycelium", &"fireflies_in_the_grass", &"resonance"]`
  - const CATALOGUE_HIT_RULES: Array[StringName] = [&"mycelium", &"fireflies_in_the_grass", &"resonance"]
- `scripts/tower/tower.gd:2983`: `if _touch_lines.has("light") and _rule_stacks(&"fireflies_in_the_grass") > 0:`

## flock_together
- `scripts/tower/tower.gd:1572`: `if _kin_roll(kin_share(&"flock_together", "a")):`
- `scripts/tower/tower.gd:1578`: `_kin_fired(&"flock_together")`
- `scripts/tower/tower.gd:1761`: `var flock := kin_share(&"flock_together", "b")`
- `scripts/tower/tower.gd:3533`: `if kin_share(&"flock_together", "b") > 0.0:`
- `scripts/combat/kinships.gd:54`: `&"flock_together": ["Flock Together", "wing", "wrens_nest", "magpie_perch", false],`

## flurry
- `scripts/tower/tower.gd:1315`: `if _dream_state and _has_rule(&"flurry") and _attack_count % DreamState.FLURRY_EVERY == 0:`
  - const FLURRY_EVERY := 5  # Every 5th attack fires twice (the extra never counts)

## grandfather_stump
- `scripts/tower/tower.gd:1010`: `if tower_data.get_id() == "elder_stump" and _rule_stacks(&"grandfather_stump") > 0:`

## great_ripple
- `scripts/tower/grove_rules.gd:69`: `if tower._has_rule(&"great_ripple"):`
- `scripts/tower/grove_rules.gd:77`: `tower.hit(enemy, share * DreamState.GREAT_RIPPLE_SHARE, true, Tower.NO_CRIT, &"great_ripple")`
  - const GREAT_RIPPLE_SHARE := 0.50
  - const NO_CRIT := 0
- `scripts/tower/tower.gd:80`: `const GROVE_AREA_RULES: Array[StringName] = [&"lingering_splash", &"great_ripple"]  # GroveRules (Wide Reach)`
  - const GROVE_AREA_RULES: Array[StringName] = [&"lingering_splash", &"great_ripple"]  # GroveRules (Wide Reach)

## grove_area
- `scripts/tower/tower.gd:1489`: `if _dream_state and _any_rule(&"grove_area", GROVE_AREA_RULES):`
  - const GROVE_AREA_RULES: Array[StringName] = [&"lingering_splash", &"great_ripple"]  # GroveRules (Wide Reach)
- `scripts/tower/tower.gd:1965`: `if _dream_state and _any_rule(&"grove_area", GROVE_AREA_RULES):`
  - const GROVE_AREA_RULES: Array[StringName] = [&"lingering_splash", &"great_ripple"]  # GroveRules (Wide Reach)

## grove_speed
- `scripts/tower/tower.gd:555`: `if _dream_state and _any_rule(&"grove_speed", GROVE_SPEED_RULES):`
  - const GROVE_SPEED_RULES: Array[StringName] = [&"momentum", &"quickening"]  # GroveRules (Swift)

## guiding_light
- `scripts/tower/tower.gd:1886`: `if status == EnemyStatuses.MARKED and _dream_state and _has_rule(&"guiding_light"):`
  - const MARKED := &"marked"
- `scripts/tower/tower.gd:1887`: `var reach := (2.0 if _rule_level(&"guiding_light") > 0 else 1.0) * MAP_GRID.cell_size.x`
  - const MAP_GRID = preload("res://resource/map/map_grid.tres")

## hairpin_winds
- `scripts/tower/tower.gd:3024`: `var hairpin := DreamState.HAIRPIN_WINDS_EXTRA * _rule_power(&"hairpin_winds") if _rule_stacks(&"hairpin_winds") > 0 else 0.0`
  - const HAIRPIN_WINDS_EXTRA := 1  # Pinwheel / Windmill: +1 max adjacent path tile

## hammer_and_anvil
- `scripts/tower/tower.gd:933`: `chance = attack_data.crit_chance + _aura_crit + 0.1 * kin_share(&"hammer_and_anvil", "a")  # Hammer and Anvil: the sniper's eye`
- `scripts/tower/tower.gd:1569`: `var hammer := kin_share(&"hammer_and_anvil", "a")`
- `scripts/tower/tower.gd:1755`: `var anvil := kin_share(&"hammer_and_anvil", "b")`
- `scripts/combat/kinships.gd:50`: `&"hammer_and_anvil": ["Hammer and Anvil", "stone", "mossback", "standing_stone", false],`

## harvest_moon
- `scripts/tower/dew_catch.gd:98`: `var harvest_multiplier := 1.0 + (HARVEST_MOON if dreams and dreams.has_rule(&"harvest_moon") else 0.0)`
  - const HARVEST_MOON := 0.5  # Harvest Moon (Seed card): the Harvest pays +50%

## heavy_air
- `scripts/tower/tower.gd:3369`: `return 1.0 + DreamState.HEAVY_AIR_BONUS if _rule_stacks(&"heavy_air") > 0 else 1.0`
  - const HEAVY_AIR_BONUS := 0.40

## heavy_eyelids
- `scripts/combat/reactions.gd:293`: `if dreams == null or not dreams.has_rule(&"heavy_eyelids"):`
- `scripts/combat/reactions.gd:297`: `return 3 if dreams.rule_level(&"heavy_eyelids") > 0 else 2`

## heavy_seed
- `scripts/tower/seed_boomerang.gd:130`: `var pass_multiplier := _damage_multiplier * (2.0 if _returning and dreams and dreams.has_rule(&"heavy_seed") else 1.0)`

## hedgerow_roots
- `scripts/tower/tower.gd:1052`: `if _rule_stacks(&"hedgerow_roots") <= 0:`

## hoar_fog
- `scripts/tower/path_cloud.gd:88`: `var hoar := _tower.kin_share(&"hoar_fog", "b")`
- `scripts/tower/path_cloud.gd:92`: `_tower._kin_fired(&"hoar_fog")`
- `scripts/tower/tower.gd:2133`: `var fog := kin_share(&"hoar_fog", "a")`
- `scripts/tower/tower.gd:2136`: `_kin_fired(&"hoar_fog")`
- `scripts/combat/kinships.gd:58`: `&"hoar_fog": ["Hoar Fog", "water", "frostfern", "mistveil", false],`

## hummingheart
- `scripts/tower/grove_rules.gd:42`: `if tower._dream_state == null or not tower._has_rule(&"hummingheart") or tower.attack_data.attacks_per_second <= 0.0:`
- `scripts/tower/tower.gd:542`: `* (1.0 + (GroveRules.hummingheart(self, get_attacks_per_second()) if _dream_state and _has_rule(&"hummingheart") else 0.0))`

## hunters_moon
- `scripts/tower/tower.gd:1682`: `if _has_rule(&"hunters_moon"):`

## hush
- `scripts/tower/tower.gd:631`: `total *= 1.0 + HUSH_RADIUS * _rule_stacks(&"hush") * _rule_power(&"hush")  # Hush: wider song pulses`
  - const HUSH_RADIUS := 0.25  # Hush: Bellflower-line pulses +25% radius per stack (max 3; dream_audit.md)

## ill_wind
- `scripts/tower/tower.gd:2949`: `var ill_wind := 1.0 + (DreamState.ILL_WIND_BONUS * _rule_power(&"ill_wind") if _rule_stacks(&"ill_wind") > 0 else 0.0)`
  - const ILL_WIND_BONUS := 0.45  # Effect damage of statuses Gust / Zephyr copied

## jewel_thieves
- `scripts/tower/tower.gd:1905`: `if _kin_roll(kin_share(&"jewel_thieves", "b")):`
- `scripts/tower/tower.gd:1907`: `_kin_fired(&"jewel_thieves")`
- `scripts/tower/tower.gd:2800`: `if kin_share(&"jewel_thieves", "a") > 0.0 and is_instance_valid(enemy) and not enemy.is_cleansed:`
- `scripts/tower/tower.gd:2802`: `if _jewel_pecks % JEWEL_THIEVES_EVERY == 0 and _kin_roll(kin_share(&"jewel_thieves", "a")):`
  - const JEWEL_THIEVES_EVERY := 6  # Jewel Thieves A: every 6th peck strips a buff (+1 Dew if there's none)
- `scripts/tower/tower.gd:2806`: `_kin_fired(&"jewel_thieves")`
- `scripts/combat/kinships.gd:64`: `&"jewel_thieves": ["Jewel Thieves", "wing", "hummingbird_bower", "magpie_perch", false],`

## kind_canopy
- `scripts/tower/tower.gd:997`: `if _rule_stacks(&"kind_canopy") > 0 and KIND_CANOPY_WARDENS.has(tower_data.get_id()):`
  - const KIND_CANOPY_WARDENS := ["acorn", "elder_stump", "grove_heart"]  # Kind Canopy (Seed card): these auras reach…

## lantern_roots
- `scripts/tower/tower.gd:2199`: `var share := kin_share(&"lantern_roots", "b")`
- `scripts/tower/tower.gd:2210`: `_kin_fired(&"lantern_roots")`
- `scripts/tower/tower.gd:3333`: `var roots := kin_share(&"lantern_roots", "a")`
- `scripts/tower/tower.gd:3342`: `_kin_fired(&"lantern_roots")`
- `scripts/combat/kinships.gd:61`: `&"lantern_roots": ["Lantern Roots", "root", "rootlight", "tangleroot", false],`

## living_walls
- `scripts/tower/tower.gd:2654`: `or _rule_stacks(&"living_walls") <= 0 or DreamState.drifts_stood(self) < LIVING_WALLS_DRIFTS:`
  - const LIVING_WALLS_DRIFTS := 5

## longer_flight
- `scripts/tower/tower.gd:2820`: `var length := (attack_data.boomerang_length + _rule_stacks(&"longer_flight")) * MAP_GRID.cell_size.x`
  - const MAP_GRID = preload("res://resource/map/map_grid.tres")

## loose_stones
- `scripts/tower/tower.gd:1976`: `if _dream_state and _has_rule(&"loose_stones"):`

## many_threads
- `scripts/tower/tower.gd:2399`: `var many_threads := _rule_stacks(&"many_threads") > 0  # Many Threads: Catch at 4 Drowsy`

## momentum
- `scripts/tower/final_twists.gd:17`: `"windmill": &"momentum", "elf_circle": &"fairy_dance"}`
- `scripts/tower/final_twists.gd:75`: `&"momentum":`
- `scripts/tower/final_twists.gd:77`: `_update_momentum_art(tower, state.get(&"momentum", 0.0))`
- `scripts/tower/final_twists.gd:381`: `var momentum: float = state.get(&"momentum", 0.0)`
- `scripts/tower/final_twists.gd:386`: `state[&"momentum"] = momentum`
- `scripts/tower/final_twists.gd:389`: `return tower._twist_state.get(&"momentum", 0.0) if tower._twist == &"momentum" else 0.0`
- `scripts/tower/grove_rules.gd:17`: `if tower._has_rule(&"momentum"):`
- `scripts/tower/tower.gd:79`: `const GROVE_SPEED_RULES: Array[StringName] = [&"momentum", &"quickening"]  # GroveRules (Swift)`
  - const GROVE_SPEED_RULES: Array[StringName] = [&"momentum", &"quickening"]  # GroveRules (Swift)
- `scripts/tower/tower.gd:554`: `var momentum := FinalTwists.momentum(self) if _twist == &"momentum" else 0.0  # Windmill: spins up`
- `scripts/tower/tower.gd:1590`: `if _dream_state and not is_area and _has_rule(&"momentum"):`

## mountains_fall
- `scripts/combat/reactions.gd:372`: `if dreams and dreams.has_rule(&"mountains_fall") and not rubble.is_empty():`

## mushroom_rain
- `scripts/combat/reactions.gd:636`: `if dreams and dreams.has_rule(&"mushroom_rain"):`

## mycelium
- `scripts/tower/tower.gd:1322`: `const CATALOGUE_HIT_RULES: Array[StringName] = [&"mycelium", &"fireflies_in_the_grass", &"resonance"]`
  - const CATALOGUE_HIT_RULES: Array[StringName] = [&"mycelium", &"fireflies_in_the_grass", &"resonance"]
- `scripts/tower/tower.gd:2981`: `if _touch_lines.has("spore") and _rule_stacks(&"mycelium") > 0:`
- `scripts/tower/tower.gd:2982`: `_apply_one_status(enemy, EnemyStatuses.SPORED, roundi(DreamState.MYCELIUM_SPORED * _rule_power(&"mycelium")), get_damage())`
  - const MYCELIUM_SPORED := 1  # Poisoned stacks a Sprout touching a Sporeling-line Warden applies on hit
  - const SPORED := &"spored"

## needle_point
- `scripts/tower/tower.gd:2796`: `if _dream_state and _has_rule(&"needle_point"):`

## night_chimes
- `scripts/tower/tower.gd:1647`: `var share := kin_share(&"night_chimes", "a")`
- `scripts/tower/tower.gd:1663`: `if not is_instance_valid(enemy) or enemy.is_cleansed or not _kin_roll(kin_share(&"night_chimes", "b")):`
- `scripts/combat/kinships.gd:52`: `&"night_chimes": ["Night Chimes", "song", "chime_stone", "dreamcatcher", true],  # In the demo since Bellflower starts there (meta_design.md a3375108)`

## nightshade
- `scripts/combat/reactions.gd:239`: `if dreams == null or not dreams.has_rule(&"nightshade"):`

## old_growth
- `scripts/tower/tower.gd:1197`: `var growth: float = other.kin_share(&"old_growth", "b") if distance <= 1.5 else 0.0`
- `scripts/tower/tower.gd:2552`: `var growth := kin_share(&"old_growth", "a")`
- `scripts/combat/kinships.gd:53`: `&"old_growth": ["Old Growth", "acorn", "elder_stump", "dewcatcher", false],`
- `scripts/combat/support_log.gd:156`: `if tower.is_catcher() or tower.kin_share(&"old_growth", "a") > 0.0:`

## overflowing_well
- `scripts/tower/dew_catch.gd:122`: `if dreams and dreams.has_rule(&"overflowing_well") and uncapped > cap:`

## overgrown
- `scripts/tower/tower_seller.gd:117`: `if dreams != null and dreams.has_rule(&"overgrown"):`

## overlap
- `scripts/tower/tower.gd:1560`: `if is_area and _dream_state and _has_rule(&"overlap"):`

## patient_aim
- `scripts/tower/tower.gd:1321`: `const HIT_CARD_RULES: Array[StringName] = [&"patient_aim", &"crush", &"crowd_breaker", &"shiny_things"]`
  - const HIT_CARD_RULES: Array[StringName] = [&"patient_aim", &"crush", &"crowd_breaker", &"shiny_things"]
- `scripts/tower/tower.gd:1348`: `if _rule_stacks(&"patient_aim") > 0:`
- `scripts/tower/tower.gd:1349`: `multiplier *= 1.0 + minf(DreamState.PATIENT_AIM_PER * _aim_idle, DreamState.PATIENT_AIM_MAX) * _rule_power(&"patient_aim")  # Slow snipers gain most`
  - const PATIENT_AIM_MAX := 0.60
  - const PATIENT_AIM_PER := 0.15  # Per second a Warden hasn't fired

## patient_roots
- `scripts/tower/tower.gd:2071`: `bonus += PATIENT_ROOTS_ROOT_HOLD * _rule_power(&"patient_roots")`
  - const PATIENT_ROOTS_ROOT_HOLD := 0.25  # …and holds this much longer, on top of the +0.25 s for every Hold
- `scripts/tower/tower.gd:2242`: `if tower_data.line == "root" and _rule_stacks(&"patient_roots") > 0:`
- `scripts/tower/tower.gd:2243`: `tiles += PATIENT_ROOTS_PULL * _rule_power(&"patient_roots")`
  - const PATIENT_ROOTS_PULL := 0.5  # Patient Roots (Seed card): the Rootling line pulls this much further…

## pollen_beaks
- `scripts/tower/tower.gd:2811`: `if _has_rule(&"pollen_beaks"):`

## prism_heart
- `scripts/combat/reactions.gd:384`: `var level := 1 if prism and dreams and dreams.has_rule(&"prism_heart") else 0`

## quick_reactions
- `scripts/combat/reactions.gd:801`: `if dreams and dreams.has_rule(&"quick_reactions"):`

## quickening
- `scripts/tower/grove_rules.gd:20`: `if tower._has_rule(&"quickening") and tower._grove.get(&"quick_until", -1.0) > tower._anim_time:`
- `scripts/tower/grove_rules.gd:36`: `if tower is Tower and tower.tower_data.can_attack and tower._has_rule(&"quickening") \`
- `scripts/tower/grove_rules.gd:133`: `if is_instance_valid(dreams) and dreams.has_rule(&"quickening") and is_instance_valid(enemy):`
- `scripts/tower/tower.gd:79`: `const GROVE_SPEED_RULES: Array[StringName] = [&"momentum", &"quickening"]  # GroveRules (Swift)`
  - const GROVE_SPEED_RULES: Array[StringName] = [&"momentum", &"quickening"]  # GroveRules (Swift)

## rainfog
- `scripts/tower/tower.gd:1637`: `var fog := kin_share(&"rainfog", "b")`
- `scripts/tower/tower.gd:1642`: `_kin_fired(&"rainfog")`
- `scripts/tower/tower.gd:1930`: `var rainfog := kin_share(&"rainfog", "a")`
- `scripts/tower/tower.gd:1933`: `_kin_fired(&"rainfog")`
- `scripts/combat/kinships.gd:48`: `&"rainfog": ["Rainfog", "water", "rain_lily", "mistveil", true],`

## resonance
- `scripts/tower/tower.gd:1322`: `const CATALOGUE_HIT_RULES: Array[StringName] = [&"mycelium", &"fireflies_in_the_grass", &"resonance"]`
  - const CATALOGUE_HIT_RULES: Array[StringName] = [&"mycelium", &"fireflies_in_the_grass", &"resonance"]
- `scripts/tower/tower.gd:2988`: `_apply_one_status(enemy, EnemyStatuses.STATIC, roundi(DreamState.RESONANCE_CHARGED * _rule_power(&"resonance")), get_damage())`
  - const RESONANCE_CHARGED := 1  # Chime Stone pulses count as lightning: +1 Charged per nightmare hit
  - const STATIC := &"static"
- `scripts/tower/tower.gd:2991`: `return _dream_state != null and tower_data.get_id() == "chime_stone" and _has_rule(&"resonance")`

## resonant_hollow
- `scripts/tower/tower.gd:2170`: `var share := kin_share(&"resonant_hollow", "b")`
- `scripts/tower/tower.gd:2182`: `_kin_fired(&"resonant_hollow")`
- `scripts/tower/tower.gd:2186`: `if not _kin_roll(kin_share(&"resonant_hollow", "a")) or not is_instance_valid(enemy) or enemy.is_cleansed:`
- `scripts/tower/tower.gd:2195`: `_kin_fired(&"resonant_hollow")`
- `scripts/combat/kinships.gd:62`: `&"resonant_hollow": ["Resonant Hollow", "song", "echo_hollow", "chime_stone", false],`

## ricochet
- `scripts/tower/seed_boomerang.gd:40`: `if dreams and dreams.has_rule(&"ricochet"):`
- `scripts/tower/seed_boomerang.gd:41`: `_turns_left = 2 if dreams.rule_level(&"ricochet") > 0 else 1`

## ring_dance
- `scripts/tower/fairy_ring.gd:75`: `if dreams != null and dreams.has_rule(&"ring_dance"):`
- `scripts/tower/fairy_ring.gd:76`: `var dance := DreamState.RING_DANCE_TILES * dreams.rule_power(&"ring_dance") * Tower.MAP_GRID.cell_size.x`
  - const MAP_GRID = preload("res://resource/map/map_grid.tres")
  - const RING_DANCE_TILES := 2.0  # A Fairy Ring burst sets off rings this close

## ring_of_rings
- `scripts/combat/reactions.gd:608`: `var ring_of_rings := dreams != null and dreams.has_rule(&"ring_of_rings")`

## rolling_thunder
- `scripts/combat/reactions.gd:474`: `if dreams and dreams.has_rule(&"rolling_thunder"):`
- `scripts/combat/reactions.gd:475`: `level = 1 + dreams.rule_level(&"rolling_thunder")`

## root_network
- `scripts/tower/tower.gd:3377`: `if tower_data.get_id() == "sprout" and _dream_state and _has_rule(&"root_network"):`
- `scripts/tower/tower.gd:3378`: `var diagonals := _rule_level(&"root_network") > 0`

## rooted_nightmares
- `scripts/tower/tower.gd:1698`: `if _has_rule(&"rooted_nightmares") and _hits_landed % ROOTED_NIGHTMARES_EVERY == 0:`
  - const ROOTED_NIGHTMARES_EVERY := 8
- `scripts/enemy/enemy_spawner.gd:29`: `const ROOTED_RULE := &"rooted_nightmares"`
  - const ROOTED_RULE := &"rooted_nightmares"

## scented_hedge
- `scripts/tower/tower.gd:2613`: `var scent := _scented_by() if _rule_stacks(&"scented_hedge") > 0 else null`

## seed_storm
- `scripts/tower/tower.gd:2827`: `if _dream_state and _has_rule(&"seed_storm") and _throws % 5 == 0:`

## shared_light
- `scripts/tower/tower.gd:1027`: `if _rule_stacks(&"shared_light") > 0:`
- `scripts/tower/tower.gd:1028`: `bonus *= 1.0 + SHARED_LIGHT * _rule_power(&"shared_light")`
  - const SHARED_LIGHT := 0.5  # Shared Light (Seed card): aura bonuses +50%

## sharp_beaks
- `scripts/tower/tower.gd:1911`: `for i in _rule_stacks(&"sharp_beaks"):`
- `scripts/tower/tower.gd:2780`: `var pecks := attack_data.pecks + _rule_stacks(&"sharp_beaks")`

## shattering_blow
- `scripts/tower/tower.gd:1712`: `if _dream_state == null or not _has_rule(&"shattering_blow"):`
- `scripts/tower/tower.gd:1714`: `var deep := _rule_level(&"shattering_blow") > 0`
- `scripts/tower/tower.gd:1720`: `other.take_damage(dealt * share, tower_data.line, true, false, self, &"shattering_blow")`

## shiny_things
- `scripts/tower/tower.gd:1321`: `const HIT_CARD_RULES: Array[StringName] = [&"patient_aim", &"crush", &"crowd_breaker", &"shiny_things"]`
  - const HIT_CARD_RULES: Array[StringName] = [&"patient_aim", &"crush", &"crowd_breaker", &"shiny_things"]
- `scripts/tower/tower.gd:1361`: `multiplier *= 1.0 + DreamState.SHINY_THINGS_BONUS * _shiny.size() * _rule_power(&"shiny_things")`
  - const SHINY_THINGS_BONUS := 0.15  # Per stolen buff, SHINY_THINGS_TIME s, max SHINY_THINGS_STACKS
- `scripts/tower/tower.gd:1365`: `if _rule_stacks(&"shiny_things") <= 0:`

## skyward_gaze
- `scripts/tower/tower.gd:3568`: `if _rule_stacks(&"skyward_gaze") > 0:`
- `scripts/tower/tower.gd:3795`: `if _rule_stacks(&"skyward_gaze") > 0:`

## slumber_rot
- `scripts/tower/tower.gd:1634`: `if _kin_roll(kin_share(&"slumber_rot", "b")):`
- `scripts/tower/tower.gd:1636`: `_kin_fired(&"slumber_rot")`
- `scripts/tower/tower.gd:1802`: `if _kin_roll(kin_share(&"slumber_rot", "a")):`
- `scripts/tower/tower.gd:1804`: `_kin_fired(&"slumber_rot")`
- `scripts/combat/kinships.gd:47`: `&"slumber_rot": ["Slumber Rot", "spore", "driftspore", "bloomcap", true],`

## snare
- `scripts/tower/final_twists.gd:85`: `if _tick(state, &"snare", delta, SNARE_CHECK):`
  - const SNARE_CHECK := 0.1
- `scripts/tower/tower.gd:2048`: `var snare := kin_share(&"snare", "a")`
- `scripts/tower/tower.gd:2051`: `_kin_fired(&"snare"))`
- `scripts/tower/tower.gd:2059`: `var drag := kin_share(&"snare", "b")`
- `scripts/tower/tower.gd:2062`: `_kin_fired(&"snare")`
- `scripts/combat/kinships.gd:51`: `&"snare": ["Snare", "root", "rootcurl", "tangleroot", false],`
- `scripts/enemy/enemy.gd:1935`: `var snare := holder.kin_share(&"snare", "a")`
- `scripts/enemy/enemy.gd:1940`: `holder._kin_fired(&"snare")`

## spillover
- `scripts/tower/grove_rules.gd:89`: `other.take_damage(leftover, tower.tower_data.line, true, false, tower, &"spillover")`
- `scripts/tower/tower.gd:1592`: `if _dream_state and is_area and combo != &"spillover" and enemy.is_cleansed and _has_rule(&"spillover"):`

## spore_nursery
- `scripts/tower/tower.gd:1808`: `if attack_data.attack_kind == TowerData.AttackKind.TRAP and _kin_roll(kin_share(&"spore_nursery", "a")):`
- `scripts/tower/tower.gd:1810`: `_kin_fired(&"spore_nursery")`
- `scripts/tower/tower.gd:2137`: `var nursery := kin_share(&"spore_nursery", "b")`
- `scripts/tower/tower.gd:2147`: `_kin_fired(&"spore_nursery")`
- `scripts/combat/kinships.gd:57`: `&"spore_nursery": ["Spore Nursery", "spore", "fairy_ring", "driftspore", false],`

## spotter
- `scripts/tower/tower.gd:1915`: `if crit == NO_CRIT and target != null and is_instance_valid(target) and _kin_roll(kin_share(&"spotter", "a")):`
  - const NO_CRIT := 0
- `scripts/tower/tower.gd:1917`: `_kin_fired(&"spotter")`
- `scripts/tower/tower.gd:1998`: `if kin_share(&"spotter", "a") > 0.0:`
- `scripts/tower/tower.gd:2160`: `var share := kin_share(&"spotter", "b")`
- `scripts/combat/kinships.gd:60`: `&"spotter": ["Spotter", "stone", "cairn", "standing_stone", false],`

## static_bloom
- `scripts/tower/tower.gd:2291`: `if _dream_state and _has_rule(&"static_bloom"):`
- `scripts/tower/tower.gd:2292`: `bloom = 2 if _rule_level(&"static_bloom") > 0 else 1`

## static_field
- `scripts/combat/reactions.gd:426`: `if dreams == null or not dreams.has_rule(&"static_field"):`
- `scripts/combat/reactions.gd:428`: `var deep := dreams.rule_level(&"static_field") > 0`

## storm_beacon
- `scripts/tower/tower.gd:1805`: `if _kin_roll(kin_share(&"storm_beacon", "b")):`
- `scripts/tower/tower.gd:1807`: `_kin_fired(&"storm_beacon")`
- `scripts/tower/tower.gd:2298`: `var beacon := kin_share(&"storm_beacon", "a")`
- `scripts/combat/kinships.gd:49`: `&"storm_beacon": ["Storm Beacon", "light", "stormcap", "lanternmoth", true],`

## sudden_bloom
- `scripts/tower/tower.gd:422`: `if _rule_stacks(&"sudden_bloom") > 0:`
- `scripts/tower/tower.gd:423`: `bloom_left = maxf(bloom_left, SUDDEN_BLOOM_SECONDS * _rule_power(&"sudden_bloom"))  # ×2 damage for 10 s`
  - const SUDDEN_BLOOM_SECONDS := 10.0  # dream_audit.md: was "next 3 attacks ×2"

## sunspot
- `scripts/tower/tower.gd:1555`: `if kin_share(&"sunspot", "b") > 0.0:  # Sunspot: hits in a row on one nightmare ramp up`
- `scripts/tower/tower.gd:1758`: `var sun := kin_share(&"sunspot", "b")`
- `scripts/tower/tower.gd:3126`: `and _kin_roll(kin_share(&"sunspot", "a")):`
- `scripts/tower/tower.gd:3128`: `_kin_fired(&"sunspot")`
- `scripts/combat/kinships.gd:59`: `&"sunspot": ["Sunspot", "light", "sunpetal", "lanternmoth", false],`

## sweet_scent
- `scripts/tower/tower.gd:628`: `if tower_data.get_id() == "honeysuckle" and _rule_stacks(&"sweet_scent") > 0:`
- `scripts/tower/tower.gd:629`: `total = maxf(total, DreamState.SWEET_SCENT_TILES * _rule_power(&"sweet_scent"))  # Sweet Scent`
  - const SWEET_SCENT_TILES := 2.0  # Honeysuckle's Drowsy reach

## tailwind
- `scripts/tower/seed_boomerang.gd:121`: `var full := Tower._kin_roll(_tower.kin_share(&"tailwind", "a")) if is_instance_valid(_tower) else false  # Tailwind: full stacks`
- `scripts/tower/tower.gd:2940`: `var reach := lerpf(attack_data.spread_radius, TAILWIND_REACH, kin_share(&"tailwind", "b")) * MAP_GRID.cell_size.x  # Tailwind`
  - const MAP_GRID = preload("res://resource/map/map_grid.tres")
  - const TAILWIND_REACH := 3.0  # Tailwind B: Gust's copies reach this far
- `scripts/combat/kinships.gd:65`: `&"tailwind": ["Tailwind", "wind", "samara", "gust", false],`

## the_quiet_ones
- `scripts/tower/tower.gd:1045`: `return 1.0 + QUIET_ONES if is_quiet() and _rule_stacks(&"the_quiet_ones") > 0 else 1.0`
  - const QUIET_ONES := 0.5  # The Quiet Ones: non-attacking Wardens +50%

## thorn_snare
- `scripts/tower/tower.gd:2612`: `var snare := _rule_stacks(&"thorn_snare") > 0`
- `scripts/tower/tower.gd:2616`: `var level: int = _rule_level(&"thorn_snare") if snare else 0`

## thornheart
- `scripts/tower/tower.gd:1037`: `if tower_data.get_id() == "bramble" and _rule_stacks(&"thornheart") > 0:`
- `scripts/tower/tower.gd:1039`: `multiplier *= 1.0 + minf(DreamState.THORNHEART_PER * brambles, DreamState.THORNHEART_MAX) * _rule_power(&"thornheart")  # Thornheart`
  - const THORNHEART_MAX := 1.0
  - const THORNHEART_PER := 0.05  # Bramble thorns, per Bramble you own

## thousand_cuts
- `scripts/tower/tower.gd:1598`: `if _dream_state and _has_rule(&"thousand_cuts") and is_instance_valid(enemy):`

## true_graft
- `scripts/tower/tower.gd:1233`: `_graft_status = _strongest_neighbour_status() if kin_share(&"true_graft", "b") > 0.0 else []`
- `scripts/tower/tower.gd:1245`: `_damage_share = lerpf(tower_data.copy_share, 1.0, kin_share(&"true_graft", "a")) if best != null else 1.0  # True Graft: 100%`
- `scripts/tower/tower.gd:1811`: `if not _graft_status.is_empty() and _kin_roll(kin_share(&"true_graft", "b")):`
- `scripts/tower/tower.gd:1813`: `_kin_fired(&"true_graft")`
- `scripts/combat/kinships.gd:63`: `&"true_graft": ["True Graft", "acorn", "graftling", "elder_stump", false],`

## twin_puff
- `scripts/tower/tower.gd:1704`: `if tower_data.get_id() != "sporeling" or _dream_state == null or not _has_rule(&"twin_puff"):`
- `scripts/tower/tower.gd:1706`: `var every := 2 if _rule_level(&"twin_puff") > 0 else 3`

## warm_hearth
- `scripts/tower/tower.gd:1224`: `if tower_data.get_id() == "sprout" and _rule_stacks(&"warm_hearth") > 0:`
- `scripts/tower/tower.gd:1225`: `var hearth := 1.0 + DreamState.WARM_HEARTH_SPROUTS * _rule_power(&"warm_hearth")  # Warm Hearth: auras on Sprouts`
  - const WARM_HEARTH_SPROUTS := 0.50  # Aura bonuses on Sprouts

## watchful_rest
- `scripts/tower/tower.gd:1453`: `if watch_charged or _rule_stacks(&"watchful_rest") <= 0:`
- `scripts/tower/tower.gd:1462`: `elif _watch_time >= DreamState.WATCHFUL_REST_TIME[mini(_rule_level(&"watchful_rest"), 1)]:`
  - const WATCHFUL_REST_TIME := [5.0, 3.0]

## whirlwind_heart
- `scripts/tower/tower.gd:576`: `if _dream_state and _has_rule(&"whirlwind_heart"):`

## wildfire_spores
- `scripts/combat/reactions.gd:573`: `var level := 1 if dreams and dreams.has_rule(&"wildfire_spores") else 0`

## windborne_rain
- `scripts/tower/seed_boomerang.gd:137`: `if dreams and dreams.has_rule(&"windborne_rain"):`

