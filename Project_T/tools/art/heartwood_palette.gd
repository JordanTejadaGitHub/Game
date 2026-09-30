class_name HeartwoodPalette
extends RefCounted
# The Heartwood 32 master palette (documentation/art_direction.md, "the Heartwood 32 palette").
# Every piece of game art uses only these 32 colours. Generators pick colours by name
# (`HeartwoodPalette.color("gold")`), never raw hex, and snap what they write with `snap_image()`.
# Nightmares use only the cold ramps (Ink, Nightmare, Stone & moon, Dew): pass `cold = true`.
# The same colours are exported for non-Godot tools in assets/palette/ (heartwood32.gpl / .hex /
# .png, written by tools/art/palette_export.gd).
# Warden Night (art_direction.md "Decision (2026-09-30)", documentation/warden_night.md): Warden idle
# sheets alone may also use 3 more colours (Rosedust, Plum, Nightbloom, 35 in all). Pass
# `wardens = true` to snap to them, and `warden_night(img)` shifts a finished idle sheet one shade
# darker by the map. Nothing else (nightmares, tiles, the Heartwood, UI) ever gets them.

# Dark → light within each ramp.
const RAMPS := [
	{"name": "Ink", "role": "outlines, shadows, the night sky",
		"colors": [["Void", "05050d"], ["Night", "24243c"], ["Dusk", "3c3c5c"], ["Slate", "5c5a78"]]},
	{"name": "Nightmare", "role": "nightmare bodies, rims, cold glow",
		"colors": [["Dread", "140f26"], ["Shade", "2c2444"], ["Bruise", "4c3c74"], ["Wraithlight", "9a84e8"]]},
	{"name": "Stone & moon", "role": "boulders, mist, cold highlights, eyes",
		"colors": [["Stone", "8c8cac"], ["Mist", "b4b0c8"], ["Moonlight", "dce8f4"]]},
	{"name": "Moss", "role": "ground, leaves, the canopy",
		"colors": [["Deepmoss", "1c3c2c"], ["Moss", "34643c"], ["Leaf", "5c944c"], ["Sprig", "9cc46c"], ["Newleaf", "d4ec9c"]]},
	{"name": "Bark", "role": "trunks, roots, dead trees",
		"colors": [["Root", "241c14"], ["Bark", "5c3c24"], ["Oak", "8c5c34"], ["Deadwood", "bca48c"]]},
	{"name": "Path", "role": "the path; Moonpath is the palest ground",
		"colors": [["Loam", "6c5c5c"], ["Path", "b4a494"], ["Moonpath", "dccdb2"]]},
	{"name": "Warm light", "role": "attacks, the hollow, dream-fruit, fireflies",
		"colors": [["Ember", "b8662c"], ["Gold", "e9a83c"], ["Glow", "fcd47c"], ["Heartlight", "fff4dc"]]},
	{"name": "Blossom", "role": "Sporeling and flower Wardens",
		"colors": [["Orchid", "bc44dc"], ["Blossom", "ec9cf4"]]},
	{"name": "Dew", "role": "water Wardens, jars, dew pools",
		"colors": [["Pool", "2c4c5c"], ["Dew", "4c8ca4"], ["Dewlight", "9cd4fc"]]},
]
const COLD_RAMPS := ["Ink", "Nightmare", "Stone & moon", "Dew"]
const SIZE := 32

