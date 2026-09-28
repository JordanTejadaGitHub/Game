class_name DetailPass
extends RefCounted
# The "detailed 64" pass (documentation/art_direction.md, "Rendering style"): every art generator
# runs its finished 64x64 frames through this before saving. In order it adds
#   1. a 1 px rim of light on the upper-left inside edge, dithered seams between shading bands and
#      a little grain (refine),
#   2. form light from the upper left in banded steps, selective outlines, sparse material texture
#      (leaf clumps, bark grain, path pebbles, stone cracks), nightmare motes and smoke, and a banded
#      glow around warm lights and nightmare eyes (enrich),
#   3. then snaps every pixel to the Heartwood 32 palette (nightmares to the cold ramps only).
# Port of the Theme Discussion reference (helpers.js refine + enrich.js + palette.js remap); keep the
# numbers in step with the "Detailed · 64" column of https://claude.ai/artifact/L3HVzecXZZLdogJKHtkuvy.
#
#   DetailPass.apply(img, DetailPass.Kind.WARDEN)                      # one frame
#   DetailPass.apply_sheet(sheet, Vector2i(64, 64), DetailPass.Kind.NIGHTMARE)  # frame by frame
#
# Pixels with alpha < 128 count as empty for edges and shapes; the glow and smoke it adds are
# palette colours with alpha steps.

enum Kind {
	WARDEN,     ## Wardens, the Heartwood, warm props: gold rim.
	OBSTACLE,   ## Boulders, trees, other world objects: pale rim.
	NIGHTMARE,  ## Nightmares: violet rim, motes, smoke; cold ramps only.
	TILE,       ## Seamless ground tiles: no rim or form light, edges wrap by clamping.
}

# Rim colour and strength per kind (palette.js WARM / COLD / PALE).
const RIM := {
	Kind.WARDEN: ["fcd47c", 0.2],
	Kind.OBSTACLE: ["dccdb2", 0.12],
	Kind.NIGHTMARE: ["9a84e8", 0.24],
	Kind.TILE: ["dccdb2", 0.12],
}


## Runs the full pass on one frame in place (converted to RGBA8) and returns it. `glow_radius` (px)
## sets how far the glow halo and nightmare smoke spread; 0 = from the frame width, max(3, w / 32)
## (64 → 3, 112 → 4, 144 → 5, 176 → 6). Rim, seams, texture and motes are always 1 px.
## `texture` (0..1) thins the grain, material texture and motes: 1 = the reference, 0.5 = half as
## many pixels, 0 = none (for art that is already shaded, or calm ground tiles). Rim, seams, form
## light, glow and smoke stay.
static func apply(img: Image, kind: Kind, glow_radius := 0, texture := 1.0) -> Image:
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	var p := _read(img)
	var tile := kind == Kind.TILE
	_refine(p, w, h, tile, _hex(RIM[kind][0]), RIM[kind][1], texture)
	_enrich(p, w, h, kind, glow_radius if glow_radius > 0 else maxi(3, roundi(w / 32.0)), texture)
	_write(img, p)
	HeartwoodPalette.snap_image(img, kind == Kind.NIGHTMARE)
	return img


## Runs the pass on each `frame`-sized cell of a sheet separately, so blur and edges never bleed
## between frames. Returns the sheet.
static func apply_sheet(sheet: Image, frame: Vector2i, kind: Kind, glow_radius := 0, texture := 1.0) -> Image:
	if sheet.get_format() != Image.FORMAT_RGBA8:
		sheet.convert(Image.FORMAT_RGBA8)
	for y in range(0, sheet.get_height() - frame.y + 1, frame.y):
		for x in range(0, sheet.get_width() - frame.x + 1, frame.x):
			var rect := Rect2i(x, y, frame.x, frame.y)
			var cell := sheet.get_region(rect)
			if cell.is_invisible():
				continue
			apply(cell, kind, glow_radius, texture)
			sheet.blit_rect(cell, Rect2i(Vector2i.ZERO, frame), rect.position)
	return sheet


# ---- pixels: ints packed like the reference's little-endian Uint32 (a << 24 | b << 16 | g << 8 | r)

