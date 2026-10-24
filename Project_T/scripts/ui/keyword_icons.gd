class_name KeywordIcons

# The keyword chips' icons (Dream cards' "Makes / Uses" chips, owner 2026-10-16: icon + word, never the icon alone):
# 13 keywords drawn here as 16×16 pixel glyphs in the Heartwood 32 (Palette constants only), Moonlit Thread style, read
# at 16–20 px. The same glyph flashes in the world when the thing happens (Fx: a jump, a Reaction, a linger). Status
# chips use the status icons (IconInfo.icon); Asleep had none, so it is drawn here too.
# Nothing is cached in a static (a static Texture crashes the exit): draw() paints rects straight onto a canvas;
# make_texture() returns a new texture for the caller to keep on its own instance.

const SIZE := 16  # Art pixels per side

# Keyword id -> the word on its chip.
const WORDS := {&"stacks": "Stacks", &"linger": "Linger", &"jump": "Jump", &"repeat": "Repeat", &"reaction": "Reaction",
	&"layered": "Layered", &"slow": "Slow", &"crit": "Crit", &"area": "Area", &"heavy": "Heavy", &"cluster": "Cluster",
	&"rank": "Rank", &"maze": "Maze", &"lingering": "Lingering", &"age": "Age", &"order": "Order"}
# Keywords drawn with another's icon: {lingering} (a status a card keeps from running down; section 33) is Linger's hourglass.
const ALIASES := {&"lingering": &"linger"}
# Status chips: the player's word -> IconInfo's status id (the sheet icon). Asleep is drawn in GRIDS.
const STATUSES := {&"poisoned": &"spored", &"charged": &"static", &"soaked": &"damp", &"drowsy": &"drowsy",
	&"exposed": &"marked", &"rooted": &"held", &"asleep": &"asleep"}

const INKS := {
	"k": Palette.VOID, "s": Palette.DUSK, "S": Palette.SLATE, "v": Palette.SHADE, "V": Palette.BRUISE,
	"l": Palette.WRAITHLIGHT, "g": Palette.STONE, "G": Palette.MIST, "w": Palette.MOONLIGHT, "e": Palette.MOSS,
	"f": Palette.LEAF, "h": Palette.SPRIG, "i": Palette.NEWLEAF, "B": Palette.BARK, "o": Palette.OAK,
	"t": Palette.DEADWOOD, "r": Palette.EMBER, "y": Palette.GOLD, "Y": Palette.GLOW, "W": Palette.HEARTLIGHT,
	"P": Palette.BLOSSOM, "c": Palette.POOL, "C": Palette.DEW, "a": Palette.DEWLIGHT,
}

