extends Control
class_name NightmareIcons

# A nightmare's Kind, immunities and traits as icons (screens_ui.md "Nightmare info", added 2026-09-28; Nightmare
# Kinds, enemy_design.md ed6f573b, replaced the damage-type icons): one small icon control, two kinds:
# - a status = IconInfo's sheet icon, crossed out (immune) or with "½" (wears off faster);
# - a trait (Flying, Hidden, Dread shell, Passes through walls, …): a drawn glyph in a dark disc.
# Every icon explains itself on hover and on tap (TapTip). make_rows(data) builds the Kind badge (kind_row: its glyph
# and EnemyData.get_kind_line(), the Kind's name linked to its glossary entry; Plain shows none) and the "Immune /
# Wears off fast / Traits" rows for the nightmare info, the first-appearance card, the boss dossier, the Codex and the
# Coming strip.

enum Kind { FAMILY, STATUS, TRAIT }  # (FAMILY: unused since damage types went; kept so the values stay put)

# The Kind badge's glyph: a trait glyph that shows what the Kind does (draw_glyph).
const KIND_GLYPHS := {EnemyData.Kind.ARMOURED: &"dread_shell", EnemyData.Kind.FLYING: &"flying",
	EnemyData.Kind.HIDDEN: &"hidden", EnemyData.Kind.SWARM: &"swarm", EnemyData.Kind.FAST: &"sprints"}
# The IconInfo.TERMS id of each Kind's glossary entry (the badge's link; Warden tags link the same).
const KIND_TERMS := {EnemyData.Kind.ARMOURED: &"kind_armoured", EnemyData.Kind.FLYING: &"kind_flying",
	EnemyData.Kind.HIDDEN: &"kind_hidden", EnemyData.Kind.SWARM: &"kind_swarm", EnemyData.Kind.FAST: &"kind_fast",
	EnemyData.Kind.PLAIN: &"kind_plain"}

# Damage line -> its family's base Warden (the face shown). "support" is Acorn's line in the docs.
const LINE_WARDENS := {"spore": "sporeling", "stone": "pebbling", "water": "dewdrop", "light": "firefly_jar",
	"root": "rootling", "song": "bellflower", "wing": "nestling", "wind": "whirligig", "acorn": "acorn",
	"support": "acorn"}
const TOWER_DIR := "res://resource/tower/"
# How a line reads in a sentence ("stone Wardens deal half damage to it").
const LINE_WORDS := {"acorn": "Acorn", "support": "Acorn"}

const IMMUNE_COLOR := UiStyle.POOR
const DISC_COLOR := Color(Palette.DREAD, 0.9)
const GLYPH_COLOR := UiStyle.MOONLIGHT

# Traits: id -> [name, what it means]. The first ones are EnemyData.get_defences()' trait ids (Enemy
# Code); the rest are read from other EnemyData fields by traits_of(). Boss ability icons
# (EnemyData.abilities "icon") use the same glyphs (draw_glyph).
const TRAITS := {
	&"flying": ["Flying", "Flies over the maze: walls don't change its path."],
	&"through_walls": ["Passes through walls", "Glides straight through the maze: walls don't change its path."],
	&"hidden": ["Hidden", "Can't be seen or targeted until something reveals it, or it comes close."],
	&"dread_shell": ["Dread shell", "A shell absorbs part of every hit until it cracks for good."],
	&"always_damp": ["Always {damp}", "It's always {damp}: lightning loves it."],
	&"ignores_slows": ["Never slowed", "{damp}, {drowsy} and slowing auras don't slow it."],
	&"sprints": ["Sprints", "Speeds up down long straight corridors, until the next turn."],
	&"burrows": ["Burrows", "Sinks under a Warden or wall beside it and surfaces on the other side."],
	&"wanders": ["Wanders", "Strays into dead-end pockets and back out, taking its time."],
	&"splits": ["Splits", "Bursts into smaller nightmares when dispelled."],
	&"trample": ["Tramples walls", "Knocks down Thornwalls next to it, for good."],
	&"leap": ["Leaps", "Sinks and rises farther along the path, skipping cells."],
	&"mender": ["Mends", "Heals the nightmares near it."],
	&"waker": ["Wakes others", "Shakes {drowsy} off the nightmares near it."],
	&"revealer": ["Reveals", "Uncovers {hidden} nightmares near it, for your Wardens too."],
	&"ash": ["Ash trail", "Its burning trail clears {spored} from nightmares walking on it."],
	&"thief": ["Steals Dew", "Takes Dew as well as leaves if it reaches the Heartwood."],
	&"followers": ["Brings followers", "Others walk behind it in single file, and get lost without it."],
	&"bulky": ["Bulky", "Area hits deal less to it."],
}

