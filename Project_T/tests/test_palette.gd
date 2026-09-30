extends SceneTree
# The Heartwood 32 palette and the detail pass (tools/art/): 32 unique named colours, snap() only
# ever returns palette colours (cold ramps only for nightmares), the exported palette files match,
# and the detail pass keeps nightmares cold and the value order ground < obstacles < path.
# Run:  Godot --headless --path . --script res://tests/test_palette.gd
# Pass `-- --preview=C:/tmp/dir` to also save before/after sheets of a few real sprites.

var failures := 0


func _init() -> void:
	var cols := HeartwoodPalette.colors()
	var names := HeartwoodPalette.names()
	_check(cols.size() == 32 and names.size() == 32, "32 colours, 32 names")
	var seen := {}
	for c in cols:
		seen[c.to_html(false)] = true
	_check(seen.size() == 32, "all 32 colours are different")
	var lower := {}
	for n in names:
		lower[n.to_lower()] = true
	_check(lower.size() == 32, "all 32 names are different")
	_check(HeartwoodPalette.color("gold") == Color.html("e9a83c") and HeartwoodPalette.color("Moonpath")
		== Color.html("dccdb2"), "colours by name")
	_check(HeartwoodPalette.ramp("Moss").size() == 5 and HeartwoodPalette.ramp("Moss")[0]
		== HeartwoodPalette.color("deepmoss"), "ramps dark to light")

	var cold := 0
	for c in cols:
		_check(HeartwoodPalette.snap(c) == c, "a palette colour snaps to itself: %s" % c.to_html(false))
		if HeartwoodPalette.is_cold(c):
			cold += 1
	_check(cold == 14, "14 cold colours (Ink, Nightmare, Stone & moon, Dew), got %d" % cold)

	var rng := RandomNumberGenerator.new()
	rng.seed = 32
	var bad := 0
	var bad_cold := 0
	for i in 2000:
		var c := Color8(rng.randi_range(0, 255), rng.randi_range(0, 255), rng.randi_range(0, 255))
		if HeartwoodPalette.index_of(HeartwoodPalette.snap(c)) < 0:
			bad += 1
		if not HeartwoodPalette.is_cold(HeartwoodPalette.snap(c, true)):
			bad_cold += 1
	_check(bad == 0, "snap() returns only palette colours (%d misses)" % bad)
	_check(bad_cold == 0, "snap(cold) returns only cold colours (%d misses)" % bad_cold)
	_check(is_equal_approx(HeartwoodPalette.snap(Color(1, 0.8, 0.3, 0.4)).a, 0.4), "snap() keeps alpha")
	_check(HeartwoodPalette.snap(Color8(250, 200, 80), true) != HeartwoodPalette.color("glow")
		and HeartwoodPalette.is_cold(HeartwoodPalette.snap(Color8(250, 200, 80), true)),
		"a warm colour on a nightmare turns cold")

	var img := _noise(64, rng)
	HeartwoodPalette.snap_image(img)
	_check(_only_palette(img, false), "snap_image() leaves only palette colours")
	_check(img.get_pixel(0, 0).a == 0.0 and img.get_pixel(1, 0).a8 == 128,
		"snap_image() keeps alpha")

	_check_files()
	_check_warden_night(rng)
	_check_detail_pass()
	_preview()
	print("test_palette: %d failure(s)" % failures)
	quit(failures)


func _check_files() -> void:
	var hex := FileAccess.get_file_as_string("res://assets/palette/heartwood32.hex").strip_edges().split("\n")
	var cols := HeartwoodPalette.colors()
	var same := hex.size() == 32
	for i in mini(hex.size(), 32):
		same = same and Color.html(hex[i].strip_edges()) == cols[i]
	_check(same, "assets/palette/heartwood32.hex matches (re-run tools/art/palette_export.gd)")
	var gpl := FileAccess.get_file_as_string("res://assets/palette/heartwood32.gpl")
	_check(gpl.begins_with("GIMP Palette") and gpl.count("\n") == 32 + 4, "heartwood32.gpl has 32 colours")
	var strip: Image = load("res://assets/palette/heartwood32.png").get_image()
	_check(strip != null and strip.get_width() == 32 and strip.get_pixel(12, 0) == cols[12],
		"heartwood32.png is the 32x1 palette strip")