const GRIDS := {
	&"stacks": [
		"................",
		"....kkkkkkkk....",
		"...kPPWWPPPPk...",
		"...kllllllllk...",
		"...kVVVVVVVVk...",
		"....kkkkkkkkkk..",
		".....kPPWPPPPPk.",
		".....kllllllllk.",
		".....kVVVVVVVVk.",
		".....kkkkkkkkkk.",
		"....kPWPPPPPPk..",
		"....kllllllllk..",
		"....kVVVVVVVVk..",
		".....kkkkkkkk...",
		"................",
		"................",
	],
	&"linger": [
		"................",
		"..kkkkkkkkkkkk..",
		"..kYyyyyyyyyrk..",
		"..kkkkkkkkkkkk..",
		"...kcccccccck...",
		"...kaaaaaaaak...",
		"....kCaaaaCk....",
		".....kCaaCk.....",
		"......kaak......",
		".....kcaack.....",
		"....kccaacck....",
		"...kcCaaaaCck...",
		"...kCaaaaaaCk...",
		"..kkkkkkkkkkkk..",
		"..kYyyyyyyyyrk..",
		"..kkkkkkkkkkkk..",
	],
	&"jump": [
		"................",
		"................",
		"......kkkk......",
		"....kkYYWYkk....",
		"...kYYkkkkYYk...",
		"..kYk......kYk..",
		"..kYk.....kkYkk.",
		"..kYk.....kYYYk.",
		"..kk.......kYk..",
		"............k...",
		".kkk.......kkk..",
		"kVVVk.....kVVVk.",
		"kVPVk.....kVPVk.",
		"kvVvk.....kvVvk.",
		".kkk.......kkk..",
		"................",
	],
	&"repeat": [
		"................",
		"..........k.....",
		"..kkkkkkkkYk....",
		".kYYYYYYYYYYk...",
		".kyyyyyyyyyyyk..",
		".kyykkkkkkkyk...",
		".kyyk.....kk....",
		".kkkk...........",
		"...........kkkk.",
		"....kk.....kyyk.",
		"...kykkkkkkkyyk.",
		"..kyyyyyyyyyyyk.",
		"...kYYYYYYYYYYk.",
		"....kYkkkkkkkk..",
		".....k..........",
		"................",
	],
	&"reaction": [
		".......kk.......",
		"......kYYk......",
		"....kkkWWkkk....",
		"...kYYWWWWYYk...",
		"....kkkWWkkk....",
		"......kYYk......",
		".......kk.......",
		"................",
		"...kkk....kkk...",
		"..khhfk..kaaCk..",
		".khhfffkkaaCCCk.",
		".khffffkkaCCCCk.",
		".kfffefkkCCCcCk.",
		"..kfeek..kCcck..",
		"...kkk....kkk...",
		"................",
	],
	&"layered": [
		".......kk.......",
		"......kYYk......",
		"..kk..kyyk..kk..",
		".khhk..kk..kaak.",
		".kffk......kCCk.",
		"..kk........kk..",
		"....kkkkkkkk....",
		"...kVVVVVVVVk...",
		"...kVPVVVVPVk...",
		"...kVPVVVVPVk...",
		"...kvVVVVVVvk...",
		"...kvvVVVVvvk...",
		"...kvvvvvvvvk...",
		"...kvkvvvvkvk...",
		"...kk.kkkk.kk...",
		"................",
	],
	&"slow": [
		"................",
		"................",
		"........kkkk....",
		".k.k..kkttttkk..",
		".k.k..kttooottk.",
		"..kk.kttoBBBotk.",
		".kGGkktoBtttBok.",
		"kGGGkktoBtBtBok.",
		"kGGGkktoBtBBBok.",
		"kGGGGkttoBtoook.",
		"kgGGGGktooooBkGk",
		"kggGGGGkkkkkkGGk",
		".kggggggggggggk.",
		"..kkkkkkkkkkkkk.",
		"................",
		"................",
	],
	&"crit": [
		"................",
		".......k........",
		"..k...kYk...k...",
		"..kYk.kYk..kYk..",
		"...kYkYYYkkYk...",
		"....kYYWWYYk....",
		".kkkYYWWWWYkkkk.",
		"kYYYYWWWWWWYYYYk",
		".kkkYYWWWWYYkkk.",
		"....kYYWWYYk....",
		"...kYkkYYkkYk...",
		"..kYk.kYYk.kYk..",
		"..kk...kYk..kk..",
		".......kYk......",
		"........k.......",
		"................",
	],
	# A Warden's own hit (user 2026-10-22: the "Hits" chip had no icon): a pale shot with speed lines, sparks where it lands
	&"hit": [
		"................",
		"................",
		"................",
		".............k..",
		"......kkkk..kYk.",
		".....kwwGGk..kYk",
		"GGG.kwwGGGSk....",
		".....kwGGGSk.kk.",
		"GGGG.kGGGSSk.kYk",
		".....kGGSSsk.kk.",
		"GGG..kSSSsk.....",
		"......kkkk......",
		".............kYk",
		"..............k.",
		"................",
		"................",
	],
	&"area": [
		".....kkkkkk.....",
		"...kkYYYYYYkk...",
		"..kYYkkkkkkYYk..",
		".kYk........kYk.",
		".kYk...kk...kYk.",
		"kYk...kVVk...kYk",
		"kYk...kVPk...kYk",
		"kYk.kk.kk.kk.kYk",
		"kYk.kVk..kVk.kYk",
		"kYk.kPk..kPk.kYk",
		".kYk.k....k.kYk.",
		".kYk........kYk.",
		"..kYYkkkkkkYYk..",
		"...kkYYYYYYkk...",
		".....kkkkkk.....",
		"................",
	],
	&"heavy": [
		"................",
		".....kkkkkkk....",
		"....kGwwGGGSk...",
		"...kGGGGGSSSSk..",
		"...kGGGGSSSSsk..",
		"...kSSSSSSSssk..",
		"....kSSSsssssk..",
		".....kkkkkskk...",
		"........kBok....",
		".......kBok.....",
		"......kBok......",
		".....kBok.......",
		"....kBok........",
		"...kBok.........",
		"...kkk..........",
		"................",
	],
	&"cluster": [
		"................",
		"......kkkk......",
		".....kiihhk.....",
		"....kihhhffk....",
		"....khhfffek....",
		".....kffeek.....",
		"......kkkk......",
		"..kkkk....kkkk..",
		".kiihhk..kiihhk.",
		"kihhhffkkihhhffk",
		"khhfffekkhhfffek",
		".kffeek..kffeek.",
		"..kkkk....kkkk..",
		"................",
		"................",
		"................",
	],
	&"rank": [
		"................",
		".......kk.......",
		"......kYYk......",
		".....kYWWYk.....",
		"....kYYkkYYk....",
		"...kYYk..kYYk...",
		"..kyyk....kyyk..",
		"..kkk..kk..kkk..",
		"......kYYk......",
		".....kYWWYk.....",
		"....kYYkkYYk....",
		"...kYYk..kYYk...",
		"..kyyk....kyyk..",
		"..kkk......kkk..",
		"................",
		"................",
	],
	&"maze": [
		"kkkkkkkkkkkkkkkk",
		"kBttttttttttttBk",
		"kBtkkkkkkkkkktBk",
		"kBtkBBBBBBBBktBk",
		"kBtkBttttttBktBk",
		"kBtkBtkkkktBktBk",
		"kBtkBtkYYktBktBk",
		"kBtkBtkYYktBktBk",
		"kBtkBtkkttBBktBk",
		"kBtkBttttBBBktBk",
		"kBtkBBBBBBBBktBk",
		"kBtkkkkkkkkkktBk",
		"kBttttttttttttBk",
		"kBBBBBBBBBBBBtBk",
		"kkkkkkkkkkkkktkk",
		"................",
	],
	&"asleep": [
		"................",
		"..........kkkkk.",
		"....kkkk..kWWWk.",
		"...kGwwk...kkWk.",
		"..kGwk....kWkk..",
		".kGwk.....kWWWk.",
		".kGwk......kkk..",
		"kGwk............",
		"kGwk............",
		"kGwk........k...",
		"kGGwk......kGk..",
		".kGGwkkkkkkGGk..",
		".kgGGGwwwwGGk...",
		"..kkgGGGGgkk....",
		"....kkkkkk......",
		"................",
	],
	# Age (section 33 final pass: Toadstool Throne's "planted 10+ drifts ago"): a cut stump: Deadwood rim, Bark and Oak
	# rings, a crack from the dark pith to the rim (art council 2026-10-24: not a coin or a target, apart from Area).
	&"age": [
		"......kkkk......",
		"....kkkttkkk....",
		"..kktttootttkk..",
		"..kttoBBBBotkk..",
		".kttBBooooBkktk.",
		".ktoBoBBBBkBotk.",
		"kktBoBBookBoBtkk",
		"ktoBoBokkoBoBotk",
		"ktoBoBokkoBoBotk",
		"kktBoBBooBBoBtkk",
		".ktoBoBBBBoBotk.",
		".kttBBooooBBttk.",
		"..kttoBBBBottk..",
		"..kktttootttkk..",
		"....kkkttkkk....",
		"......kkkk......",
	],
	# Order (Host Trees / Shared Caps: who is picked first): three 3 px steps rising left to right on one Void base;
	# the first Glow with a notch (shape, not colour alone), the others Mist (art council 2026-10-24).
	&"order": [
		"................",
		"................",
		"..........kkkkk.",
		"..........kGGGk.",
		"..........kGGGk.",
		"......kkkkkGGGk.",
		"......kGGGkGGGk.",
		"......kGGGkGGGk.",
		"..kkkkkGGGkGGGk.",
		"..kYkYkGGGkGGGk.",
		"..kYYYkGGGkGGGk.",
		"..kYYYkGGGkGGGk.",
		"..kYYYkGGGkGGGk.",
		"..kkkkkkkkkkkkk.",
		"................",
		"................",
	],
}