var kind := Kind.TRAIT
var id := ""  # Line, status id or trait id
var mode := &""  # STATUS: &"immune" / &"short"
var tip := ""

# --- Builders --------------------------------------------------------------------------------------

# The Kind's glyph alone (the Coming strip), its tip the Kind's line; null for Plain.
static func kind_icon(data: EnemyData, side: float = 28.0) -> NightmareIcons:
	if data == null or not KIND_GLYPHS.has(data.kind):
		return null
	var icon := NightmareIcons.new()
	icon.kind = Kind.TRAIT
	icon.id = String(KIND_GLYPHS[data.kind])
	icon.tip = data.get_kind_line()
	return icon._sized(side)

# The Kind badge: its glyph, then "Armoured: heavy hits and armour breakers crack its shell.", the Kind's name
# as a link to its glossary entry (hover / tap). null for Plain (no badge).
static func kind_row(data: EnemyData, side: float = 28.0, font: int = 15) -> HBoxContainer:
	var icon := kind_icon(data, side)
	if icon == null:
		return null
	var row := HBoxContainer.new()
	row.name = "KindBadge"
	row.add_theme_constant_override("separation", 6)
	row.add_child(icon)
	var name := data.get_kind_name()
	var rest := data.get_kind_line().trim_prefix(name + ":").strip_edges()
	var text := StatusLinks.make_label("", font, UiStyle.INK)
	text.name = "KindLine"
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	text.text = "%s: %s" % [StatusLinks._link(StatusLinks.TERM_PREFIX + String(KIND_TERMS[data.kind]), name), rest]
	row.add_child(text)
	return row

# A status crossed out (`how` = &"immune") or with "½" (&"short": `multiplier` of its duration).
# `condition` (get_defences' "conditional"): immune only then, e.g. "while sprinting".
static func status(status_id: StringName, how: StringName, multiplier: float = 1.0, side: float = 28.0,
		condition: String = "") -> NightmareIcons:
	var icon := NightmareIcons.new()
	icon.kind = Kind.STATUS
	icon.id = String(status_id)
	icon.mode = how
	var name := IconInfo.status_name(status_id)
	if how == &"immune" and condition != "":
		icon.tip = "Immune to %s %s: the status does nothing to it then." % [name, condition]
	elif how == &"immune":
		icon.tip = "Immune to %s: the status does nothing to it." % name
	elif is_equal_approx(multiplier, 0.5):
		icon.tip = "%s wears off fast: it lasts half as long on it." % name
	else:
		icon.tip = "%s wears off fast: it lasts %d%% as long on it." % [name, roundi(multiplier * 100.0)]
	return icon._sized(side)

static func trait_icon(trait_id: StringName, side: float = 28.0) -> NightmareIcons:
	var icon := NightmareIcons.new()
	icon.kind = Kind.TRAIT
	icon.id = String(trait_id)
	var entry: Array = TRAITS.get(trait_id, [String(trait_id).capitalize(), ""])
	icon.tip = IconInfo.format("%s: %s" % entry)
	return icon._sized(side)

func _sized(side: float) -> NightmareIcons:
	custom_minimum_size = Vector2(side, side)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	TapTip.attach(self, tip)
	return self

# --- Data ------------------------------------------------------------------------------------------

# The demo (demo_scope.md) has only the spore, light and water families: others' resist / weak
# icons would name Wardens the player can't have (CodexData.demo_limited: not in dev runs).
static func in_build(line: String) -> bool:
	if not CodexData.demo_limited():
		return true
	var data := base_warden(line)
	return data != null and CodexData.DEMO_FAMILIES.has(data.get_id())

static func base_warden(line: String) -> TowerData:
	var path := TOWER_DIR + String(LINE_WARDENS.get(line, "")) + ".tres"
	return load(path) as TowerData if LINE_WARDENS.has(line) and ResourceLoader.exists(path) else null

static func family_name(line: String) -> String:
	var data := base_warden(line)
	return data.display_name if data != null and data.get("display_name") else line.capitalize()

