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
# A crowded nightmare's status row: one pip per status, 7×7 art px (the status colour inside a 1 px Void outline), each
# status its own shape so it reads without colour (UI council round 8 redrew the pairs that merged): Soaked a drop,
# Drowsy a thick half-moon, Asleep a deep violet "z", Poisoned a triangle, Exposed a hollow diamond (a colour ring round
# a Void middle), Charged a zigzag bolt, Rooted a solid square, Caught an X. No stack numbers. The outline and the fill
# take their own alpha (outline 1.0, fill 0.85: one modulate over both smudged the outline). Drawn as rects, on a
# CanvasItem (draw_pip) or straight into a RenderingServer canvas item (draw_pip_rid: Enemy's HUD rows): no texture.
const PIP_SIZE := 7
const PIP_OUTLINE_ALPHA := 1.0
const PIP_FILL_ALPHA := 0.85
const PIPS := {
	&"damp": ["...k...", "..kck..", ".kccck.", "kccccck", "kccccck", ".kccck.", "..kkk.."],
	&"drowsy": ["...kkk.", "..kcck.", ".kccck.", ".kccck.", ".kccck.", "..kcck.", "...kkk."],
	&"asleep": ["kkkkkkk", "kccccck", "kkkkcck", ".kcckk.", "kcckkkk", "kccccck", "kkkkkkk"],
	&"spored": ["...k...", "..kck..", "..kck..", ".kccck.", ".kccck.", "kccccck", "kkkkkkk"],
	&"marked": ["...k...", "..kck..", ".kckck.", "kckkkck", ".kckck.", "..kck..", "...k..."],
	&"static": ["...kkk.", "..kcck.", ".kcck..", "kcccckk", "kkkcck.", "..kck..", "..kk..."],
	&"held": ["kkkkkkk", "kccccck", "kccccck", "kccccck", "kccccck", "kccccck", "kkkkkkk"],
	&"caught": ["kk...kk", "kck.kck", ".kckck.", "..kck..", ".kckck.", "kck.kck", "kk...kk"],
}
const PIP_ALIASES := {&"soaked": &"damp", &"poisoned": &"spored", &"exposed": &"marked", &"charged": &"static",
	&"rooted": &"held"}
# Pips whose colour isn't the status colour: Asleep deep violet (Drowsy keeps the pink), Poisoned a paler, yellower
# green than the health bar's, Caught the Dreamcatchers' thread (no status colour of its own).
const PIP_COLORS := {&"asleep": Palette.BRUISE, &"spored": Palette.NEWLEAF, &"caught": Palette.WRAITHLIGHT}

# Whether `id` (a status id or the player's word: "damp" / "soaked") has a crowd pip.
static func has_pip(id: StringName) -> bool:
	return PIPS.has(PIP_ALIASES.get(id, id))

# The pip's colour: PIP_COLORS, else EnemyStatuses.COLORS (the Warden's status colour).
static func pip_color(id: StringName) -> Color:
	id = PIP_ALIASES.get(id, id)
	return PIP_COLORS.get(id, EnemyStatuses.COLORS.get(id, Palette.MOONLIGHT))

# Draws `id`'s pip centred on `centre` on a CanvasItem, `px` screen px per art px (whole numbers keep it crisp).
# `full`: the status is at its most (Brimming doubles the most): the outline lights Heartlight instead of Void, which
# reads on every shape (section 35, owner 2026-10-24).
static func draw_pip(canvas: CanvasItem, id: StringName, centre: Vector2, px: float = 1.0,
		outline_alpha: float = PIP_OUTLINE_ALPHA, fill_alpha: float = PIP_FILL_ALPHA, full := false) -> void:
	for part in _pip_rects(id, centre, px, outline_alpha, fill_alpha, full):
		canvas.draw_rect(part[0], part[1])

# The same into a RenderingServer canvas item (Enemy's HUD rows draw into an RID, not a CanvasItem).
static func draw_pip_rid(item: RID, id: StringName, centre: Vector2, px: float = 1.0,
		outline_alpha: float = PIP_OUTLINE_ALPHA, fill_alpha: float = PIP_FILL_ALPHA, full := false) -> void:
	for part in _pip_rects(id, centre, px, outline_alpha, fill_alpha, full):
		RenderingServer.canvas_item_add_rect(item, part[0], part[1])

# [[Rect2, Color], …]: one rect per run of one ink (outline first, then fill).
static func _pip_rects(id: StringName, centre: Vector2, px: float, outline_alpha: float, fill_alpha: float, full := false) -> Array:
	id = PIP_ALIASES.get(id, id)
	if not PIPS.has(id):
		return []
	var inks := {"k": Color(Palette.HEARTLIGHT if full else Palette.VOID, outline_alpha), "c": Color(pip_color(id), fill_alpha)}
	var origin := (centre - Vector2(PIP_SIZE, PIP_SIZE) * px / 2.0).round()
	var rows: Array = PIPS[id]
	var out: Array = []
	for y in PIP_SIZE:
		var row: String = rows[y]
		var x := 0
		while x < PIP_SIZE:
			var ink := row[x]
			var run := x + 1
			while run < PIP_SIZE and row[run] == ink:
				run += 1
			if inks.has(ink):
				out.append([Rect2(origin + Vector2(x, y) * px, Vector2(run - x, 1) * px), inks[ink]])
			x = run
	return out

# The pip as a 7×7 image (previews, docs), at the in-game alphas.
static func pip_image(id: StringName) -> Image:
	var image := Image.create_empty(PIP_SIZE, PIP_SIZE, false, Image.FORMAT_RGBA8)
	for part in _pip_rects(id, Vector2(PIP_SIZE, PIP_SIZE) / 2.0, 1.0, PIP_OUTLINE_ALPHA, PIP_FILL_ALPHA):
		image.fill_rect(Rect2i(part[0]), part[1])
	return image

# --- A full status's dot (dream_council_review.md 35, owner 2026-10-24) -------------------------------------------
# A status at its most (Brimming doubles the most) fills its dot: the badge sits on a disc of its own colour inside a
# 1 px Heartlight ring and a Void edge (it was a soft gold glow, easy to miss). Enemy's status row draws it under the
# icon, into its marks canvas item, in place of the glow; `r` is the badge's half size.
const FULL_FILL_ALPHA := 0.6  # The colour under the icon, dark enough that the icon still reads on it
static func draw_full_dot_rid(item: RID, centre: Vector2, r: float, color: Color) -> void:
	var rs := RenderingServer
	rs.canvas_item_add_circle(item, centre, r + 2.0, Color(Palette.VOID, 0.9))
	rs.canvas_item_add_circle(item, centre, r + 1.0, Palette.HEARTLIGHT)
	rs.canvas_item_add_circle(item, centre, r, Palette.VOID)
	rs.canvas_item_add_circle(item, centre, r, Color(color, FULL_FILL_ALPHA))

# The same on a CanvasItem (previews).
static func draw_full_dot(canvas: CanvasItem, centre: Vector2, r: float, color: Color) -> void:
	canvas.draw_circle(centre, r + 2.0, Color(Palette.VOID, 0.9))
	canvas.draw_circle(centre, r + 1.0, Palette.HEARTLIGHT)
	canvas.draw_circle(centre, r, Palette.VOID)
	canvas.draw_circle(centre, r, Color(color, FULL_FILL_ALPHA))