# Warden Night (warden_night.md): 35 colours for Warden idle sheets; nothing else ever snaps to the 3.
func _check_warden_night(rng: RandomNumberGenerator) -> void:
	var w35 := HeartwoodPalette.warden_colors()
	var seen := {}
	for c in w35:
		seen[c.to_html(false)] = true
	_check(w35.size() == 35 and seen.size() == 35, "the Warden set has 35 unique colours")
	_check(HeartwoodPalette.colors().size() == 32 and HeartwoodPalette.names().size() == 32,
		"the shared palette stays 32")
	for n in ["rosedust", "plum", "nightbloom"]:
		var c := HeartwoodPalette.color(n)
		_check(HeartwoodPalette.is_warden_only(c) and HeartwoodPalette.index_of(c) == -1
			and not HeartwoodPalette.is_cold(c), "%s is Warden-only" % n)
		_check(HeartwoodPalette.snap(c) != c and HeartwoodPalette.snap(c, true) != c,
			"snap() without wardens never returns %s" % n)
		_check(HeartwoodPalette.snap(c, false, true) == c, "snap(wardens) returns %s" % n)
	var warden_hits := 0
	var bad := 0
	for i in 3000:
		var c := Color8(rng.randi_range(0, 255), rng.randi_range(0, 255), rng.randi_range(0, 255))
		if HeartwoodPalette.is_warden_only(HeartwoodPalette.snap(c)) \
				or HeartwoodPalette.is_warden_only(HeartwoodPalette.snap(c, true)):
			bad += 1
		var s := HeartwoodPalette.snap(c, false, true)
		if HeartwoodPalette.index_of(s, true) < 0:
			bad += 1
		if HeartwoodPalette.is_warden_only(s):
			warden_hits += 1
	_check(bad == 0, "snap() keeps the 3 out of other art; snap(wardens) stays in the 35 (%d misses)" % bad)
	_check(warden_hits > 0, "snap(wardens) does pick the new colours (%d of 3000)" % warden_hits)

	# The map matches the style reference json, and warden_night() applies it.
	var ref: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://assets/style_reference/warden_night/warden_night.json"))
	var same := true
	var listed := 0
	for m: Dictionary in ref.map:
		var to: String = HeartwoodPalette.WARDEN_NIGHT_MAP.get(m.from, m.from)
		same = same and to == m.to and HeartwoodPalette.color(to) == Color.html(m.to_hex)
		listed += 1
	_check(same and listed == 32, "WARDEN_NIGHT_MAP matches warden_night.json (%d entries)" % listed)
	var img := Image.create(35, 1, false, Image.FORMAT_RGBA8)
	var names := HeartwoodPalette.names()
	for i in 32:
		img.set_pixel(i, 0, HeartwoodPalette.color(names[i], 0.6 if i == 0 else 1.0))
	img.set_pixel(32, 0, Color8(250, 160, 250))  # off-palette pink, near Blossom
	img.set_pixel(33, 0, Color(0, 0, 0, 0))
	HeartwoodPalette.warden_night(img)
	var mapped := true
	for i in 32:
		var want := HeartwoodPalette.color(HeartwoodPalette.WARDEN_NIGHT_MAP.get(names[i], names[i]))
		var got := img.get_pixel(i, 0)
		mapped = mapped and Color(got.r, got.g, got.b) == want
	_check(mapped, "warden_night() shifts every colour by the map")
	_check(img.get_pixel(32, 0) == HeartwoodPalette.color("rosedust"), "off-palette pink snaps, then maps to Rosedust")
	_check(img.get_pixel(0, 0).a8 == 153 and img.get_pixel(33, 0).a == 0.0, "warden_night() keeps alpha")

	var gpl := FileAccess.get_file_as_string("res://assets/palette/heartwood35_wardens.gpl")
	_check(gpl.count("\n") == 35 + 4 and "Nightbloom" in gpl, "heartwood35_wardens.gpl has 35 colours")
	var json: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/palette/heartwood32.json"))
	_check(json.get("warden_only", []).size() == 3 and json.get("warden_night_map", {}).size()
		== HeartwoodPalette.WARDEN_NIGHT_MAP.size(), "heartwood32.json lists the Warden-only 3 and the map")