# Whether `id` has a chip icon (a keyword, a status word or a status id).
static func has(id: StringName) -> bool:
	return GRIDS.has(ALIASES.get(id, id)) or IconInfo.icon(_status_id(id)) != null

# The chip's word: the keyword's, or the status's own name ("Poisoned").
static func word(id: StringName) -> String:
	if WORDS.has(id):
		return WORDS[id]
	return IconInfo.status_name(_status_id(id))

# Draws the icon for `id` centred on `centre`, `size` px square (16 or 20 on chips; whole-pixel edges, so 20 px gives
# a few 2-px rows, still crisp). `alpha` for world flashes that fade.
static func draw(canvas: CanvasItem, id: StringName, centre: Vector2, size: float = 16.0, alpha: float = 1.0) -> void:
	var origin := (centre - Vector2(size, size) / 2.0).round()
	id = ALIASES.get(id, id)
	if not GRIDS.has(id):
		# The texture is kept on the canvas: one only held by this call was freed before the frame drew (white squares on
		# every status chip; the art council caught it 2026-10-24). On the canvas, not in a static (exit crash).
		var key := StringName("_keyword_icon_" + String(id))
		var sheet: Texture2D = canvas.get_meta(key) if canvas.has_meta(key) else IconInfo.icon(_status_id(id))
		if sheet != null:
			canvas.set_meta(key, sheet)
			canvas.draw_texture_rect(sheet, Rect2(origin, Vector2(size, size)), false, Color(1, 1, 1, alpha))  # multiplier
		return
	var step := size / SIZE
	var rows: Array = GRIDS[id]
	for y in SIZE:
		var row: String = rows[y]
		var top := origin.y + roundf(y * step)
		var bottom := origin.y + roundf((y + 1) * step)
		var x := 0
		while x < SIZE:
			var ink := row[x]
			var run := x + 1
			while run < SIZE and row[run] == ink:
				run += 1  # One rect per run of one colour
			if INKS.has(ink):
				var left := origin.x + roundf(x * step)
				var right := origin.x + roundf(run * step)
				canvas.draw_rect(Rect2(left, top, right - left, bottom - top), Color(INKS[ink], alpha))
			x = run

