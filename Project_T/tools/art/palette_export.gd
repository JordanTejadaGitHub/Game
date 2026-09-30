extends SceneTree
# Writes the Heartwood 32 palette (HeartwoodPalette) to assets/palette/ for art tools outside Godot:
#   heartwood32.gpl        GIMP / Aseprite / Krita palette, one named colour per line
#   heartwood32.hex        Lospec-style hex list, one colour per line (ramp order)
#   heartwood32.json       names, ramps and the cold-ramp flag, for the JS generators
#   heartwood32.png        32x1 palette image (one pixel per colour, ramp order)
#   heartwood32_ramps.png  swatch sheet: one row per ramp, 16 px chips
#   heartwood35_wardens.gpl / .hex  the Warden Night set (the 32 + Rosedust, Plum, Nightbloom),
#                          for Warden idle sheets only
# Run:  Godot --headless --path . --script res://tools/art/palette_export.gd

const OUT := "res://assets/palette/"
const CHIP := 16


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var cols := HeartwoodPalette.colors()
	var names := HeartwoodPalette.names()

	var gpl := "GIMP Palette\nName: Heartwood 32\nColumns: 8\n# documentation/art_direction.md\n"
	var hex := ""
	for i in cols.size():
		var c := cols[i]
		gpl += "%3d %3d %3d\t%s\n" % [c.r8, c.g8, c.b8, names[i]]
		hex += c.to_html(false) + "\n"
	_save_text(OUT + "heartwood32.gpl", gpl)
	_save_text(OUT + "heartwood32.hex", hex)

	var ramps := []
	for r: Dictionary in HeartwoodPalette.RAMPS:
		var entries := []
		for e: Array in r.colors:
			entries.append({"name": e[0], "hex": "#" + e[1]})
		ramps.append({"name": r.name, "role": r.role, "cold": r.name in HeartwoodPalette.COLD_RAMPS,
			"colors": entries})
	var warden := []
	for e: Array in HeartwoodPalette.WARDEN_COLORS:
		warden.append({"name": e[0], "hex": "#" + e[1], "role": e[2]})
	_save_text(OUT + "heartwood32.json", JSON.stringify({"name": "Heartwood 32", "ramps": ramps,
		"warden_only": warden, "warden_night_map": HeartwoodPalette.WARDEN_NIGHT_MAP}, "\t") + "\n")

	# Warden Night: the 35-colour set Warden idle sheets may use (the 32 + Rosedust, Plum, Nightbloom).
	var gpl35 := "GIMP Palette\nName: Heartwood 35 (Wardens)\nColumns: 8\n# Warden idle sheets only: documentation/warden_night.md\n"
	var hex35 := ""
	var names35 := names.duplicate()
	for e: Array in HeartwoodPalette.WARDEN_COLORS:
		names35.append(e[0])
	var cols35 := HeartwoodPalette.warden_colors()
	for i in cols35.size():
		gpl35 += "%3d %3d %3d\t%s\n" % [cols35[i].r8, cols35[i].g8, cols35[i].b8, names35[i]]
		hex35 += cols35[i].to_html(false) + "\n"
	_save_text(OUT + "heartwood35_wardens.gpl", gpl35)
	_save_text(OUT + "heartwood35_wardens.hex", hex35)

	var strip := Image.create(cols.size(), 1, false, Image.FORMAT_RGBA8)
	for i in cols.size():
		strip.set_pixel(i, 0, cols[i])
	strip.save_png(OUT + "heartwood32.png")

	var widest := 0
	for r: Dictionary in HeartwoodPalette.RAMPS:
		widest = maxi(widest, r.colors.size())
	var sheet := Image.create(widest * CHIP, HeartwoodPalette.RAMPS.size() * CHIP, false, Image.FORMAT_RGBA8)
	for row in HeartwoodPalette.RAMPS.size():
		var r: Dictionary = HeartwoodPalette.RAMPS[row]
		for col in r.colors.size():
			sheet.fill_rect(Rect2i(col * CHIP, row * CHIP, CHIP, CHIP), Color.html(r.colors[col][1]))
	sheet.save_png(OUT + "heartwood32_ramps.png")

	print("Heartwood 32 written to ", OUT)
	quit()


func _save_text(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