func _check_detail_pass() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 64
	# A blob with a warm light in it, as a Warden and as a nightmare.
	var warden := DetailPass.apply(_blob(rng), DetailPass.Kind.WARDEN)
	_check(_only_palette(warden, false), "the Warden pass leaves only palette colours")
	_check(warden.get_pixel(0, 0).a == 0.0, "the Warden pass keeps the empty corners empty")
	var night := DetailPass.apply(_blob(rng), DetailPass.Kind.NIGHTMARE)
	_check(_only_palette(night, true), "the nightmare pass leaves only cold colours, even on its warm light")
	var smoke := 0
	for y in range(40, 64):
		for x in 64:
			var a := night.get_pixel(x, y).a
			if a > 0.0 and a < 1.0:
				smoke += 1
	_check(smoke > 0, "nightmares get smoke under the silhouette")

	var ground := _flat_tile("deepmoss")
	var path := _flat_tile("moonpath")
	var stone := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	stone.fill_rect(Rect2i(12, 14, 40, 36), HeartwoodPalette.color("void"))
	stone.fill_rect(Rect2i(13, 15, 38, 34), HeartwoodPalette.color("stone"))
	DetailPass.apply(ground, DetailPass.Kind.TILE)
	DetailPass.apply(path, DetailPass.Kind.TILE)
	DetailPass.apply(stone, DetailPass.Kind.OBSTACLE)
	var lg := _mean_l(ground)
	var ls := _mean_l(stone)
	var lp := _mean_l(path)
	_check(lg < ls and ls < lp, "value order holds after the pass: ground %.2f < stone %.2f < path %.2f" % [lg, ls, lp])
	_check(_only_palette(ground, false) and _only_palette(path, false), "tiles snap to the palette")

	var flat := _flat_tile("moss")
	var calm := DetailPass.apply(flat.duplicate(), DetailPass.Kind.TILE, 0, 0.0)
	var busy := DetailPass.apply(flat.duplicate(), DetailPass.Kind.TILE)
	_check(calm.get_data() == flat.get_data() and busy.get_data() != flat.get_data(),
		"texture 0 leaves a flat tile flat; the default adds texture")
	var half := DetailPass.apply(flat.duplicate(), DetailPass.Kind.TILE, 0, 0.5)
	_check(_changed(flat, half) < _changed(flat, busy) and _changed(flat, half) > 0,
		"texture 0.5 adds less texture than the default (%d < %d px)" % [_changed(flat, half), _changed(flat, busy)])

	var sheet := Image.create(128, 64, false, Image.FORMAT_RGBA8)
	var frame := _blob(rng)
	sheet.blit_rect(frame, Rect2i(0, 0, 64, 64), Vector2i.ZERO)
	sheet.blit_rect(frame, Rect2i(0, 0, 64, 64), Vector2i(64, 0))
	DetailPass.apply_sheet(sheet, Vector2i(64, 64), DetailPass.Kind.WARDEN)
	_check(_only_palette(sheet, false) and sheet.get_region(Rect2i(0, 0, 64, 64)).get_data()
		== sheet.get_region(Rect2i(64, 0, 64, 64)).get_data(), "apply_sheet() treats each frame alike")


# Optional: before/after of a few real sheets, 4x, for eyeballing against the reference page.
func _preview() -> void:
	var dir := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--preview="):
			dir = a.trim_prefix("--preview=")
	if dir.is_empty():
		return
	for job in [["res://assets/towers/sporeling.png", DetailPass.Kind.WARDEN],
			["res://assets/creatures/leaf_bug.png", DetailPass.Kind.NIGHTMARE],
			["res://assets/creatures/weeper.png", DetailPass.Kind.NIGHTMARE]]:
		if not FileAccess.file_exists(job[0]):
			continue
		var src: Image = load(job[0]).get_image()
		src.convert(Image.FORMAT_RGBA8)
		var fw := mini(src.get_width(), 64 * 4)
		var before := src.get_region(Rect2i(0, 0, fw, 64))
		var after := DetailPass.apply_sheet(before.duplicate(), Vector2i(64, 64), job[1])
		var out := Image.create(fw, 128, false, Image.FORMAT_RGBA8)
		out.fill(HeartwoodPalette.color("night"))
		out.blend_rect(before, Rect2i(0, 0, fw, 64), Vector2i.ZERO)
		out.blend_rect(after, Rect2i(0, 0, fw, 64), Vector2i(0, 64))
		out.resize(fw * 4, 512, Image.INTERPOLATE_NEAREST)
		out.save_png(dir.path_join(job[0].get_file()))
	print("previews saved to ", dir)


func _noise(size: int, rng: RandomNumberGenerator) -> Image:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in size:
		for x in size:
			img.set_pixel(x, y, Color8(rng.randi_range(0, 255), rng.randi_range(0, 255), rng.randi_range(0, 255)))
	img.set_pixel(0, 0, Color(1, 1, 1, 0))
	img.set_pixel(1, 0, Color8(77, 230, 51, 128))
	return img


# A round body with an outline, two shading bands and a bright warm light in the middle.
func _blob(rng: RandomNumberGenerator) -> Image:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var body := Color8(90, 70, 130).lerp(Color8(60, 120, 70), rng.randf())
	for y in 64:
		for x in 64:
			var d := Vector2(x - 32, y - 30).length()
			if d < 20:
				img.set_pixel(x, y, body if x + y < 62 else body.darkened(0.3))
			elif d < 21.5:
				img.set_pixel(x, y, Color8(10, 8, 20))
	img.fill_rect(Rect2i(29, 26, 6, 6), Color8(255, 220, 110))
	return img


func _flat_tile(color_name: String) -> Image:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(HeartwoodPalette.color(color_name))
	return img


func _only_palette(img: Image, cold: bool) -> bool:
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a == 0.0:
				continue
			if HeartwoodPalette.index_of(c) < 0 or (cold and not HeartwoodPalette.is_cold(c)):
				push_error("off-palette pixel %s at %d,%d" % [c.to_html(), x, y])
				return false
	return true


func _changed(a: Image, b: Image) -> int:
	var n := 0
	for y in a.get_height():
		for x in a.get_width():
			if a.get_pixel(x, y) != b.get_pixel(x, y):
				n += 1
	return n


func _mean_l(img: Image) -> float:
	var s := 0.0
	var n := 0
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a > 0.5:
				s += HeartwoodPalette.oklab(c).x
				n += 1
	return s / maxi(n, 1)


func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		push_error("FAIL: " + what)
	else:
		print("ok  ", what)