# The 16×16 image of a drawn icon (null for a sheet status: use IconInfo.icon).
static func make_image(id: StringName) -> Image:
	id = ALIASES.get(id, id)
	if not GRIDS.has(id):
		return null
	var image := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var rows: Array = GRIDS[id]
	for y in SIZE:
		for x in SIZE:
			var ink: String = (rows[y] as String)[x]
			if INKS.has(ink):
				image.set_pixel(x, y, INKS[ink])
	return image

# A texture for `id` (a new one each call: keep it on the caller's instance, never in a static). Draw it with
# TEXTURE_FILTER_NEAREST.
static func make_texture(id: StringName) -> Texture2D:
	var image := make_image(id)
	if image != null:
		return ImageTexture.create_from_image(image)
	return IconInfo.icon(_status_id(id))

static func _status_id(id: StringName) -> StringName:
	return STATUSES.get(id, id)

# --- Crowd pips (enemy_design.md "Status icons in crowds", owner 2026-10-24) ------------------------------------
# A crowded nightmare's status row: one pip per status, 7×7 art px (5 px of the status colour inside a 1 px Void
# outline), each status its own shape so it reads without colour: Soaked a drop, Drowsy a crescent, Asleep a closed
# bar, Poisoned a triangle, Exposed a diamond, Charged a plus, Rooted a square, Caught a ring. Enemy Code draws them
# (draw_pip) at 70% opacity; no stack numbers. Drawn as rects: no texture to keep alive.
const PIP_SIZE := 7
const PIPS := {
	&"damp": ["...k...", "..kck..", ".kccck.", "kccccck", "kccccck", ".kccck.", "..kkk.."],
	&"drowsy": ["..kkkk.", ".kcck..", "kcck...", "kcck...", "kcck...", ".kcck..", "..kkkk."],
	&"asleep": [".......", ".......", "kkkkkkk", "kccccck", "kccccck", "kkkkkkk", "......."],
	&"spored": ["...k...", "..kck..", "..kck..", ".kccck.", ".kccck.", "kccccck", "kkkkkkk"],
	&"marked": ["...k...", "..kck..", ".kccck.", "kccccck", ".kccck.", "..kck..", "...k..."],
	&"static": ["..kkk..", "..kck..", "kkkckkk", "kccccck", "kkkckkk", "..kck..", "..kkk.."],
	&"held": ["kkkkkkk", "kccccck", "kccccck", "kccccck", "kccccck", "kccccck", "kkkkkkk"],
	&"caught": [".kkkkk.", "kccccck", "kckkkck", "kck.kck", "kckkkck", "kccccck", ".kkkkk."],
}
const PIP_ALIASES := {&"soaked": &"damp", &"poisoned": &"spored", &"exposed": &"marked", &"charged": &"static",
	&"rooted": &"held"}