static func line_word(line: String) -> String:
	return LINE_WORDS.get(line, line)

# Enemy Code's summary of how `data` takes damage and statuses (EnemyData.get_defences()).
static func defences(data: EnemyData) -> Dictionary:
	return data.get_defences()

# The trait ids that apply to `data`: get_defences()' traits, then what the other fields add.
static func traits_of(data: EnemyData) -> Array[StringName]:
	var out: Array[StringName] = []
	for trait_id in defences(data).get("traits", []):
		out.append(StringName(trait_id))
	var extra: Array[StringName] = []
	match data.trait_kind:
		EnemyData.Trait.TRAMPLE: extra.append(&"trample")
		EnemyData.Trait.LEAP: extra.append(&"leap")
	if data.mend_radius > 0.0: extra.append(&"mender")
	if data.wake_radius > 0.0: extra.append(&"waker")
	if data.reveal_radius > 0.0: extra.append(&"revealer")
	if data.ash_trail_time > 0.0: extra.append(&"ash")
	if data.steals_dew > 0: extra.append(&"thief")
	if data.followers != null and data.follower_count > 0: extra.append(&"followers")
	if data.area_multiplier < 1.0: extra.append(&"bulky")
	for trait_id in extra:
		if not out.has(trait_id):
			out.append(trait_id)
	return out

# {status id: duration share} for statuses it shrugs off (share below 1; every boss: Rooted ½).
static func shrugs_off(data: EnemyData) -> Dictionary:
	var out := {}
	var d := defences(data)
	var shorter: Dictionary = d.get("shorter", {})
	for status_id in shorter:
		var m := float(shorter[status_id])
		if m < 1.0 and not d.get("immune", []).has(StringName(status_id)):
			out[StringName(status_id)] = m
	return out

# The Kind badge (none for Plain), then the "Immune / Wears off fast" rows for `data` (each hidden when empty) plus a
# traits row. `side` = icon size; `compact` = the Kind's glyph only, no captions (the Coming strip). Returns an empty
# box when there's nothing to show.
static func make_rows(data: EnemyData, side: float = 28.0, compact: bool = false, with_traits: bool = true) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	var d := defences(data)
	if compact:
		var glyph := kind_icon(data, side)
		if glyph != null:
			var row := HFlowContainer.new()
			row.alignment = FlowContainer.ALIGNMENT_CENTER
			row.add_child(glyph)
			box.add_child(row)
		return box
	var font := int(maxf(side * 0.5, 13.0))
	var badge := kind_row(data, side, font)
	if badge != null:
		box.add_child(badge)
	var guarded: Array[Control] = []
	for status_id in d.get("immune", []):
		guarded.append(status(StringName(status_id), &"immune", 0.0, side))
	var conditional: Dictionary = d.get("conditional", {})  # {status id: "while sprinting"}
	for status_id in conditional:
		guarded.append(status(StringName(status_id), &"immune", 0.0, side, String(conditional[status_id])))
		var when := Label.new()
		when.text = String(conditional[status_id])
		when.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		when.custom_minimum_size = Vector2(0, side)
		when.add_theme_font_size_override("font_size", maxi(int(side * 0.45), 12))
		when.add_theme_color_override("font_color", IMMUNE_COLOR.lightened(0.4))
		guarded.append(when)
	var short := shrugs_off(data)
	var fading: Array[Control] = []  # Its own row (wording review 2026-10-13: "Immune / shrugs off" was two things)
	for status_id in short:
		fading.append(status(status_id, &"short", short[status_id], side))
	if not guarded.is_empty():
		box.add_child(_row("Immune to", IMMUNE_COLOR.lightened(0.3), guarded, font))
	if not fading.is_empty():
		box.add_child(_row("Wears off fast", IMMUNE_COLOR.lightened(0.3), fading, font))
	if with_traits:
		var icons: Array[Control] = []
		for trait_id in traits_of(data):
			icons.append(trait_icon(trait_id, side))
		if not icons.is_empty():
			box.add_child(_row("Traits", GLYPH_COLOR, icons, font))
	return box