static func _read(img: Image) -> PackedInt64Array:
	var data := img.get_data()
	var p := PackedInt64Array()
	p.resize(data.size() / 4)
	for i in p.size():
		p[i] = data.decode_u32(i * 4)
	return p


static func _write(img: Image, p: PackedInt64Array) -> void:
	var data := PackedByteArray()
	data.resize(p.size() * 4)
	for i in p.size():
		data.encode_u32(i * 4, p[i])
	img.set_data(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8, data)


static func _k(v: int) -> int:
	return 0 if (v >> 24) < 128 else v


static func _pack(r: int, g: int, b: int, a: int) -> int:
	return (a << 24) | (b << 16) | (g << 8) | r


static func _hex(h: String) -> int:
	var v := h.hex_to_int()
	return _pack((v >> 16) & 0xff, (v >> 8) & 0xff, v & 0xff, 255)


static func _lum(v: int) -> float:
	return 0.3 * (v & 0xff) + 0.59 * ((v >> 8) & 0xff) + 0.11 * ((v >> 16) & 0xff)


## Moves v's rgb toward t's by k, keeping v's alpha (truncates like the reference's `| 0`).
static func _mix(v: int, t: int, k: float) -> int:
	var r := v & 0xff
	var g := (v >> 8) & 0xff
	var b := (v >> 16) & 0xff
	return _pack(int(r + ((t & 0xff) - r) * k), int(g + (((t >> 8) & 0xff) - g) * k),
		int(b + (((t >> 16) & 0xff) - b) * k), (v >> 24) & 0xff)


## Stable per-pixel noise in [0, 1).
static func _hash(x: int, y: int) -> float:
	return (((x * 73856093) ^ (y * 19349663) ^ 0x5bd1e995) & 0xffffffff) % 1000 / 1000.0


## Pixel at (x, y) with low alpha as 0; outside the image is 0, or the clamped edge for tiles.
static func _at(p: PackedInt64Array, w: int, h: int, tile: bool, x: int, y: int) -> int:
	if x < 0 or y < 0 or x >= w or y >= h:
		if not tile:
			return 0
		x = clampi(x, 0, w - 1)
		y = clampi(y, 0, h - 1)
	return _k(p[y * w + x])


static func _edge(p: PackedInt64Array, w: int, h: int, tile: bool, x: int, y: int) -> bool:
	return _at(p, w, h, tile, x, y) != 0 and (_at(p, w, h, tile, x - 1, y) == 0
		or _at(p, w, h, tile, x + 1, y) == 0 or _at(p, w, h, tile, x, y - 1) == 0
		or _at(p, w, h, tile, x, y + 1) == 0)


static func _inner(p: PackedInt64Array, w: int, h: int, tile: bool, x: int, y: int) -> bool:
	return _at(p, w, h, tile, x, y) != 0 and not _edge(p, w, h, tile, x, y)


# ---- 1. refine: dithered band seams, the upper-left rim of light, grain

static func _refine(p: PackedInt64Array, w: int, h: int, tile: bool, rim: int, rim_k: float, texture: float) -> void:
	var base := p.duplicate()
	var white := _hex("fff4dc")
	var black := _hex("05060a")
	for y in h:
		for x in w:
			if not _inner(base, w, h, tile, x, y):
				continue
			var v := base[y * w + x]
			if ((x + y) & 1) == 0:
				var r := _at(base, w, h, tile, x + 1, y)
				var d := _at(base, w, h, tile, x, y + 1)
				if r != 0 and r != v and _inner(base, w, h, tile, x + 1, y) \
						and _at(base, w, h, tile, x - 1, y) == v and _at(base, w, h, tile, x + 2, y) == r:
					var dl := absf(_lum(r) - _lum(v))
					if dl > 4 and dl < 80:
						v = r
				elif d != 0 and d != v and _inner(base, w, h, tile, x, y + 1) \
						and _at(base, w, h, tile, x, y - 1) == v and _at(base, w, h, tile, x, y + 2) == d:
					var dl := absf(_lum(d) - _lum(v))
					if dl > 4 and dl < 80:
						v = d
			if not tile and (_edge(base, w, h, tile, x, y - 1) or _edge(base, w, h, tile, x - 1, y)):
				v = _mix(v, rim, rim_k)
			var hh := _hash(x, y)
			if hh < 0.05 * texture:
				v = _mix(v, black, 0.09)
			elif hh > 1.0 - 0.04 * texture:
				v = _mix(v, white, 0.07)
			p[y * w + x] = v