const PIP_CAUGHT_COLOR := Palette.WRAITHLIGHT  # Caught has no status colour of its own (the Dreamcatchers' thread)

# Whether `id` (a status id or the player's word: "damp" / "soaked") has a crowd pip.
static func has_pip(id: StringName) -> bool:
	return PIPS.has(PIP_ALIASES.get(id, id))

# The pip's colour: EnemyStatuses.COLORS (the Warden's status colour), Caught's own.
static func pip_color(id: StringName) -> Color:
	id = PIP_ALIASES.get(id, id)
	return PIP_CAUGHT_COLOR if id == &"caught" else EnemyStatuses.COLORS.get(id, Palette.MOONLIGHT)

# Draws `id`'s pip centred on `centre`, `px` screen px per art px (whole numbers keep it crisp), at `alpha`.
static func draw_pip(canvas: CanvasItem, id: StringName, centre: Vector2, px: float = 1.0, alpha: float = 1.0) -> void:
	id = PIP_ALIASES.get(id, id)
	if not PIPS.has(id):
		return
	var inks := {"k": Color(Palette.VOID, alpha), "c": Color(pip_color(id), alpha)}
	var origin := (centre - Vector2(PIP_SIZE, PIP_SIZE) * px / 2.0).round()
	var rows: Array = PIPS[id]
	for y in PIP_SIZE:
		var row: String = rows[y]
		var x := 0
		while x < PIP_SIZE:
			var ink := row[x]
			var run := x + 1
			while run < PIP_SIZE and row[run] == ink:
				run += 1  # One rect per run of one ink
			if inks.has(ink):
				canvas.draw_rect(Rect2(origin + Vector2(x, y) * px, Vector2(run - x, 1) * px), inks[ink])
			x = run

# The pip as a 7×7 image (previews, docs).
static func pip_image(id: StringName) -> Image:
	id = PIP_ALIASES.get(id, id)
	var image := Image.create_empty(PIP_SIZE, PIP_SIZE, false, Image.FORMAT_RGBA8)
	if not PIPS.has(id):
		return image
	for y in PIP_SIZE:
		for x in PIP_SIZE:
			var ink := String(PIPS[id][y])[x]
			if ink == "k":
				image.set_pixel(x, y, Palette.VOID)
			elif ink == "c":
				image.set_pixel(x, y, pip_color(id))
	return image