# Warden Night: the 3 Warden-only colours (idle sheets only) and the one-shade-darker map.
const WARDEN_COLORS := [
	["Rosedust", "b27aae", "Sporeling and flower Wardens: the night shade of Blossom"],
	["Plum", "7a4a82", "the night shade of Orchid"],
	["Nightbloom", "6b6fb0", "Dreamshroom and violet Wardens: the night shade of Wraithlight"],
]
const WARDEN_SIZE := 35
# From → to; colours not listed stay (Void, Night, Dusk, Dread, Shade, Bruise, Deepmoss, Root, Loam,
# Pool). Must match assets/style_reference/warden_night/warden_night.json (tests/test_palette.gd).
const WARDEN_NIGHT_MAP := {
	"Slate": "Dusk", "Moonlight": "Mist", "Mist": "Stone", "Stone": "Slate",
	"Wraithlight": "Nightbloom",
	"Newleaf": "Sprig", "Sprig": "Leaf", "Leaf": "Moss", "Moss": "Deepmoss",
	"Deadwood": "Path", "Oak": "Bark", "Bark": "Root",
	"Moonpath": "Path", "Path": "Loam",
	"Heartlight": "Moonpath", "Glow": "Gold", "Gold": "Ember", "Ember": "Oak",
	"Blossom": "Rosedust", "Orchid": "Plum",
	"Dewlight": "Dew", "Dew": "Pool",
}

static var _names: PackedStringArray = []
static var _by_name := {}          # lower-case name -> Color (the 32 and the Warden 3)
static var _rgb: PackedInt32Array = []  # 0xRRGGBB per index: the 32, then the Warden 3
static var _lab: Array[Vector3] = []
static var _cold: Array[bool] = []
static var _night_map := {}        # 0xRRGGBB -> 0xRRGGBB (Warden Night)
static var _cache := {}            # (rgb | cold << 24 | wardens << 25) -> 0xRRGGBB


static func _ensure() -> void:
	if not _rgb.is_empty():
		return
	for ramp: Dictionary in RAMPS:
		var cold: bool = ramp.name in COLD_RAMPS
		for entry: Array in ramp.colors:
			_add(entry[0], entry[1], cold)
			_names.append(entry[0])
	for entry: Array in WARDEN_COLORS:
		_add(entry[0], entry[1], false)
	for from: String in WARDEN_NIGHT_MAP:
		_night_map[_to_int(_by_name[from.to_lower()])] = _to_int(_by_name[WARDEN_NIGHT_MAP[from].to_lower()])


static func _add(color_name: String, hex: String, cold: bool) -> void:
	var c := Color.html(hex)
	_by_name[color_name.to_lower()] = c
	_rgb.append(hex.hex_to_int())
	_lab.append(oklab(c))
	_cold.append(cold)


## A palette colour by name, case-insensitive ("gold", "Moonpath"; the Warden-only "rosedust" too).
## Errors on an unknown name.
static func color(color_name: String, alpha := 1.0) -> Color:
	_ensure()
	var key := color_name.to_lower()
	assert(_by_name.has(key), "HeartwoodPalette: no colour named '%s'" % color_name)
	var c: Color = _by_name.get(key, Color.MAGENTA)
	c.a = alpha
	return c


static func has_color(color_name: String) -> bool:
	_ensure()
	return _by_name.has(color_name.to_lower())


## All 32 colours in ramp order (dark → light within each ramp).
static func colors() -> Array[Color]:
	_ensure()
	var out: Array[Color] = []
	for n in _names:
		out.append(_by_name[n.to_lower()])
	return out


## All 32 names in ramp order.
static func names() -> PackedStringArray:
	_ensure()
	return _names.duplicate()


## The Warden palette (35): the 32, then Rosedust, Plum, Nightbloom. For Warden idle sheets only.
static func warden_colors() -> Array[Color]:
	var out := colors()
	for entry: Array in WARDEN_COLORS:
		out.append(Color.html(entry[1]))
	return out


## True for the 3 Warden-only colours (rgb only).
static func is_warden_only(c: Color) -> bool:
	return index_of(c, true) >= SIZE


## One ramp's colours, dark → light ("Moss", "Warm light", ...).
static func ramp(ramp_name: String) -> Array[Color]:
	var out: Array[Color] = []
	for r: Dictionary in RAMPS:
		if String(r.name).to_lower() == ramp_name.to_lower():
			for entry: Array in r.colors:
				out.append(Color.html(entry[1]))
	return out


