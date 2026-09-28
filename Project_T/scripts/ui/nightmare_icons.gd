extends Control
class_name NightmareIcons

# Resistances and immunities as icons (screens_ui.md "Nightmare info", added 2026-09-28): one small
# icon control, three kinds:
# - a damage type (enemy_design.md "Damage types": the Warden's TowerData.line; IconInfo names it) =
#   its type icon (a coloured initial until the art), with a grey shield (resists, ×0.5) or a warm
#   spark (weak to, ×1.5); rows show it with its name: "Resists [icon] Stone ×0.5";
# - a status = IconInfo's sheet icon, crossed out (immune) or with "½" (wears off faster);
# - a trait (Flying, Hidden, Dread shell, Passes through walls, …): a drawn glyph in a dark disc.
# Every icon explains itself on hover and on tap (TapTip). make_rows(data) builds the "Resists /
# Weak to / Immune" rows for the nightmare info, the Coming strip and the boss dossier.

enum Kind { FAMILY, STATUS, TRAIT }

# Damage line -> its family's base Warden (the face shown). "support" is Acorn's line in the docs.
const LINE_WARDENS := {"spore": "sporeling", "stone": "pebbling", "water": "dewdrop", "light": "firefly_jar",
	"root": "rootling", "song": "bellflower", "wing": "nestling", "wind": "whirligig", "acorn": "acorn",
	"support": "acorn"}
const TOWER_DIR := "res://resource/tower/"
# How a line reads in a sentence ("stone Wardens deal half damage to it").
const LINE_WORDS := {"acorn": "Acorn", "support": "Acorn"}

const RESIST_COLOR := Color(0.62, 0.65, 0.7)
const WEAK_COLOR := Color(1.0, 0.72, 0.35)
const IMMUNE_COLOR := Color(0.95, 0.35, 0.3)
const DISC_COLOR := Color(0.07, 0.08, 0.1, 0.9)
const GLYPH_COLOR := Color(0.88, 0.86, 0.95)

# Traits: id -> [name, what it means]. The first ones are EnemyData.get_defences()' trait ids (Enemy
# Code); the rest are read from other EnemyData fields by traits_of(). Boss ability icons
# (EnemyData.abilities "icon") use the same glyphs (draw_glyph).
const TRAITS := {
	&"flying": ["Flying", "Flies over the maze: walls don't bend its route."],
	&"through_walls": ["Passes through walls", "Glides straight through the maze: walls don't bend its route."],
	&"hidden": ["Hidden", "Can't be seen or targeted until something reveals it, or it comes close."],
	&"dread_shell": ["Dread shell", "A shell soaks up part of every hit until it cracks for good."],
	&"always_damp": ["Always {damp}", "It's always {damp}: lightning loves it."],
	&"ignores_slows": ["Never slowed", "{damp}, {drowsy} and slowing auras don't slow it."],
	&"sprints": ["Sprints", "Speeds up down long straight corridors, until the next turn."],
	&"burrows": ["Burrows", "Sinks under a Warden or wall beside it and surfaces on the other side."],
	&"wanders": ["Wanders", "Strays into dead-end pockets and back out, taking its time."],
	&"splits": ["Splits", "Bursts into smaller nightmares when dispelled."],
	&"trample": ["Tramples walls", "Knocks down Thornwalls next to it, for good."],
	&"leap": ["Leaps", "Sinks and rises further along the path, skipping tiles."],
	&"mender": ["Mends", "Heals the nightmares near it."],
	&"waker": ["Wakes others", "Shakes {drowsy} off the nightmares near it."],
	&"revealer": ["Reveals", "Uncovers {hidden} nightmares near it, for your Wardens too."],
	&"ash": ["Ash trail", "Its burning trail clears {spored} from nightmares walking on it."],
	&"thief": ["Steals Dew", "Takes Dew as well as leaves if it reaches the Heartwood."],
	&"followers": ["Brings followers", "Others walk behind it in single file, and get lost without it."],
	&"swarm": ["Swarm", "Single-target hits deal less to it."],
	&"bulky": ["Bulky", "Area hits deal less to it."],
}

var kind := Kind.TRAIT
var id := ""  # Line, status id or trait id
var mode := &""  # FAMILY: &"resist" / &"weak"; STATUS: &"immune" / &"short"
var tip := ""
var _face: Texture2D = null

