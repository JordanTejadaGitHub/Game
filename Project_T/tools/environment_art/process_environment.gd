extends SceneTree
# Second half of the environment art pipeline (documentation/environment_assets.md): takes the raw
# sheets the generator page exported and runs each through the shared "detailed 64" DetailPass and
# the Heartwood 32 palette (tools/art/), writing the finished PNGs into assets/environment/.
# Run by export.ps1; by hand:
#   godot --headless --path . --script res://tools/environment_art/process_environment.gd -- --raw=<dir>
# Only PNGs are written (the .import files, and so the UIDs, stay as they are). Run --import after.

const OUT := "res://assets/environment"

# Detail pass kind per sheet.
const KINDS := {
	"grass": DetailPass.Kind.TILE, "path": DetailPass.Kind.TILE, "path_rim": DetailPass.Kind.TILE,
	"island_edge": DetailPass.Kind.TILE,
	"cliff": DetailPass.Kind.TILE, "dew_pool": DetailPass.Kind.TILE, "blight_patch": DetailPass.Kind.TILE,
	"border_wall": DetailPass.Kind.TILE, "rope_bridge": DetailPass.Kind.TILE,
	"withered_tree": DetailPass.Kind.OBSTACLE, "mossy_boulder": DetailPass.Kind.OBSTACLE,
	"tended_stump": DetailPass.Kind.OBSTACLE, "moved_hollow": DetailPass.Kind.OBSTACLE,
	"ground_details": DetailPass.Kind.OBSTACLE, "waystone": DetailPass.Kind.OBSTACLE,
	"tree_round": DetailPass.Kind.OBSTACLE, "tree_pine": DetailPass.Kind.OBSTACLE,
	"tree_flowering": DetailPass.Kind.OBSTACLE, "void_islets": DetailPass.Kind.OBSTACLE,
	"heartwood": DetailPass.Kind.WARDEN,
}
# Palette snap only: soft alpha overlays and the seamless 256 px void (a per-64 pass would seam it).
const SNAP_ONLY := ["edge_mist", "void_sky", "void_stars", "cloud_shadows", "heartwood"]  # heartwood: drawn with its own rim and banded glow (matches the Memory Grove)
# Grain strength (the user's picks, 2026-09-28): no added grain on anything grassy, a light grain on
# the other ground tiles, full detail on props.
const NO_GRAIN := ["grass", "island_edge", "dew_pool", "blight_patch"]
const TILE_GRAIN := 0.3

func _init() -> void:
	var raw := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--raw="):
			raw = arg.trim_prefix("--raw=")
	if raw == "" or not DirAccess.dir_exists_absolute(raw):
		push_error("pass --raw=<folder the generator exported to>")
		quit(1)
		return
	var out := ProjectSettings.globalize_path(OUT)
	var count := 0
	var failures := 0
	for folder in DirAccess.get_directories_at(raw):
		var means := {}
		for file in DirAccess.get_files_at(raw + "/" + folder):
			if not file.ends_with(".png"):
				continue
			var sheet := file.get_basename()
			var img := Image.load_from_file(raw + "/" + folder + "/" + file)
			img.convert(Image.FORMAT_RGBA8)
			if sheet in SNAP_ONLY:
				HeartwoodPalette.snap_image(img)
			elif KINDS.has(sheet):
				_detail(img, sheet)
			else:
				push_error("no detail kind for " + folder + "/" + file)
				failures += 1
				continue
			DirAccess.make_dir_recursive_absolute(out + "/" + folder)
			img.save_png(out + "/" + folder + "/" + file)
			means[sheet] = _mean_l(img)
			count += 1
		if means.has("grass"):
			# The value order (art_direction.md): dark ground < pale obstacles < palest path.
			var ok: bool = means["grass"] < means["mossy_boulder"] and means["mossy_boulder"] < means["path"]
			print("%s value order ground %.3f < rocks %.3f < path %.3f: %s" % [folder, means["grass"],
				means["mossy_boulder"], means["path"], "ok" if ok else "BROKEN"])
			if not ok:
				failures += 1
		if means.has("island_edge") and means.has("grass"):
			# The rim is unbuildable edge, so it must read darker than the buildable ground.
			var rim_ok: bool = means["island_edge"] < means["grass"]
			print("%s rim %.3f < ground %.3f: %s" % [folder, means["island_edge"], means["grass"], "ok" if rim_ok else "BROKEN"])
			if not rim_ok:
				failures += 1
	print("processed %d sheets" % count)
	quit(failures)

func _detail(img: Image, sheet: String) -> void:
	var kind: DetailPass.Kind = KINDS[sheet]
	var texture := 1.0
	if sheet in NO_GRAIN:
		texture = 0.0
	elif kind == DetailPass.Kind.TILE:
		texture = TILE_GRAIN
	if sheet == "grass":
		# One image, not per tile: the pass hashes local pixel positions, so per-tile runs would stamp
		# the same grain on every grass variant.
		DetailPass.apply(img, kind, 0, texture)
		return
	var frame := Vector2i(64, 64)
	if sheet == "heartwood":
		frame = Vector2i(128, 128)
	elif sheet == "withered_tree":
		frame = Vector2i(64, 96)  # Tall trees: the bottom 64 px are the cell
	DetailPass.apply_sheet(img, frame, kind, 0, texture)

# Mean OKLab lightness of the opaque pixels.
func _mean_l(img: Image) -> float:
	var total := 0.0
	var n := 0
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a < 0.5:
				continue
			total += HeartwoodPalette.oklab(c).x
			n += 1
	return total / maxf(n, 1)