## True when the colour (rgb only) is one of the cold-ramp colours nightmares may use.
static func is_cold(c: Color) -> bool:
	var i := index_of(c)
	return i >= 0 and _cold[i]


## Palette index of an exact palette colour (rgb only, 8-bit), or -1. `wardens` also finds the
## Warden-only 3 (indices 32-34).
static func index_of(c: Color, wardens := false) -> int:
	_ensure()
	var i := _rgb.find(_to_int(c))
	return i if i < SIZE or wardens else -1


## Nearest palette colour by OKLab distance; the input's alpha is kept.
## `cold`: only the cold ramps (for nightmares). `wardens`: the 35-colour Warden set (idle sheets).
static func snap(c: Color, cold := false, wardens := false) -> Color:
	var out := Color.hex((_nearest(_to_int(c), cold, wardens) << 8) | 0xff)
	out.a = c.a
	return out


## Snaps every pixel with alpha > 0 in place, keeping its alpha. Converts to RGBA8.
static func snap_image(img: Image, cold := false, wardens := false) -> void:
	_map_image(img, func(v: int) -> int: return _nearest(v, cold, wardens))


## Warden Night: snaps a finished Warden idle sheet to the 32, then shifts every colour one shade
## darker by WARDEN_NIGHT_MAP (documentation/warden_night.md). Alpha is kept, so glow halos stay.
## In place; returns the image. Attack sheets and projectiles don't get this.
static func warden_night(img: Image) -> Image:
	_ensure()
	_map_image(img, func(v: int) -> int:
		var s := _nearest(v, false, false)
		return _night_map.get(s, s))
	return img


static func _map_image(img: Image, f: Callable) -> void:
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
	var data := img.get_data()
	for i in range(0, data.size(), 4):
		if data[i + 3] == 0:
			continue
		var v: int = f.call((data[i] << 16) | (data[i + 1] << 8) | data[i + 2])
		data[i] = (v >> 16) & 0xff
		data[i + 1] = (v >> 8) & 0xff
		data[i + 2] = v & 0xff
	img.set_data(img.get_width(), img.get_height(), img.has_mipmaps(), Image.FORMAT_RGBA8, data)


## Linear sRGB → OKLab (L, a, b).
static func oklab(c: Color) -> Vector3:
	var r := _lin(c.r)
	var g := _lin(c.g)
	var b := _lin(c.b)
	var l := pow(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b, 1.0 / 3.0)
	var m := pow(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b, 1.0 / 3.0)
	var s := pow(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b, 1.0 / 3.0)
	return Vector3(0.2104542553 * l + 0.793617785 * m - 0.0040720468 * s,
		1.9779984951 * l - 2.428592205 * m + 0.4505937099 * s,
		0.0259040371 * l + 0.7827717662 * m - 0.808675766 * s)


static func _lin(v: float) -> float:
	return v / 12.92 if v <= 0.04045 else pow((v + 0.055) / 1.055, 2.4)


static func _to_int(c: Color) -> int:
	return (c.r8 << 16) | (c.g8 << 8) | c.b8


# Nearest palette 0xRRGGBB for an 0xRRGGBB input.
static func _nearest(rgb: int, cold: bool, wardens := false) -> int:
	_ensure()
	var key := rgb | (int(cold) << 24) | (int(wardens) << 25)
	var hit: Variant = _cache.get(key)
	if hit != null:
		return hit
	var lab := oklab(Color.hex((rgb << 8) | 0xff))
	var best := 0
	var best_d := INF
	for i in _lab.size():
		if (cold and not _cold[i]) or (i >= SIZE and not wardens):
			continue
		var d := lab.distance_squared_to(_lab[i])
		if d < best_d:
			best_d = d
			best = i
	_cache[key] = _rgb[best]
	return _rgb[best]