# --- Builders --------------------------------------------------------------------------------------

# A damage type (enemy_design.md "Damage types": the Warden's TowerData.line) with a shield (`how` =
# &"resist") or spark (&"weak"). The type's icon from the sheet, else a disc in its colour with its
# initial. `side` in px.
static func family(line: String, how: StringName, side: float = 28.0) -> NightmareIcons:
	var icon := NightmareIcons.new()
	icon.kind = Kind.FAMILY
	icon.id = line
	icon.mode = how
	icon._face = IconInfo.damage_type_icon(line)
	var name := IconInfo.damage_type_name(line)
	if how == &"resist":
		icon.tip = "Resists %s: %s damage deals half to it." % [name, name]
	else:
		icon.tip = "Weak to %s: %s damage deals 50%% more to it." % [name, name]
	return icon._sized(side)

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
		icon.tip = "Immune to %s %s: it doesn't take hold then." % [name, condition]
	elif how == &"immune":
		icon.tip = "Immune to %s: it never takes hold." % name
	elif is_equal_approx(multiplier, 0.5):
		icon.tip = "Shrugs off %s: it wears off twice as fast." % name
	else:
		icon.tip = "Shrugs off %s: it lasts %d%% as long." % [name, roundi(multiplier * 100.0)]
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
	if data.single_target_multiplier < 1.0: extra.append(&"swarm")
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

# The "Resists ×0.5 / Weak to ×1.5 / Immune" rows for `data` (each hidden when empty) plus a traits
# row. `side` = icon size; `compact` = resist and weak icons only, in one row, no captions (the
# Coming strip). Returns an empty box when there's nothing to show.
static func make_rows(data: EnemyData, side: float = 28.0, compact: bool = false, with_traits: bool = true) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	var d := defences(data)
	var resists: Array = d.get("resists", []).filter(in_build)
	var weak: Array = d.get("weak_to", []).filter(in_build)
	if compact:
		var row := HFlowContainer.new()
		row.alignment = FlowContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("h_separation", 1)
		for line in resists:
			row.add_child(family(line, &"resist", side))
		for line in weak:
			row.add_child(family(line, &"weak", side))
		if row.get_child_count() > 0:
			box.add_child(row)
		else:
			row.free()
		return box
	var font := int(maxf(side * 0.5, 13.0))
	if not resists.is_empty():
		var icons: Array[Control] = []
		for line in resists:
			icons.append(_typed(line, &"resist", side, font, EnemyData.RESIST_MULTIPLIER))
		box.add_child(_row("Resists", RESIST_COLOR, icons, font))
	if not weak.is_empty():
		var icons: Array[Control] = []
		for line in weak:
			icons.append(_typed(line, &"weak", side, font, EnemyData.WEAK_MULTIPLIER))
		box.add_child(_row("Weak to", WEAK_COLOR, icons, font))
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
	for status_id in short:
		guarded.append(status(status_id, &"short", short[status_id], side))
	if not guarded.is_empty():
		box.add_child(_row("Immune / shrugs off", IMMUNE_COLOR.lightened(0.3), guarded, font))
	if with_traits:
		var icons: Array[Control] = []
		for trait_id in traits_of(data):
			icons.append(trait_icon(trait_id, side))
		if not icons.is_empty():
			box.add_child(_row("Traits", GLYPH_COLOR, icons, font))
	return box

# A damage type's icon, name and multiplier ("[icon] Stone ×0.5"); the whole entry taps to its tip.
static func _typed(line: String, how: StringName, side: float, font: int, multiplier: float) -> Control:
	var entry := HBoxContainer.new()
	entry.add_theme_constant_override("separation", 3)
	var icon := family(line, how, side)
	entry.add_child(icon)
	var name := Label.new()
	name.text = "%s ×%s" % [IconInfo.damage_type_name(line), _num(multiplier)]
	name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name.add_theme_font_size_override("font_size", font)
	name.add_theme_color_override("font_color", IconInfo.damage_type_color(line).lightened(0.2))
	TapTip.attach(name, icon.tip)
	entry.add_child(name)
	return entry

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
		Kind.FAMILY: _draw_family()
		Kind.STATUS: _draw_status()
		_: _draw_trait()