# ---- 2. enrich: form light, selective outline, materials, motes, smoke, banded glow

static func _hsv(v: int) -> Vector3:
	var c := Color8(v & 0xff, (v >> 8) & 0xff, (v >> 16) & 0xff)
	var mx := maxf(c.r, maxf(c.g, c.b))
	var mn := minf(c.r, minf(c.g, c.b))
	var d := mx - mn
	var hue := 0.0
	if d > 0.0:
		if mx == c.r:
			hue = fmod((c.g - c.b) / d + 6.0, 6.0)
		elif mx == c.g:
			hue = (c.b - c.r) / d + 2.0
		else:
			hue = (c.r - c.g) / d + 4.0
	return Vector3(hue * 60.0, d / mx if mx > 0.0 else 0.0, mx)


static func _box_blur(a: PackedFloat32Array, w: int, h: int, r: int) -> PackedFloat32Array:
	var t := PackedFloat32Array()
	t.resize(w * h)
	var o := PackedFloat32Array()
	o.resize(w * h)
	for y in h:
		for x in w:
			var s := 0.0
			var n := 0
			for k in range(-r, r + 1):
				if x + k >= 0 and x + k < w:
					s += a[y * w + x + k]
					n += 1
			t[y * w + x] = s / n
	for y in h:
		for x in w:
			var s := 0.0
			var n := 0
			for k in range(-r, r + 1):
				if y + k >= 0 and y + k < h:
					s += t[(y + k) * w + x]
					n += 1
			o[y * w + x] = s / n
	return o