static func _row(caption: String, colour: Color, icons: Array[Control], font: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	var label := Label.new()
	label.text = caption
	label.custom_minimum_size = Vector2(font * 6.2, 0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font)
	label.add_theme_color_override("font_color", colour)
	row.add_child(label)
	var flow := HFlowContainer.new()
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flow.add_theme_constant_override("h_separation", 3)
	for icon in icons:
		flow.add_child(icon)
	row.add_child(flow)
	return row

static func _num(value: float) -> String:
	return str(value).trim_suffix(".0")

# --- Drawing ---------------------------------------------------------------------------------------

func _draw() -> void:
	match kind:
		Kind.STATUS: _draw_status()
		_: _draw_trait()

func _draw_status() -> void:
	var c := size / 2.0
	var r := minf(size.x, size.y) / 2.0
	draw_circle(c, r - 1.0, DISC_COLOR)
	var art := IconInfo.icon(StringName(id))
	if art != null:
		var scale := maxf(floorf((r * 2.0 - 4.0) / 16.0), 1.0)
		var side := Vector2(16, 16) * scale
		draw_texture_rect(art, Rect2(c - side / 2.0, side), false,
			UiStyle.INK_DIM if mode == &"immune" else UiStyle.INK)
	else:
		draw_circle(c, r * 0.4, EnemyStatuses.COLORS.get(StringName(id), UiStyle.INK))
	if mode == &"immune":  # Crossed out
		var d := Vector2(r * 0.7, r * 0.7)
		draw_line(c - d, c + d, Palette.DREAD, 5.0, true)
		draw_line(c - d, c + d, IMMUNE_COLOR, 3.0, true)
		draw_arc(c, r - 1.5, 0.0, TAU, 28, IMMUNE_COLOR, 2.0, true)
	else:  # "½"
		var font := ThemeDB.fallback_font
		var fs := int(maxf(r * 0.8, 10.0))
		var at := c + Vector2(r * 0.15, r * 0.95)
		draw_string_outline(font, at, "½", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, Palette.DREAD)
		draw_string(font, at, "½", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UiStyle.GOLD)
		draw_arc(c, r - 1.5, 0.0, TAU, 28, Color(UiStyle.GOLD, 0.8), 1.5, true)

func _draw_trait() -> void:
	var c := size / 2.0
	var r := minf(size.x, size.y) / 2.0
	draw_circle(c, r - 1.0, DISC_COLOR)
	draw_arc(c, r - 1.5, 0.0, TAU, 28, Color(GLYPH_COLOR, 0.45), 1.5, true)
	draw_glyph(self, StringName(id), c, r * 0.55, GLYPH_COLOR)

# One small drawn glyph per trait, `s` = half its size. Also used by the boss dossier's abilities.
static func draw_glyph(canvas: CanvasItem, glyph: StringName, c: Vector2, s: float, colour: Color) -> void:
	var w := maxf(s * 0.22, 1.5)
	var sheet := IconInfo.icon(glyph)  # The pixel-art icon when the sheet has one; drawn otherwise
	if sheet != null:
		var scale := maxf(floorf(s * 2.0 / 16.0), 1.0)
		var side := Vector2(16, 16) * scale
		canvas.draw_texture_rect(sheet, Rect2(c - side / 2.0, side), false)
		return
	match glyph:
		&"hidden":
			var art := IconInfo.icon(&"hidden")
			if art != null:
				var side := Vector2(s, s) * 2.0
				canvas.draw_texture_rect(art, Rect2(c - side / 2.0, side), false)
			else:
				canvas.draw_arc(c, s * 0.7, PI * 1.1, PI * 1.9, 12, colour, w, true)
		&"flying", &"eclipse":  # Two wings
			canvas.draw_arc(c + Vector2(-s * 0.5, s * 0.3), s * 0.6, PI * 1.05, PI * 1.9, 10, colour, w, true)
			canvas.draw_arc(c + Vector2(s * 0.5, s * 0.3), s * 0.6, PI * 1.1, PI * 1.95, 10, colour, w, true)
		&"dread_shell":  # Hexagon
			var hexagon := PackedVector2Array()
			for i in 7:
				hexagon.append(c + Vector2.from_angle(TAU * i / 6.0) * s)
			canvas.draw_polyline(hexagon, colour, w, true)
			canvas.draw_line(c + Vector2(-s * 0.3, -s * 0.5), c + Vector2(s * 0.1, s * 0.4), colour, w * 0.7)
		&"burrows", &"through_walls":  # A wall with an arrow under it
			canvas.draw_rect(Rect2(c + Vector2(-s * 0.25, -s), Vector2(s * 0.5, s * 1.1)), colour, false, w)
			canvas.draw_arc(c + Vector2(0, s * 0.2), s * 0.8, 0.0, PI, 12, colour, w, true)
		&"sprints", &"charge":
			canvas.draw_arc(c, s * 0.75, 0.0, TAU * 0.8, 16, colour, w, true)
			canvas.draw_line(c + Vector2(s * 0.3, 0), c + Vector2(s, 0), colour, w)
		&"trample":  # Antlers
			canvas.draw_line(c + Vector2(0, s), c + Vector2(0, -s * 0.2), colour, w)
			canvas.draw_line(c + Vector2(0, -s * 0.2), c + Vector2(-s, -s), colour, w)
			canvas.draw_line(c + Vector2(0, -s * 0.2), c + Vector2(s, -s), colour, w)
		&"leap", &"sink":
			canvas.draw_arc(c + Vector2(0, s * 0.5), s, PI * 1.1, PI * 1.9, 12, colour, w, true)
			canvas.draw_circle(c + Vector2(s * 0.8, s * 0.2), w * 1.2, colour)
		&"wanders", &"grief":
			canvas.draw_arc(c, s * 0.8, 0.0, TAU * 0.75, 14, colour, w, true)
			canvas.draw_arc(c, s * 0.35, PI, TAU * 1.2, 10, colour, w, true)
		&"mender":
			canvas.draw_line(c + Vector2(0, -s), c + Vector2(0, s), colour, w * 1.4)
			canvas.draw_line(c + Vector2(-s, 0), c + Vector2(s, 0), colour, w * 1.4)
		&"waker", &"revealer":  # An eye
			canvas.draw_arc(c + Vector2(0, s * 0.6), s * 1.1, PI * 1.2, PI * 1.8, 10, colour, w, true)
			canvas.draw_arc(c + Vector2(0, -s * 0.6), s * 1.1, PI * 0.2, PI * 0.8, 10, colour, w, true)
			canvas.draw_circle(c, s * 0.3, colour)
		&"ash":  # A flame
			canvas.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s), c + Vector2(s * 0.6, s * 0.3),
				c + Vector2(0, s), c + Vector2(-s * 0.6, s * 0.3)]), Palette.WRAITHLIGHT)  # Cold ghost-fire: no warm colour on a nightmare
		&"always_damp", &"damp":
			var art := IconInfo.icon(&"damp")
			if art != null:
				canvas.draw_texture_rect(art, Rect2(c - Vector2(s, s), Vector2(s, s) * 2.0), false)
		&"ignores_slows":  # An arrow through bars
			canvas.draw_line(c + Vector2(-s, 0), c + Vector2(s, 0), colour, w)
			canvas.draw_line(c + Vector2(s * 0.4, -s * 0.5), c + Vector2(s, 0), colour, w)
			canvas.draw_line(c + Vector2(s * 0.4, s * 0.5), c + Vector2(s, 0), colour, w)
			canvas.draw_line(c + Vector2(-s * 0.4, -s), c + Vector2(-s * 0.4, s), Color(colour, 0.5), w)
		&"thief":  # A drop with a minus
			canvas.draw_circle(c + Vector2(0, s * 0.25), s * 0.6, Palette.DEWLIGHT)
			canvas.draw_line(c + Vector2(-s * 0.35, s * 0.25), c + Vector2(s * 0.35, s * 0.25), Palette.ROOT, w)
		&"splits", &"sapling", &"rises":
			canvas.draw_circle(c + Vector2(-s * 0.45, 0), s * 0.45, colour)
			canvas.draw_circle(c + Vector2(s * 0.5, -s * 0.2), s * 0.35, colour)
			canvas.draw_circle(c + Vector2(s * 0.35, s * 0.55), s * 0.25, colour)
		&"followers":
			for i in 3:
				canvas.draw_circle(c + Vector2(-s + i * s, 0), s * (0.45 - 0.1 * i), colour)
		&"swarm", &"bulky":
			for offset in [Vector2(-0.5, -0.4), Vector2(0.5, -0.4), Vector2(0, 0.5)]:
				canvas.draw_circle(c + offset * s, s * (0.3 if glyph == &"swarm" else 0.5), colour)
		_:
			canvas.draw_circle(c, s * 0.4, colour)