func _draw_family() -> void:
	var c := size / 2.0
	var r := minf(size.x, size.y) / 2.0 - 1.0
	var frame := RESIST_COLOR if mode == &"resist" else WEAK_COLOR
	var type_colour := IconInfo.damage_type_color(id)
	draw_circle(c, r, Color(0.12, 0.13, 0.16) if mode == &"resist" else Color(0.2, 0.14, 0.08))
	if _face != null:  # The damage type's pixel-art icon, whole-number scaled
		var scale := maxf(floorf(r * 1.6 / 16.0), 1.0)
		var side := Vector2(16, 16) * scale
		draw_texture_rect(_face, Rect2(c - side / 2.0, side), false)
	else:  # Until the art: a disc in the type's colour with its initial
		draw_circle(c, r * 0.72, type_colour)
		var font := ThemeDB.fallback_font
		var letter := IconInfo.damage_type_name(id).left(1)
		var fs := int(r * 1.0)
		var w := font.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(font, c + Vector2(-w / 2.0, fs * 0.36), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.08, 0.08, 0.1))
	draw_arc(c, r, 0.0, TAU, 28, frame, 2.0, true)
	# The badge, bottom right: a small shield (resists) or a four-point spark (weak).
	var b := c + Vector2(r * 0.62, r * 0.62)
	var s := maxf(r * 0.42, 4.0)
	if mode == &"resist":
		var shield := PackedVector2Array([b + Vector2(-s, -s), b + Vector2(s, -s), b + Vector2(s, 0.1 * s),
			b + Vector2(0, s * 1.1), b + Vector2(-s, 0.1 * s)])
		draw_colored_polygon(shield, RESIST_COLOR)
		draw_polyline(shield + PackedVector2Array([shield[0]]), Color(0.1, 0.1, 0.12), 1.0)
	else:
		draw_circle(b, s * 0.9, Color(0.2, 0.12, 0.05))
		var spark := PackedVector2Array()
		for i in 8:
			spark.append(b + Vector2.from_angle(TAU * i / 8.0 - PI / 2.0) * (s * 1.1 if i % 2 == 0 else s * 0.35))
		draw_colored_polygon(spark, WEAK_COLOR)

func _draw_status() -> void:
	var c := size / 2.0
	var r := minf(size.x, size.y) / 2.0
	draw_circle(c, r - 1.0, DISC_COLOR)
	var art := IconInfo.icon(StringName(id))
	if art != null:
		var scale := maxf(floorf((r * 2.0 - 4.0) / 16.0), 1.0)
		var side := Vector2(16, 16) * scale
		draw_texture_rect(art, Rect2(c - side / 2.0, side), false,
			Color(0.75, 0.75, 0.78) if mode == &"immune" else Color.WHITE)
	else:
		draw_circle(c, r * 0.4, EnemyStatuses.COLORS.get(StringName(id), Color.WHITE))
	if mode == &"immune":  # Crossed out
		var d := Vector2(r * 0.7, r * 0.7)
		draw_line(c - d, c + d, Color(0.08, 0.05, 0.05), 5.0, true)
		draw_line(c - d, c + d, IMMUNE_COLOR, 3.0, true)
		draw_arc(c, r - 1.5, 0.0, TAU, 28, IMMUNE_COLOR, 2.0, true)
	else:  # "½"
		var font := ThemeDB.fallback_font
		var fs := int(maxf(r * 0.8, 10.0))
		var at := c + Vector2(r * 0.15, r * 0.95)
		draw_string_outline(font, at, "½", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, Color(0.05, 0.05, 0.08))
		draw_string(font, at, "½", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1.0, 0.85, 0.5))
		draw_arc(c, r - 1.5, 0.0, TAU, 28, Color(1.0, 0.85, 0.5, 0.8), 1.5, true)

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
				c + Vector2(0, s), c + Vector2(-s * 0.6, s * 0.3)]), Color(1.0, 0.55, 0.3))
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
			canvas.draw_circle(c + Vector2(0, s * 0.25), s * 0.6, Color(0.6, 0.85, 1.0))
			canvas.draw_line(c + Vector2(-s * 0.35, s * 0.25), c + Vector2(s * 0.35, s * 0.25), Color(0.1, 0.1, 0.15), w)
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