static func _enrich(p: PackedInt64Array, w: int, h: int, kind: Kind, radius: int, texture: float) -> void:
	var base := p.duplicate()
	var tile := kind == Kind.TILE
	var night := kind == Kind.NIGHTMARE
	var mask := PackedFloat32Array()
	mask.resize(w * h)
	for i in w * h:
		mask[i] = 1.0 if _k(base[i]) != 0 else 0.0
	var blur := _box_blur(_box_blur(mask, w, h, radius), w, h, radius)
	var black := _hex("07060c")
	var light_c := _hex("c7b4ff" if night else "fff0c8")
	var shadow_c := _hex("0a0716" if night else "1a1430")
	var leaf_hi := _hex("e9f5a8")
	var violet := _hex("8a6fe0")
	for y in h:
		for x in w:
			var i := y * w + x
			var v := base[i]
			if _k(v) == 0:
				continue
			var hsv := _hsv(v)
			var hu := hsv.x
			var s := hsv.y
			var val := hsv.z
			# Form light from the upper left, in two banded steps so it stays pixel art.
			if not tile:
				var gx := _bv(blur, w, h, x + 1, y) - _bv(blur, w, h, x - 1, y)
				var gy := _bv(blur, w, h, x, y + 1) - _bv(blur, w, h, x, y - 1)
				var lit := (gx + gy) * 2.2
				if _edge(base, w, h, tile, x, y):
					if lit > 0.12:  # selective outline: lit edges pick up the colour inside
						var inside := 0
						if not _edge(base, w, h, tile, x + 1, y + 1):
							for c in [_at(base, w, h, tile, x + 1, y), _at(base, w, h, tile, x, y + 1),
									_at(base, w, h, tile, x + 1, y + 1)]:
								if c != 0:
									inside = c
									break
						if inside != 0:
							v = _mix(v, inside, 0.45)
					p[i] = v
					continue
				var k := 0.0
				if lit > 0.28:
					k = 0.32
				elif lit > 0.1:
					k = 0.17
				elif lit < -0.28:
					k = -0.38
				elif lit < -0.1:
					k = -0.2
				if k > 0.0:
					v = _mix(v, light_c, k)
				elif k < 0.0:
					v = _mix(v, shadow_c, -k)
			var hr := _hash(x, y)
			if _hash(x + 101, y + 59) >= texture:  # `texture` < 1 skips material texture here
				p[i] = v
				continue
			if hu > 65 and hu < 165 and s > 0.25:
				# Moss and leaves: tiny lit leaf clumps with a shadow under each; grass blades on tiles.
				if hr < 0.1:
					v = _mix(v, leaf_hi, 0.4)
				elif _hash(x, y - 1) < 0.1:
					v = _mix(v, black, 0.26)
				if tile and hr > 0.975:
					for k2 in range(1, 4):
						if y - k2 >= 0:
							p[(y - k2) * w + x] = _mix(base[(y - k2) * w + x], leaf_hi, 0.28)
					v = _mix(v, black, 0.2)
			elif hu >= 12 and hu <= 48 and s > 0.2 and val < 0.75:
				# Bark and wood: vertical grain.
				var n := int(_hash(7, y >> 2) * 6)
				if (x + n) % 5 == 0:
					v = _mix(v, black, 0.26)
				elif (x + n) % 5 == 2 and hr < 0.5:
					v = _mix(v, light_c, 0.14)
			elif hu >= 20 and hu <= 55 and s <= 0.35 and val > 0.55:
				# Pale path earth: pebbles and small cracks.
				if hr < 0.012:
					v = _mix(v, light_c, 0.25)
					if y + 1 < h:
						p[i + w] = _mix(base[i + w], black, 0.25)
				elif _hash(x >> 3, y >> 3) < 0.1 and ((x - y) & 7) == 0:
					v = _mix(v, black, 0.14)
			elif (s < 0.22 and val > 0.28 and val < 0.9) \
					or (hu > 215 and hu < 300 and s < 0.5 and val > 0.33 and not night):
				# Stone: cracks and speckle.
				if _hash(x >> 3, y >> 3) < 0.3 and ((x + y) & 7) == 0:
					v = _mix(v, black, 0.34)
				elif hr < 0.1:
					v = _mix(v, light_c, 0.2)
				elif hr > 0.93:
					v = _mix(v, black, 0.18)
			elif night and val < 0.4:
				# Nightmare bodies: cold motes drifting inside the dark.
				if hr < 0.06:
					v = _mix(v, violet, 0.5)
			p[i] = v
	# Nightmares: dark smoke trailing off the lower half of the silhouette.
	if night:
		for y in range(h / 2, h):
			for x in w:
				var i := y * w + x
				if _k(base[i]) != 0:
					continue
				var b := _bv(blur, w, h, x, y - 2)
				if b > 0.18 and _hash(x, y) < b * 1.4:
					p[i] = _pack(22, 16, 42, 170 if b > 0.35 else 105)
	# Glow: warm lights bloom gold; nightmare eyes bloom cold. Banded in thirds, never a soft blur.
	var glow := PackedFloat32Array()
	glow.resize(w * h)
	var any := false
	for i in w * h:
		var v := base[i]
		if _k(v) == 0:
			continue
		var r := v & 0xff
		var g := (v >> 8) & 0xff
		var b := (v >> 16) & 0xff
		var l := _lum(v)
		if (r > 190 and g > 140 and b < 150 and l > 150) or (night and l > 150):
			glow[i] = 1.0
			any = true
	if not any:
		return
	var glow_b := _box_blur(_box_blur(glow, w, h, radius), w, h, radius)
	var glow_c := _pack(190, 170, 255, 255) if night else _pack(255, 206, 110, 255)
	for i in w * h:
		var a := minf(1.0, glow_b[i] * 3.2)
		if a < 0.08:
			continue
		a = roundf(a * 3.0) / 3.0
		var v := p[i]
		if _k(v) == 0 and (v >> 24) < 60:
			p[i] = (glow_c & 0xffffff) | (roundi(a * 150.0) << 24)
		elif _k(v) != 0:
			p[i] = _mix(v, glow_c, a * 0.35)


static func _bv(blur: PackedFloat32Array, w: int, h: int, x: int, y: int) -> float:
	if x < 0 or y < 0 or x >= w or y >= h:
		return 0.0
	return blur[y * w + x]
