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
	&"rank": "Rank", &"maze": "Maze"}
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
}

# Whether `id` has a chip icon (a keyword, a status word or a status id).
static func has(id: StringName) -> bool:
	return GRIDS.has(id) or IconInfo.icon(_status_id(id)) != null

# The chip's word: the keyword's, or the status's own name ("Poisoned").
static func word(id: StringName) -> String:
	if WORDS.has(id):
		return WORDS[id]
	return IconInfo.status_name(_status_id(id))

# Draws the icon for `id` centred on `centre`, `size` px square (16 or 20 on chips; whole-pixel edges, so 20 px gives
# a few 2-px rows, still crisp). `alpha` for world flashes that fade.
static func draw(canvas: CanvasItem, id: StringName, centre: Vector2, size: float = 16.0, alpha: float = 1.0) -> void:
	var origin := (centre - Vector2(size, size) / 2.0).round()
	if not GRIDS.has(id):
		var sheet := IconInfo.icon(_status_id(id))
		if sheet != null:
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
