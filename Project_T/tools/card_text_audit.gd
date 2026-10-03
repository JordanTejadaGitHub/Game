extends SceneTree

# Card text audit dump (Roguelite Mechanic Discussion, 2026-10-02): one row per Dream card (base and Deepened) with
# its Needs, text, every numeric field that differs from UpgradeData's default, the constants the code uses for its
# rule id, and a number check (the text's numbers that match no field or constant: "unmatched: …").
#   godot --headless --path . --script res://tools/card_text_audit.gd
# Writes documentation/card_text_audit.csv. The logic is tools/card_text_check.gd (tests/test_card_text.gd uses it).

const Check := preload("res://tools/card_text_check.gd")
const OUT := "res://documentation/card_text_audit.csv"

func _initialize() -> void:
	var rows := Check.csv_rows()
	var file := FileAccess.open(OUT, FileAccess.WRITE)
	if file == null:
		printerr("card_text_audit: can't write %s" % OUT)
		quit(1)
		return
	file.store_string(Check.to_csv(rows))
	file.close()
	var flagged := rows.slice(1).filter(func(row: PackedStringArray) -> bool: return row[row.size() - 1].begins_with("unmatched")).size()
	print("card_text_audit: %d cards, %d with unmatched numbers -> %s" % [rows.size() - 1, flagged, ProjectSettings.globalize_path(OUT)])
	quit(0)
