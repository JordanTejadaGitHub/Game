extends SceneTree

# Headless test for IconInfo's {field:warden.field[:format]} token (text_pass.md 797758fe: Warden cards quoted numbers
# that drifted from their TowerData; the token reads them from the data). Run:
#   godot --headless --path . --script res://tests/test_field_tokens.gd

var failures := 0

func _initialize() -> void:
	var thunder: TowerData = load("res://resource/tower/thunderhead.tres")
	var snug: TowerData = load("res://resource/tower/snugroot.tres")
	var graft: TowerData = load("res://resource/tower/graftling.tres")
	_check(IconInfo.format("every {field:thunderhead.storm_every}th") == "every %dth" % thunder.storm_every,
		"a plain field reads the data (%s)" % IconInfo.format("{field:thunderhead.storm_every}"))
	_check(IconInfo.format("Holds {field:snugroot.hold_targets:count}") == "Holds %d" % snug.hold_targets, "count")
	_check(IconInfo.format("{field:graftling.copy_share:pct}") == "%d%%" % roundi(graft.copy_share * 100.0),
		"pct (%s)" % IconInfo.format("{field:graftling.copy_share:pct}"))
	_check(IconInfo.format("{field:snugroot.ability_every:seconds}").ends_with(" s"), "seconds")
	_check(IconInfo.format("{field:thunderhead.attack_range:cells}").contains("cell"), "cells")
	_check(IconInfo.format("{field:nobody.storm_every}") == "nobody.storm_every", "an unknown Warden shows the token's path, never crashes")
	_check(IconInfo.format("{field:thunderhead.no_such_field}") == "thunderhead.no_such_field", "an unknown field too")
	_check(IconInfo._number(1.5) == "1.5" and IconInfo._number(3.0) == "3", "whole numbers lose their decimals")
	# One Dictionary key deep (BranchKit specials) and a rate as its period (Roguelite df57f046's last exceptions).
	var nimbus: TowerData = load("res://resource/tower/nimbus.tres")
	_check(IconInfo.format("{field:nimbus.special_params.drift_every:seconds}") == "%s s" % IconInfo._number(nimbus.special_params.drift_every),
		"a special_params key (%s)" % IconInfo.format("{field:nimbus.special_params.drift_every:seconds}"))
	_check(IconInfo.format("{field:nimbus.special_params.nope}") == "nimbus.special_params.nope", "an unknown key shows its path")
	var root_data: TowerData = load("res://resource/tower/world_root.tres")
	_check(IconInfo.format("every {field:world_root.attacks_per_second:every}") == "every %s s" % IconInfo._number(1.0 / root_data.attacks_per_second),
		"every: a rate as its period (%s)" % IconInfo.format("{field:world_root.attacks_per_second:every}"))
	print("field tokens test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
