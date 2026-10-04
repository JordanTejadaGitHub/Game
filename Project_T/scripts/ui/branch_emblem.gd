class_name BranchEmblem

# Branch and family emblems (UI Asset's art; the story chat: on Remember's "Not in this dream" silhouettes, as a badge on
# each tree node, and on the family pick cards, Main). Both return null until there's art for that form, so callers keep
# their portraits as the fallback. Two ways the art can arrive, whichever UI Asset delivers:
#   - one file per id: assets/ui/emblems/branch_<id>.png, family_<id>.png
#   - a sheet: assets/ui/emblems/emblems.png with emblems.json {"branch_<id>": [x, y, w, h], "family_<id>": […]}
# load() caches the textures; only the parsed JSON map (plain data, no Resource) is kept here, so nothing holds a Texture
# in a static at exit.

const DIR := "res://assets/ui/emblems/"
const SHEET := DIR + "emblems.png"
const SHEET_MAP := DIR + "emblems.json"

static var _map: Dictionary = {}
static var _map_read := false

# The emblem of branch (or final) `form`, or null.
static func texture(form: TowerData) -> Texture2D:
	return _emblem("branch_" + form.get_id()) if form != null else null

# The emblem of the family whose base is `base`, or null.
static func family(base: TowerData) -> Texture2D:
	return _emblem("family_" + base.get_id()) if base != null else null

static func _emblem(key: String) -> Texture2D:
	var path := DIR + key + ".png"
	if ResourceLoader.exists(path):
		return load(path)
	var rect = _sheet_map().get(key)
	if rect is Array and rect.size() == 4 and ResourceLoader.exists(SHEET):
		var atlas := AtlasTexture.new()
		atlas.atlas = load(SHEET)
		atlas.region = Rect2(float(rect[0]), float(rect[1]), float(rect[2]), float(rect[3]))
		return atlas
	return null

static func _sheet_map() -> Dictionary:
	if not _map_read:
		_map_read = true
		if FileAccess.file_exists(SHEET_MAP):
			var parsed = JSON.parse_string(FileAccess.get_file_as_string(SHEET_MAP))
			_map = parsed if parsed is Dictionary else {}
	return _map
