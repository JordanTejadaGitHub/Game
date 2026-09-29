extends SceneTree
# Generates the placeholder sounds in assets/audio/ (audio_direction.md): the dispel, Warden attacks and hits,
# nightmare signatures, building, the Heartwood, UI, stingers, and act 1's music stems and ambience.
# Everything is synthesized here (no samples), so it's all original and free to ship as a stand-in.
# Warm things use plucks, bells and music box; nightmares use noise, drones and whisper formants.
# Music is in D minor, 72 bpm, 3/4, 8 bars (20 s); every stem has the same length so they loop in sync.
# Run:  Godot --headless --path . --script res://tools/sound_generator.gd
# then once more with --import so Godot imports the new .wav files.

const SFX_RATE := 44100
const MUSIC_RATE := 22050
const SFX_DIR := "res://assets/audio/sfx/"
const MUSIC_DIR := "res://assets/audio/music/"
const SFX_PEAK := 0.7  # ≈ −3 dBFS
# Second listen (audio_direction.md pillar 6, "Rounded, never sharp"): soft onsets, a dark top end,
# bells in their lower octaves, no crackle/click/hiss textures.
const SFX_ONSET := 0.012
const HIT_ONSET := 0.004
const SFX_TOP_HZ := 4500.0  # Every sound effect is lowpassed here
const SFX_BELL_ONSET := 0.008  # Soft mallet
const SFX_MAX_PARTIAL_HZ := 6000.0  # Nothing rings above this
# Warden families with their own hit sound (the rest use sprout's).
const HIT_FAMILIES := ["stone", "root", "water", "light", "spore", "sprout"]

const BPM := 72.0
const BEATS_PER_BAR := 3
const BARS := 8
const BEAT := 60.0 / BPM
const LOOP := BEAT * BEATS_PER_BAR * BARS  # 20 s
const TAIL := 3.0  # Rendered past the loop end, then folded back onto the start (seamless reverb)

# [ratio, amplitude, decay scale] per partial.
const MUSIC_BOX := [[1.0, 1.0, 1.0], [2.0, 0.3, 0.55], [3.0, 0.1, 0.35], [5.04, 0.06, 0.2]]
const BELL := [[0.5, 0.35, 1.5], [1.0, 1.0, 1.0], [1.19, 0.3, 0.8], [1.5, 0.25, 0.7],
	[2.0, 0.4, 0.55], [2.52, 0.18, 0.4], [3.01, 0.12, 0.3]]
const CHIME := [[1.0, 1.0, 1.0], [2.76, 0.35, 0.45], [5.4, 0.15, 0.25], [8.93, 0.06, 0.15]]

# Chord per bar: [bass root midi, third (3 minor / 4 major)]. Dm Bb F C Dm Gm Bb A.
const CHORDS := [[50, 3], [46, 4], [53, 4], [48, 4], [50, 3], [43, 3], [46, 4], [45, 4]]
# Ambience wind gusts: [start s, length s] within the 20 s loop; calm stretches between them.
const AMB_GUSTS := [[0.5, 5.5], [8.5, 4.5], [14.0, 4.5]]
# Music box melody: [beat, midi].
const MELODY :=[[0, 69], [2, 65], [3, 74], [4, 72], [5, 70], [6, 69], [8, 72], [9, 67], [11, 64],
	[12, 65], [13, 69], [14, 74], [15, 70], [16, 67], [17, 62], [18, 65], [19, 70], [20, 74],
	[21, 73], [22, 69], [23, 64]]

var rng := RandomNumberGenerator.new()

func _init() -> void:
	rng.seed = 7071
	side_rng.seed = 4242
	for dir in [SFX_DIR, MUSIC_DIR]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var started := Time.get_ticks_msec()
	_make_sfx()
	_make_music()
	print("Sounds generated in %.1f s" % ((Time.get_ticks_msec() - started) / 1000.0))
	quit()


# --- Building blocks ------------------------------------------------------------------------------

static func hz(midi: float) -> float:
	return 440.0 * pow(2.0, (midi - 69.0) / 12.0)

# A float, or a Callable(t) -> float evaluated at time t.
static func _val(x, t: float) -> float:
	return x.call(t) if x is Callable else float(x)

func _seg(length: float, rate: int) -> PackedFloat32Array:
	var seg := PackedFloat32Array()
	seg.resize(int(length * rate))
	return seg

# Attack, then exponential decay (time constant `tau`), with a short fade at `length`.
static func perc(attack: float, tau: float, length: float) -> Callable:
	return func(t: float) -> float:
		if t < 0.0 or t >= length:
			return 0.0
		var a := t / attack if t < attack else exp(-(t - attack) / tau)
		return a * clampf((length - t) / 0.02, 0.0, 1.0)

# Rises over `attack`, holds, falls over `release` before `length`.
static func swell(attack: float, release: float, length: float) -> Callable:
	return func(t: float) -> float:
		if t < 0.0 or t >= length:
			return 0.0
		return minf(clampf(t / attack, 0.0, 1.0), clampf((length - t) / release, 0.0, 1.0))

# Exponential glide from `a` to `b` over `time`.
static func glide(a: float, b: float, time: float) -> Callable:
	return func(t: float) -> float: return a * pow(b / a, clampf(t / time, 0.0, 1.0))

# Oscillator. `freq` and `amp` may be Callables of t. Shapes: sine, saw, tri, square.
func _tone(rate: int, length: float, freq, amp, shape := "sine") -> PackedFloat32Array:
	var seg := _seg(length, rate)
	var phase := rng.randf()
	for i in seg.size():
		var t := float(i) / rate
		phase = fposmod(phase + _val(freq, t) / rate, 1.0)
		var v := 0.0
		match shape:
			"saw": v = 2.0 * phase - 1.0
			"tri": v = 1.0 - 4.0 * absf(phase - 0.5)
			"square": v = 1.0 if phase < 0.5 else -1.0
			_: v = sin(TAU * phase)
		seg[i] = v * _val(amp, t)
	return seg

func _noise(rate: int, length: float, amp) -> PackedFloat32Array:
	var seg := _seg(length, rate)
	for i in seg.size():
		seg[i] = rng.randf_range(-1.0, 1.0) * _val(amp, float(i) / rate)
	return seg

# State-variable filter. mode: "lp", "bp", "hp". `cutoff` may be a Callable of t. `damp` = 1/Q.
func _filter(seg: PackedFloat32Array, rate: int, cutoff, damp := 0.7, mode := "lp") -> PackedFloat32Array:
	var low := 0.0
	var band := 0.0
	var out := PackedFloat32Array()
	out.resize(seg.size())
	var constant := not (cutoff is Callable)
	var f := 2.0 * sin(PI * minf(float(cutoff) if constant else 0.0, rate / 6.0) / rate)
	for i in seg.size():
		if not constant:
			f = 2.0 * sin(PI * clampf(cutoff.call(float(i) / rate), 10.0, rate / 6.0) / rate)
		low += f * band
		var high := seg[i] - low - damp * band
		band += f * high
		out[i] = low if mode == "lp" else (band if mode == "bp" else high)
	return out

func _env(seg: PackedFloat32Array, rate: int, amp: Callable) -> PackedFloat32Array:
	for i in seg.size():
		seg[i] *= amp.call(float(i) / rate)
	return seg

# Adds `src` into `dst` starting at `at` seconds (grows `dst` if needed).
func _mix(dst: PackedFloat32Array, src: PackedFloat32Array, rate: int, at: float, gain := 1.0) -> void:
	var offset := int(at * rate)
	if offset + src.size() > dst.size():
		dst.resize(offset + src.size())
	for i in src.size():
		dst[offset + i] += src[i] * gain

# Sounds that were replaced draw from their own generator (`_side`) and `_burn` what the old version
# drew, so every sound generated after them stays byte-identical (e.g. the approved Firefly Jar).
var side_rng := RandomNumberGenerator.new()  # Seeded in _init, so the replaced sounds are reproducible too

func _side(make: Callable) -> PackedFloat32Array:
	var main := rng
	rng = side_rng
	var out: PackedFloat32Array = make.call()
	rng = main
	return out

func _burn(draws: int) -> void:
	for i in draws:
		rng.randf()

# Sum of decaying partials (music box, bell, chime). `decay` = the fundamental's time constant.
func _bell(rate: int, freq: float, amp: float, decay: float, partials: Array, length := -1.0) -> PackedFloat32Array:
	if length < 0.0:
		length = decay * 5.0
	var seg := _seg(length, rate)
	var sfx := rate == SFX_RATE  # Sound effects: soft mallet, no partials above SFX_MAX_PARTIAL_HZ
	var onset := SFX_BELL_ONSET if sfx else 0.003
	for p in partials:
		var f: float = freq * p[0]
		var phase := rng.randf() * TAU
		if f > rate * 0.45 or (sfx and f > SFX_MAX_PARTIAL_HZ):
			continue
		var a: float = amp * p[1]
		var tau: float = decay * p[2]
		var step := TAU * f / rate
		for i in seg.size():
			var t := float(i) / rate
			seg[i] += sin(phase + step * i) * a * minf(t / onset, 1.0) * exp(-t / tau)
	for i in range(maxi(seg.size() - int(0.02 * rate), 0), seg.size()):
		seg[i] *= float(seg.size() - i) / (0.02 * rate)
	return seg

# Karplus-Strong plucked string (harp, soft plucks). `soft` 0..1 smooths the initial noise.
func _pluck(rate: int, freq: float, amp: float, length: float, soft := 0.5, decay := 0.996) -> PackedFloat32Array:
	var n := maxi(int(rate / freq), 2)
	var line := PackedFloat32Array()
	line.resize(n)
	for i in n:
		line[i] = rng.randf_range(-1.0, 1.0)
	for _pass in int(soft * 6.0):
		for i in n:
			line[i] = (line[i] + line[(i + 1) % n]) * 0.5
	var seg := _seg(length, rate)
	var idx := 0
	for i in seg.size():
		var cur := line[idx]
		var next_i := (idx + 1) % n
		line[idx] = (cur + line[next_i]) * 0.5 * decay
		seg[i] = cur * amp
		idx = next_i
	seg = _env(seg, rate, swell(0.002, 0.05, length))
	if rate == SFX_RATE:  # Sound effects: a felt-soft string, no bright noise burst on top
		seg = _filter(_filter(seg, rate, 1600.0, 0.7), rate, 1600.0, 0.7)
	return seg

# Whispering: noise through two moving formants, chopped into syllables.
func _whisper(rate: int, length: float, amp: float, syllables := 5.0) -> PackedFloat32Array:
	var noise := _noise(rate, length, 1.0)
	var f1 := rng.randf_range(500.0, 900.0)
	var f2 := rng.randf_range(1400.0, 2600.0)
	var drift := rng.randf() * TAU
	var a := _filter(noise, rate, func(t: float) -> float: return f1 * (1.0 + 0.3 * sin(t * 2.3 + drift)), 0.25, "bp")
	var b := _filter(noise, rate, func(t: float) -> float: return f2 * (1.0 + 0.25 * sin(t * 3.1 + drift)), 0.3, "bp")
	var seg := _seg(length, rate)
	# Syllable envelope: random-length puffs with gaps.
	var gates := PackedFloat32Array()
	var t := 0.0
	while t < length:
		var on := rng.randf_range(0.6, 1.4) / syllables
		gates.append(t)
		gates.append(t + on)
		t += on + rng.randf_range(0.2, 1.0) / syllables
	var g := 0
	for i in seg.size():
		var time := float(i) / rate
		while g + 2 < gates.size() and time > gates[g + 1]:
			g += 2
		var inside := clampf(minf(time - gates[g], gates[g + 1] - time) / 0.04, 0.0, 1.0)
		seg[i] = (a[i] + b[i] * 0.6) * amp * inside
	return _env(seg, rate, swell(0.05, 0.1, length))

func _reverse(seg: PackedFloat32Array) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(seg.size())
	for i in seg.size():
		out[i] = seg[seg.size() - 1 - i]
	return out

func _normalize(seg: PackedFloat32Array, peak: float) -> PackedFloat32Array:
	var top := 0.0
	for v in seg:
		top = maxf(top, absf(v))
	if top > 0.0:
		for i in seg.size():
			seg[i] *= peak / top
	return seg

# `stereo`: `seg` holds interleaved left/right samples.
func _save(seg: PackedFloat32Array, rate: int, path: String, stereo := false) -> void:
	var bytes := PackedByteArray()
	bytes.resize(seg.size() * 2)
	for i in seg.size():
		bytes.encode_s16(i * 2, int(clampf(seg[i], -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = stereo
	wav.data = bytes
	var err := wav.save_to_wav(path)
	if err != OK:
		push_error("Could not save %s: %s" % [path, error_string(err)])

# Every sound effect ends here: a dark top end (lowpassed, pillar "Rounded, never sharp") and a soft
# onset (`onset` s fade-in: 10 ms+ for most, HIT_ONSET for hits), then normalised and saved.
func _sfx(sound_name: String, seg: PackedFloat32Array, peak := SFX_PEAK, onset := SFX_ONSET) -> void:
	seg = _filter(seg, SFX_RATE, SFX_TOP_HZ, 0.7)
	var fade := int(onset * SFX_RATE)
	for i in mini(fade, seg.size()):
		seg[i] *= float(i) / fade
	_save(_normalize(seg, peak), SFX_RATE, SFX_DIR + sound_name + ".wav")


# --- Sound effects --------------------------------------------------------------------------------

func _make_sfx() -> void:
	var r := SFX_RATE

	# The dispel (the most important sound): sigh -> dissolve, all rounded (second listen: the saw
	# shriek and the crackle were too sharp). The warm release chime is its own sound so the game can
	# step its pitch up when several dispels land close together.
	for v in 4:
		var s := _seg(0.6, r)
		var top := rng.randf_range(600.0, 850.0)
		# Sigh: the nightmare's cold breath going out, a falling breathy formant with a faint voice under it.
		var breath := _filter(_noise(r, 0.4, perc(0.03, 0.12, 0.4)), r, glide(top, top * 0.45, 0.35), 0.45, "bp")
		_mix(s, _filter(breath, r, 1500.0, 0.7), r, 0.0, 1.0)
		var voice := _tone(r, 0.35, glide(top * 0.3, top * 0.18, 0.35), perc(0.03, 0.1, 0.35), "tri")
		_mix(s, _filter(voice, r, 900.0, 0.7), r, 0.0, 0.25)
		# Dissolve: a soft, muffled whumpf with an airy swell.
		_mix(s, _tone(r, 0.35, glide(200.0, 100.0, 0.08), perc(0.01, 0.08, 0.35)), r, 0.12, 0.6)
		_mix(s, _filter(_noise(r, 0.3, swell(0.05, 0.2, 0.3)), r, 600.0, 0.7), r, 0.12, 0.35)
		_sfx("dispel_%02d" % (v + 1), s, 0.5)
	# Release: the dream settling, a warm exhale over a low hum in D fading over ~0.5 s. No bell or chime
	# (third listen: chimes read as coins).
	_burn(4)  # What the old chime drew, so later sounds (the approved Firefly Jar) stay identical
	_sfx("dispel_release", _side(func() -> PackedFloat32Array:
		var release := _seg(0.8, r)
		for m in [50, 57]:  # D3 + A3
			_mix(release, _env(_choir(r, hz(m), 0.8), r, swell(0.06, 0.5, 0.8)), r, 0.0, 0.5)
		_mix(release, _filter(_noise(r, 0.7, swell(0.05, 0.5, 0.7)), r, glide(900.0, 350.0, 0.7), 0.6, "bp"), r, 0.0, 0.5)
		return release), 0.45)

	var boss := _seg(3.0, r)
	var roar := _tone(r, 0.8, glide(300.0, 80.0, 0.8), perc(0.04, 0.3, 0.8), "saw")
	_mix(boss, _filter(roar, r, 900.0, 0.5), r, 0.0, 0.5)
	_mix(boss, _tone(r, 0.6, glide(160.0, 70.0, 0.15), perc(0.01, 0.15, 0.6)), r, 0.35, 0.8)  # The whumpf
	_mix(boss, _filter(_noise(r, 0.6, swell(0.1, 0.4, 0.6)), r, 500.0, 0.7), r, 0.35, 0.6)
	for m in [50, 54, 57, 62, 66]:  # D major, the Heartwood wins
		_mix(boss, _bell(r, hz(m), 0.3, 0.9, CHIME, 2.2), r, 0.6 + (m - 50) * 0.012)
	_sfx("dispel_boss", boss)

	var split := _seg(0.6, r)  # Breaking into Sobs: a soft, detuned low chime and a small sniffle
	_mix(split, _bell(r, hz(69), 0.4, 0.15, CHIME, 0.5), r, 0.0)
	_mix(split, _bell(r, hz(69) * 1.025, 0.3, 0.12, CHIME, 0.5), r, 0.01)
	_mix(split, _filter(_noise(r, 0.15, perc(0.03, 0.05, 0.15)), r, 900.0, 0.6, "bp"), r, 0.2, 0.3)
	_sfx("split", split, 0.4)

	# The Heartwood loses a leaf: a dark lunge, the tree groaning, a deep hollow knock as the leaf falls.
	# Cuts through by level and ducking, not brightness.
	var leaf := _seg(1.6, r)
	var whoosh := _noise(r, 0.5, swell(0.3, 0.2, 0.5))
	_mix(leaf, _filter(whoosh, r, func(t: float) -> float: return 200.0 + 1000.0 * sin(PI * t / 0.5), 0.5), r, 0.0, 0.9)
	var groan := _tone(r, 1.1, func(t: float) -> float: return 72.0 - 14.0 * t + 3.0 * sin(t * 23.0), swell(0.1, 0.4, 1.1), "saw")
	_mix(leaf, _filter(groan, r, 500.0, 0.3), r, 0.3, 0.9)
	_mix(leaf, _knock(r, 95.0, 0.09), r, 0.75, 1.0)
	_sfx("leaf_lost", leaf, 0.8)

	# A lump sum of Dew (rest bonus, Omen reward): a soft, low rustle of light. Never a tinkle or coin,
	# and never per kill.
	_burn(24)  # The old tinkle's draws
	_sfx("dew", _side(func() -> PackedFloat32Array:
		var dew := _filter(_noise(r, 1.0, swell(0.25, 0.6, 1.0)), r, glide(350.0, 800.0, 1.0), 0.5, "bp")
		_mix(dew, _filter(_noise(r, 1.0, swell(0.3, 0.6, 1.0)), r, 250.0, 0.7), r, 0.0, 0.6)
		return dew), 0.35)

	# Building and the map.
	var plant := _seg(0.9, r)
	_mix(plant, _filter(_noise(r, 0.5, swell(0.05, 0.3, 0.5)), r, 160.0, 0.6), r, 0.0, 2.5)
	_mix(plant, _tone(r, 0.45, glide(45.0, 70.0, 0.45), swell(0.05, 0.25, 0.45)), r, 0.0, 0.5)
	_mix(plant, _creak(r, 0.4, 35.0, 90.0, 700.0), r, 0.2, 0.7)
	_mix(plant, _pluck(r, hz(62), 0.4, 0.5, 0.7), r, 0.45)
	_sfx("plant", plant)

	var evolve := _seg(1.4, r)
	for i in 4:  # D F# A D: a rising bloom
		_mix(evolve, _bell(r, hz([62, 66, 69, 74][i]), 0.4, 0.35, MUSIC_BOX, 1.0), r, i * 0.07)
	_mix(evolve, _filter(_noise(r, 0.6, swell(0.2, 0.3, 0.6)), r, 1200.0, 0.8), r, 0.0, 0.1)
	_sfx("evolve", evolve)

	var sell := _seg(0.7, r)
	_mix(sell, _filter(_noise(r, 0.5, swell(0.04, 0.3, 0.5)), r, glide(1500.0, 250.0, 0.5), 0.5, "bp"), r, 0.0, 0.8)
	_mix(sell, _pluck(r, hz(55), 0.4, 0.5, 0.8), r, 0.2)
	_sfx("sell", sell, 0.55)

	var invalid := _seg(0.3, r)
	for k in 2:
		_mix(invalid, _knock(r, 170.0 - k * 20.0), r, k * 0.09)
	_sfx("invalid", invalid, 0.5)

	var tend := _seg(0.8, r)  # A soft creak and a low wooden settle
	_mix(tend, _creak(r, 0.45, 20.0, 45.0, 600.0), r, 0.0, 0.8)
	_mix(tend, _filter(_noise(r, 0.4, swell(0.08, 0.25, 0.4)), r, 700.0, 0.7), r, 0.05, 0.3)
	_mix(tend, _knock(r, 120.0, 0.06), r, 0.4, 1.0)
	_sfx("tend", tend, 0.6)

	var move := _seg(0.9, r)
	var grind_rate := rng.randf_range(9.0, 14.0)
	var grind := _noise(r, 0.7, func(t: float) -> float: return swell(0.1, 0.2, 0.7).call(t) * (0.5 + 0.5 * sin(t * grind_rate * TAU) * sin(t * 3.7)))
	_mix(move, _filter(grind, r, 450.0, 0.5), r, 0.0, 2.0)
	_mix(move, _knock(r, 70.0), r, 0.65, 1.2)
	_sfx("move", move, 0.6)

	var shimmer := _seg(0.6, r)
	for i in 5:
		_mix(shimmer, _bell(r, hz(74 + [0, 3, 5, 7, 10][i]), 0.2, 0.15, CHIME, 0.4), r, i * 0.04)
	_sfx("path_shimmer", shimmer, 0.2)

	var trample := _seg(1.0, r)  # A heavy wooden collapse: low, no splinters
	_mix(trample, _knock(r, 55.0, 0.08), r, 0.0, 1.5)
	_mix(trample, _knock(r, 80.0, 0.06), r, 0.09, 1.0)
	_mix(trample, _filter(_noise(r, 0.6, perc(0.01, 0.2, 0.6)), r, 400.0, 0.7), r, 0.0, 1.5)
	_sfx("trample", trample)

	# Warden launches (quiet; the hits below carry the impact).
	for v in 3:
		var puff := _seg(0.35, r)
		_mix(puff, _tone(r, 0.08, glide(420.0 + v * 30.0, 140.0, 0.08), perc(0.004, 0.025, 0.08)), r, 0.0, 0.8)
		_mix(puff, _filter(_noise(r, 0.3, swell(0.03, 0.2, 0.3)), r, 1200.0, 0.8), r, 0.01, 0.5)
		_sfx("attack_spore_%02d" % (v + 1), puff, 0.4)
	for v in 3:  # Sling whip: a soft low swish and a knock
		var sling := _filter(_noise(r, 0.12, swell(0.04, 0.06, 0.12)), r, glide(400.0, 1200.0, 0.12), 0.6, "bp")
		_mix(sling, _knock(r, 190.0 + v * 25.0), r, 0.08, 0.8)
		_sfx("attack_stone_%02d" % (v + 1), sling, 0.4)
	for v in 3:  # A drop falling
		var drop := _seg(0.3, r)
		_mix(drop, _tone(r, 0.09, glide(400.0 + v * 40.0, 900.0, 0.06), perc(0.005, 0.03, 0.09)), r, 0.0)
		_mix(drop, _bell(r, 900.0 + v * 60.0, 0.15, 0.04, CHIME, 0.2), r, 0.05)
		_sfx("attack_water_%02d" % (v + 1), drop, 0.4)
	for v in 3:  # A warm glow swell
		var glow := _seg(0.3, r)
		for m in [69, 76]:
			_mix(glow, _tone(r, 0.25, hz(m + v), swell(0.05, 0.15, 0.25), "tri"), r, 0.0, 0.5)
		_mix(glow, _filter(_noise(r, 0.25, swell(0.05, 0.15, 0.25)), r, 700.0, 0.7), r, 0.0, 0.3)
		_sfx("attack_light_%02d" % (v + 1), glow, 0.3)
	for v in 3:
		var pulse := _knock(r, 110.0 + v * 12.0)
		_mix(pulse, _filter(_noise(r, 0.4, swell(0.02, 0.3, 0.4)), r, 120.0, 0.6), r, 0.0, 3.0)
		_sfx("attack_root_%02d" % (v + 1), pulse, 0.5)
	for v in 3:  # Sprout: a small leafy flick of air (third listen: the plucked tone sounded chiptune)
		_burn(int(r / hz([67, 69, 71][v])))  # The old pluck's draws
		var flick_len := 0.12 + v * 0.02
		_sfx("attack_sprout_%02d" % (v + 1), _side(func() -> PackedFloat32Array:
			var flick := _filter(_noise(r, flick_len, swell(0.02, 0.08, flick_len)), r, [900.0, 1100.0, 1300.0][v], 0.9, "bp")
			_mix(flick, _filter(_noise(r, flick_len, swell(0.02, 0.08, flick_len)), r, 400.0, 0.7), r, 0.0, 0.4)
			return _filter(_filter(flick, r, 1600.0, 0.7), r, 1600.0, 0.7)), 0.3)
	_sfx("attack_acorn", _bell(r, hz(62), 0.4, 0.3, MUSIC_BOX, 0.9), 0.3)

	# UI.
	var click := _knock(r, 420.0, 0.012)  # A soft wooden click
	_mix(click, _knock(r, 220.0, 0.02), r, 0.0, 0.6)
	_sfx("ui_click", click, 0.3)

	var dream := _seg(1.8, r)  # A breath in, then a shimmer
	_mix(dream, _filter(_noise(r, 0.7, swell(0.6, 0.08, 0.7)), r, glide(300.0, 1400.0, 0.7), 0.6, "bp"), r, 0.0, 0.8)
	for i in 6:
		_mix(dream, _bell(r, hz([69, 72, 74, 76, 79, 81][i]), 0.25, 0.4, MUSIC_BOX, 1.1), r, 0.65 + i * 0.05)
	_sfx("dream_open", dream, 0.5)
	_sfx("dream_take_0", _bell(r, hz(62), 0.5, 0.5, MUSIC_BOX, 1.5), 0.45)  # Common: a soft note
	var rare := _seg(2.2, r)
	for m in [62, 65, 69, 74]:
		_mix(rare, _choir(r, hz(m), 2.0), r, 0.0, 0.25)
	_mix(rare, _bell(r, hz(69), 0.4, 0.6, MUSIC_BOX, 1.8), r, 0.0)
	_sfx("dream_take_1", rare, 0.55)
	var legendary := _seg(3.2, r)
	for m in [50, 62, 66, 69, 74, 78]:
		_mix(legendary, _choir(r, hz(m), 3.0), r, 0.0, 0.2)
	for i in 5:
		_mix(legendary, _bell(r, hz([62, 66, 69, 74, 78][i]), 0.35, 0.8, CHIME, 2.5), r, i * 0.08)
	_sfx("dream_take_2", legendary, 0.65)

	_sfx("family_bell", _bell(r, hz(50), 0.9, 1.4, BELL, 5.0), 0.6)  # A deep warm bell

	# The Omen: one soft, low gust (under ~400 Hz), not a roar. Rises and falls with the swell.
	var wind := _noise(r, 3.0, swell(1.0, 1.4, 3.0))
	_sfx("omen_wind", _filter(wind, r, func(t: float) -> float: return 140.0 + 240.0 * sin(PI * t / 3.0), 0.5), 0.4)

	var rest := _seg(3.0, r)  # The exhale: breath out and a warm strum
	_mix(rest, _filter(_noise(r, 1.2, swell(0.1, 0.9, 1.2)), r, glide(1200.0, 300.0, 1.2), 0.6, "bp"), r, 0.0, 0.5)
	for i in 5:
		_mix(rest, _pluck(r, hz([50, 57, 62, 66, 69][i]), 0.4, 2.2, 0.7, 0.998), r, 0.15 + i * 0.06)
	_sfx("rest", rest, 0.5)

	var drift := _seg(2.0, r)  # A drift comes: a low drum and a cold swell
	_mix(drift, _knock(r, 60.0, 0.35), r, 0.0, 1.2)
	var cold := _tone(r, 1.8, hz(38), swell(0.8, 0.8, 1.8), "saw")
	_mix(drift, _filter(cold, r, 300.0, 0.4), r, 0.1, 0.5)
	_mix(drift, _filter(_whisper(r, 1.4, 0.8), r, 1500.0, 0.7), r, 0.3, 0.6)
	_sfx("drift_start", drift, 0.5)

	var act := _seg(4.0, r)  # Act break, leaves regrown: a warm swell and soft rustling
	for m in [50, 57, 62, 66, 69]:
		_mix(act, _tone(r, 3.5, hz(m), swell(1.5, 1.5, 3.5), "tri"), r, 0.0, 0.12)
	_mix(act, _filter(_noise(r, 3.0, func(t: float) -> float: return swell(1.0, 1.0, 3.0).call(t) * (0.5 + 0.5 * sin(t * 13.0))), r, 800.0, 0.7, "bp"), r, 0.3, 0.12)
	_sfx("act_swell", act, 0.55)

	var win := _seg(4.0, r)  # A warm resolving chord
	for i in 6:
		_mix(win, _pluck(r, hz([50, 57, 62, 66, 69, 74][i]), 0.4, 3.5, 0.7, 0.998), r, i * 0.09)
	for m in [62, 66, 69]:
		_mix(win, _bell(r, hz(m), 0.3, 1.0, CHIME, 3.0), r, 0.6)
	_sfx("win", win, 0.7)

	var loss := _seg(5.0, r)  # A slow fall into a single cold note
	for i in 5:
		_mix(loss, _pluck(r, hz([74, 70, 65, 62, 57][i]), 0.4, 1.6, 0.7, 0.997), r, i * 0.35)
	var last := _tone(r, 3.2, func(t: float) -> float: return hz(38) * (1.0 + 0.004 * sin(t * 1.3)), swell(1.0, 1.5, 3.2), "saw")
	_mix(loss, _filter(last, r, 400.0, 0.4), r, 1.6, 0.6)
	_mix(loss, _bell(r, hz(51), 0.3, 1.5, BELL, 3.2), r, 1.7)  # Eb: wrong, cold
	_sfx("loss", loss, 0.7)

	_make_signatures()

	var crit := _seg(0.9, r)  # With the hit and the punch: a soft, low bell (not a high ping)
	_mix(crit, _bell(r, hz(62), 0.6, 0.25, BELL, 0.8), r, 0.0)
	_sfx("crit", crit, 0.4)
	var punch := _tone(r, 0.35, glide(110.0, 46.0, 0.06), perc(0.004, 0.08, 0.35))  # Crit: the extra low punch
	_mix(punch, _filter(_tone(r, 0.05, 420.0, perc(0.004, 0.012, 0.05), "tri"), r, 900.0, 0.7), r, 0.0, 0.4)
	_sfx("crit_punch", punch, 0.6, HIT_ONSET)
	var beam := _seg(0.3, r)  # One soft warm tick of a held beam; pitched up as it ramps. No sizzle.
	for m in [62, 69]:
		_mix(beam, _tone(r, 0.28, hz(m), swell(0.04, 0.15, 0.28), "tri"), r, 0.0, 0.5)
	_sfx("beam", beam, 0.3)

	# Warden hits: rounded tock (300–900 Hz, soft onset) + low body + a lowpassed tail per family.
	# `_dull` = resisted: a softer onset and less body. `hit_full` = weak to it: fuller, not brighter.
	for family in HIT_FAMILIES:
		for v in 3:
			_sfx("hit_%s_%02d" % [family, v + 1], _hit(family, v, false), SFX_PEAK, HIT_ONSET)
		_sfx("hit_%s_dull" % family, _hit(family, 1, true), 0.45, HIT_ONSET)
	for v in 3:
		var full := _tone(r, 0.45, glide(150.0 - v * 10.0, 58.0, 0.06), perc(0.004, 0.11, 0.45))
		_mix(full, _filter(_noise(r, 0.3, perc(0.01, 0.08, 0.3)), r, 300.0, 0.7), r, 0.0, 0.8)
		_sfx("hit_full_%02d" % (v + 1), full, 0.55, HIT_ONSET)

	# A combo found for the first time ever (the Codex card slides in): a short, warm discovery
	# chime, distinct from the dispel's sigh and hum. Two low music-box notes (A4 then D5) over a
	# soft breath of air. Rare (a few per run), so it may be tonal. Own RNG: nothing above changes.
	_sfx("combo_found", _side(func() -> PackedFloat32Array:
		var found := _seg(1.4, r)
		_mix(found, _bell(r, hz(69), 0.4, 0.35, MUSIC_BOX, 1.0), r, 0.0)
		_mix(found, _bell(r, hz(74), 0.45, 0.45, MUSIC_BOX, 1.2), r, 0.12)
		_mix(found, _filter(_noise(r, 0.6, swell(0.1, 0.4, 0.6)), r, 900.0, 0.7), r, 0.0, 0.15)
		return found), 0.4)

	_make_wardens()  # Every Warden's own sounds (last, each with its own RNG, so nothing above shifts)

# One Warden hit. `v` shifts the pitch a little per variant.
func _hit(family: String, v: int, dull: bool) -> PackedFloat32Array:
	if family == "sprout":
		return _twig(v, dull)
	var r := SFX_RATE
	var s := _seg(0.5, r)
	var shift := 1.0 + (v - 1) * 0.06
	# [tock Hz, tock gain, body Hz, body decay s, body gain]
	var shape: Array = {
		"stone": [480.0, 0.9, 70.0, 0.07, 1.3],
		"root": [300.0, 0.5, 48.0, 0.14, 1.3],
		"water": [700.0, 0.6, 110.0, 0.05, 0.9],
		"light": [520.0, 0.4, 90.0, 0.06, 0.9],
		"spore": [360.0, 0.5, 80.0, 0.07, 1.0],
	}[family]
	var tock_hz: float = shape[0] * shift
	var tock := _tone(r, 0.06, glide(tock_hz * 1.3, tock_hz, 0.01), perc(0.004, 0.012, 0.06), "tri")
	_mix(s, _filter(tock, r, 700.0 if dull else 1400.0, 0.7), r, 0.0, shape[1] * (0.4 if dull else 1.0))
	var body_hz: float = shape[2] * shift
	var decay: float = shape[3]
	var body := _tone(r, decay * 6.0, glide(body_hz * 1.8, body_hz, 0.025), perc(0.004, decay, decay * 6.0))
	_mix(s, body, r, 0.0, shape[4] * (0.6 if dull else 1.0))
	match family:
		"stone":  # A hard wood/stone knock over the thud
			_mix(s, _tone(r, 0.05, 900.0 * shift, perc(0.004, 0.01, 0.05), "tri"), r, 0.004, 0.25)
			_mix(s, _filter(_noise(r, 0.12, perc(0.005, 0.03, 0.12)), r, 1000.0, 0.7), r, 0.0, 0.4)
		"root":  # Wooden knock + deep sub rumble, felt more than heard
			_mix(s, _knock(r, 170.0 * shift, 0.03), r, 0.0, 0.5)
			_mix(s, _filter(_noise(r, 0.4, swell(0.02, 0.3, 0.4)), r, 90.0, 0.6), r, 0.0, 3.0)
		"water":  # Droplet, low plunk, a soft spray
			_mix(s, _tone(r, 0.05, glide(600.0 * shift, 1400.0 * shift, 0.03), perc(0.004, 0.012, 0.05)), r, 0.0, 0.4)
			_mix(s, _filter(_noise(r, 0.3, perc(0.02, 0.08, 0.3)), r, 1600.0, 0.7, "bp"), r, 0.01, 0.2)
		"light":  # A warm bloom: a soft fwump of light
			for m in [62, 69]:
				_mix(s, _tone(r, 0.3, hz(m) * shift, swell(0.02, 0.2, 0.3), "tri"), r, 0.0, 0.25)
			_mix(s, _filter(_noise(r, 0.3, swell(0.02, 0.2, 0.3)), r, 800.0, 0.7), r, 0.0, 0.4)
		"spore":  # A full, round puff
			_mix(s, _filter(_noise(r, 0.3, swell(0.02, 0.22, 0.3)), r, 1100.0, 0.8), r, 0.005, 0.8)
	return _filter(s, r, 1200.0 if dull else 3000.0, 0.7)

# The Sprout's hit (third listen, "Organic, never chiptune"): a light wooden twig tap. A short noise
# burst rings a few woody, inharmonic resonances, over a soft low thump of filtered noise. No
# oscillator tone, no pitch sweep; the variants differ by their resonances, not by notes.
const TWIG_RESONANCES := [[380.0, 1070.0, 1780.0], [430.0, 1190.0, 1650.0], [350.0, 960.0, 1900.0]]
func _twig(v: int, dull: bool) -> PackedFloat32Array:
	var r := SFX_RATE
	var s := _seg(0.3, r)
	var burst := _noise(r, 0.02, perc(0.004, 0.004, 0.02))
	burst.resize(int(0.25 * r))  # Silence after the burst, so the resonances ring on
	var gains := [1.0, 0.6, 0.3]
	for k in 3:
		var ring := _filter(burst, r, TWIG_RESONANCES[v][k], 0.04, "bp")  # Narrow bands ring like wood
		ring = _filter(_env(ring, r, perc(0.001, 0.035 / (k + 1), 0.25)), r, TWIG_RESONANCES[v][k], 0.06, "bp")
		_mix(s, ring, r, 0.0, gains[k] * (0.5 if dull and k > 0 else 1.0))
	var thump := _filter(_noise(r, 0.15, perc(0.004, 0.03, 0.15)), r, 160.0, 0.6)
	_mix(s, thump, r, 0.0, 2.5 * (0.6 if dull else 1.0))
	return _filter(_filter(s, r, 1200.0 if dull else 2200.0, 0.7), r, 1200.0 if dull else 2200.0, 0.7)

# --- Warden sound sheet (audio_direction.md, 7b11d5a) ---------------------------------------------
# Every Warden's own launch (attack_<id>), hit (hit_<id>), events (<event>_<id>) and loops
# (loop_<id>). Family = material, tier = size (a final form adds one signature layer), and
# everything is organic: noise through material resonances, thumps and air, no oscillator tones,
# no pitch sweeps, no plucks, no crackle. Only the song family (Bellflower line) is tonal: low,
# soft mallet, notes from D minor pentatonic, never a melody. Sprout and Firefly Jar keep their
# family sounds (attack_/hit_sprout rebuilt on the third listen, attack_/hit_light approved).
# Each Warden draws from its own seeded RNG (`_own`), so adding or changing one never changes another.

const LOOP_LEN := 4.0  # Seconds; loops are crossfaded seamless

func _make_wardens() -> void:
	# Starters (wall line).
	_ws("hit_bramble", 2, 0.35, func(_v: int) -> PackedFloat32Array:  # A dry, low thorn scrape
		return _layers([[_scrape(0.35, 650.0), 1.0], [_thump(0.2, 150.0, 0.03), 0.4]]))
	_ws("hit_honeysuckle", 1, 0.3, func(_v: int) -> PackedFloat32Array:  # A soft, sweet floral sigh
		return _layers([[_air(0.7, 600.0, 0.12, 0.45, 0.9), 1.0], [_soft_hum([62], 0.7), 0.12]]))

	# Sporeling line: soft fungal air.
	_ws("attack_sporeling", 2, 0.3, func(_v: int) -> PackedFloat32Array:
		return _layers([[_air(0.2, 700.0, 0.03, 0.14), 0.6], [_air(0.2, 300.0, 0.03, 0.14), 0.4]]))
	_ws("hit_sporeling", 3, 0.45, func(_v: int) -> PackedFloat32Array: return _puff(0.3, 1.0))
	_ws("attack_driftspore", 2, 0.3, func(_v: int) -> PackedFloat32Array: return _air(0.4, 600.0, 0.1, 0.28))
	_ws("hit_driftspore", 3, 0.45, func(_v: int) -> PackedFloat32Array:  # A double puff, the second smaller
		return _layers([[_puff(0.3, 1.0), 1.0], [_puff(0.25, 0.8), 0.55, 0.09]]))
	_ws("attack_puffball", 2, 0.3, func(_v: int) -> PackedFloat32Array: return _air(0.25, 650.0, 0.04, 0.18))
	_ws("hit_puffball", 3, 0.5, func(_v: int) -> PackedFloat32Array: return _puff(0.35, 1.2))
	_ws("pop_puffball", 1, 0.7, func(_v: int) -> PackedFloat32Array:  # Signature: a deep, soft fwoomp, wide and airy
		return _layers([[_thump(0.6, 90.0, 0.15), 1.0], [_air(0.9, 500.0, 0.02, 0.65, 0.9), 0.6],
			[_rumble(0.9, 200.0, 0.02, 0.55), 0.4]]))
	_ws("attack_bloomcap", 2, 0.45, func(_v: int) -> PackedFloat32Array: return _cap_thup(150.0))
	_ws("cloud_bloomcap", 1, 0.4, func(_v: int) -> PackedFloat32Array: return _exhale(1.2, 450.0))
	_ws("attack_dreamshroom", 2, 0.5, func(_v: int) -> PackedFloat32Array: return _cap_thup(110.0))
	_ws("cloud_dreamshroom", 1, 0.45, func(_v: int) -> PackedFloat32Array: return _exhale(1.4, 380.0))
	_ws("sleep_dreamshroom", 1, 0.4, func(_v: int) -> PackedFloat32Array:  # Signature: a low, yawn-like drone
		return _layers([[_env(_filter(_choir(SFX_RATE, hz(38), 1.6), SFX_RATE, 400.0, 0.7), SFX_RATE, swell(0.35, 0.9, 1.6)), 1.0],
			[_air(1.6, 300.0, 0.4, 0.9), 0.4]]))
	_ws("trap_fairy_ring", 2, 0.3, func(_v: int) -> PackedFloat32Array: return _earth_pops(4))
	_ws("trigger_fairy_ring", 2, 0.55, func(_v: int) -> PackedFloat32Array: return _puff(0.35, 1.2))
	_ws("trap_elf_circle", 2, 0.35, func(_v: int) -> PackedFloat32Array:  # Signature: a faint low hum under the pops
		return _layers([[_earth_pops(5), 1.0], [_soft_hum([50], 0.9), 0.3]]))
	_ws("trigger_elf_circle", 2, 0.65, func(_v: int) -> PackedFloat32Array:
		return _layers([[_puff(0.45, 1.5), 1.0], [_rumble(0.6, 140.0, 0.01, 0.4), 0.4]]))

	# Pebbling line: rock on earth, the heaviest family.
	_ws("attack_pebbling", 2, 0.3, func(_v: int) -> PackedFloat32Array: return _air(0.2, 500.0, 0.06, 0.1, 0.6))
	_ws("hit_pebbling", 3, 0.6, func(_v: int) -> PackedFloat32Array: return _stone_thud(1.0))
	_ws("attack_mossback", 2, 0.4, func(_v: int) -> PackedFloat32Array: return _stone_grunt(160.0))
	_ws("hit_mossback", 3, 0.8, func(_v: int) -> PackedFloat32Array:  # The heaviest hit; moss softens the top
		return _lowpass(_stone_thud(1.7), 1500.0))
	_ws("attack_boulderback", 2, 0.45, func(_v: int) -> PackedFloat32Array: return _stone_grunt(125.0))
	_ws("hit_boulderback", 3, 0.85, func(_v: int) -> PackedFloat32Array:  # Signature: a ground rumble that spreads
		return _layers([[_lowpass(_stone_thud(1.7), 1400.0), 1.0], [_rumble(1.1, 90.0, 0.05, 0.85), 0.6, 0.05]]))
	_ws("attack_standing_stone", 2, 0.45, func(_v: int) -> PackedFloat32Array: return _whoom())
	_ws("hit_standing_stone", 3, 0.7, func(_v: int) -> PackedFloat32Array: return _far_crack())
	_ws("attack_moonstone", 2, 0.45, func(_v: int) -> PackedFloat32Array:
		return _layers([[_whoom(), 1.0], [_air(0.6, 1800.0, 0.2, 0.3, 0.9), 0.15]]))
	_ws("hit_moonstone", 3, 0.7, func(_v: int) -> PackedFloat32Array: return _far_crack())
	_ws("crit_moonstone", 1, 0.45, func(_v: int) -> PackedFloat32Array:  # Signature: a low, glassy bell-stone ring (D3)
		return _layers([[_bell(SFX_RATE, hz(50), 0.6, 0.8, BELL, 2.2), 1.0],
			[_ring(1.2, [hz(50) * 2.32, hz(50) * 3.9], [0.4, 0.15], 0.3), 0.4]]))
	_ws("attack_cairn", 2, 0.4, func(_v: int) -> PackedFloat32Array: return _lob())
	_ws("hit_cairn", 3, 0.65, func(_v: int) -> PackedFloat32Array: return _mortar(6, 0.25))
	_ws("attack_rockslide", 2, 0.4, func(_v: int) -> PackedFloat32Array: return _lob())
	_ws("hit_rockslide", 3, 0.7, func(_v: int) -> PackedFloat32Array:  # Signature: a rolling rubble settle (~1 s)
		return _layers([[_mortar(6, 0.25), 1.0], [_pebbles(14, 1.0, 0.5), 0.5, 0.1], [_rumble(1.1, 150.0, 0.05, 0.9), 0.4]]))

	# Dewdrop line: real water.
	_ws("attack_dewdrop", 2, 0.2, func(_v: int) -> PackedFloat32Array:
		return _lowpass(_layers([[_air(0.1, 700.0, 0.01, 0.06), 0.5], [_ring(0.12, [520.0], [1.0], 0.02), 0.3]]), 1500.0))
	_ws("hit_dewdrop", 3, 0.5, func(_v: int) -> PackedFloat32Array: return _splash(1.0, 0.3))
	_ws("attack_rain_lily", 2, 0.25, func(_v: int) -> PackedFloat32Array:
		return _lowpass(_layers([[_air(0.14, 650.0, 0.01, 0.08), 0.5], [_ring(0.16, [440.0], [1.0], 0.03), 0.4]]), 1500.0))
	_ws("hit_rain_lily", 3, 0.6, func(_v: int) -> PackedFloat32Array: return _splash(1.3, 0.5))
	_ws("attack_mistveil", 2, 0.3, func(_v: int) -> PackedFloat32Array:  # Damp air, no hiss
		return _layers([[_air(0.45, 500.0, 0.1, 0.3), 1.0], [_rumble(0.45, 180.0, 0.1, 0.3), 0.4]]))
	_ws("fog_mistveil", 1, 0.4, func(_v: int) -> PackedFloat32Array:
		return _layers([[_air(1.0, 350.0, 0.2, 0.7), 1.0], [_rumble(1.0, 150.0, 0.2, 0.7), 0.5]]))
	_wloop("loop_mistveil", func() -> PackedFloat32Array: return _breath_bed(420.0, 0.35))  # A very quiet cold breath
	_ws("attack_frostfern", 2, 0.25, func(_v: int) -> PackedFloat32Array: return _lowpass(_air(0.2, 600.0, 0.03, 0.14), 1500.0))
	_ws("hit_frostfern", 3, 0.5, func(_v: int) -> PackedFloat32Array:  # A splash that stiffens: a soft, low ice creak
		return _layers([[_splash(1.0, 0.3), 1.0], [_lowpass(_creak(SFX_RATE, 0.35, 12.0, 25.0, 350.0), 800.0), 0.5, 0.05]]))
	_ws("attack_hoarfrost", 2, 0.3, func(_v: int) -> PackedFloat32Array: return _air(0.3, 700.0, 0.05, 0.2))
	_ws("hit_hoarfrost", 3, 0.6, func(_v: int) -> PackedFloat32Array:  # Signature: a deep, slow frost groan
		return _layers([[_splash(1.1, 0.3), 1.0], [_lowpass(_creak(SFX_RATE, 0.9, 6.0, 14.0, 200.0), 500.0), 0.6, 0.05],
			[_rumble(0.9, 120.0, 0.1, 0.6), 0.3]]))

	# Firefly Jar line: warm air and glow; the approved Firefly Jar (attack_/hit_light) is the template.
	_ws("attack_stormcap", 2, 0.35, func(_v: int) -> PackedFloat32Array: return _glow_swell(0.3))
	_ws("hit_stormcap", 3, 0.6, func(v: int) -> PackedFloat32Array:
		return _layers([[_hit("light", v, false), 1.0], [_air(0.35, 600.0, 0.02, 0.25), 0.3]]))
	_ws("attack_thunderhead", 2, 0.35, func(_v: int) -> PackedFloat32Array: return _glow_swell(0.35))
	_ws("hit_thunderhead", 3, 0.6, func(v: int) -> PackedFloat32Array:
		return _layers([[_hit("light", v, false), 1.0], [_air(0.4, 550.0, 0.02, 0.3), 0.35]]))
	_ws("storm_thunderhead", 1, 0.55, func(_v: int) -> PackedFloat32Array: return _thunder_roll())
	_ws("attack_lanternmoth", 2, 0.2, func(_v: int) -> PackedFloat32Array: return _flutter(0.3, 22.0, 900.0))
	_ws("hit_lanternmoth", 3, 0.5, func(v: int) -> PackedFloat32Array:  # A warm bloom with a faint glow hum
		return _layers([[_hit("light", v, false), 1.0], [_soft_hum([57], 0.5), 0.15]]))
	_wloop("loop_sunpetal", func() -> PackedFloat32Array:  # Warm, airy hum like sunlight through leaves
		return _layers([[_hum_bed([50, 57]), 1.0], [_breath_bed(700.0, 0.4), 0.5]]))
	_wloop("loop_midsummer", func() -> PackedFloat32Array:
		return _layers([[_hum_bed([50, 57, 62]), 1.0], [_breath_bed(700.0, 0.45), 0.5]]))
	_wloop("loop_midsummer_behind", func() -> PackedFloat32Array: return _hum_bed([38, 45]))  # Signature: the lower layer

	# Rootling line: earth and creaking wood, felt more than heard.
	_ws("hit_rootling", 3, 0.55, func(_v: int) -> PackedFloat32Array:
		return _layers([[_lowpass(_creak(SFX_RATE, 0.4, 15.0, 30.0, 250.0), 700.0), 0.4], [_rumble(0.6, 70.0, 0.01, 0.4), 1.0],
			[_thump(0.4, 90.0, 0.08), 0.6]]))
	_ws("attack_rootlight", 2, 0.35, func(_v: int) -> PackedFloat32Array: return _earth_glow(false))
	_wloop("loop_rootlight", func() -> PackedFloat32Array:
		return _layers([[_hum_bed([50]), 0.6], [_breath_bed(200.0, 0.3), 1.0]]))
	_ws("attack_starcave", 2, 0.4, func(_v: int) -> PackedFloat32Array: return _earth_glow(true))
	_wloop("loop_starcave", func() -> PackedFloat32Array:  # Signature: a deep cavern resonance under the hum
		return _layers([[_hum_bed([50]), 0.6], [_breath_bed(200.0, 0.3), 1.0], [_cavern_bed(), 0.5]]))

	# Bellflower line: soft low bells and hums, the one tonal family. Variants = random chord notes.
	var bell_notes := [57, 60, 62, 65]  # A3 C4 D4 F4
	for i in bell_notes.size():
		_w("hit_bellflower_%02d" % (i + 1), _lowpass(_bell(SFX_RATE, hz(bell_notes[i]), 0.5, 0.6, BELL, 2.0), 2500.0), 0.4)
	var drowsy_notes := [50, 53, 57]  # Every 2nd pulse: sleepier and lower
	for i in drowsy_notes.size():
		_w("drowsy_bellflower_%02d" % (i + 1), _lowpass(_bell(SFX_RATE, hz(drowsy_notes[i]), 0.5, 0.9, BELL, 2.6), 1600.0), 0.35)
	var stone_notes := [50, 53, 57]
	for i in stone_notes.size():  # A low stone chime, duller and rounder than the bell
		var f: float = hz(stone_notes[i])
		_w("hit_chime_stone_%02d" % (i + 1), _own("chime_stone%d" % i, func() -> PackedFloat32Array:
			return _lowpass(_layers([[_ring(1.1, [f, f * 2.32, f * 3.9], [1.0, 0.4, 0.15], 0.35), 1.0],
				[_thump(0.2, 160.0, 0.03), 0.3]]), 1800.0)), 0.4)
	var lullaby_notes := [45, 50, 53]
	for i in lullaby_notes.size():  # A deep bell with a long hum tail; signature: a faint hummed voice
		var n: int = lullaby_notes[i]
		_w("hit_lullaby_bell_%02d" % (i + 1), _own("lullaby%d" % i, func() -> PackedFloat32Array:
			return _layers([[_lowpass(_bell(SFX_RATE, hz(n), 0.6, 1.2, BELL, 3.0), 1800.0), 1.0],
				[_soft_hum([n + 12], 2.2), 0.14]])), 0.45)
	_ws("attack_dreamcatcher", 2, 0.25, func(_v: int) -> PackedFloat32Array: return _thread_rustle())
	_ws("hit_dreamcatcher", 3, 0.45, func(_v: int) -> PackedFloat32Array: return _thrum(1.0))
	_ws("attack_great_dreamcatcher", 2, 0.28, func(_v: int) -> PackedFloat32Array: return _thread_rustle())
	_ws("hit_great_dreamcatcher", 3, 0.5, func(_v: int) -> PackedFloat32Array: return _thrum(1.3))
	_ws("shard_great_dreamcatcher", 1, 0.35, func(_v: int) -> PackedFloat32Array:  # A warm, muffled shimmer (notes together, no run)
		return _lowpass(_layers([[_bell(SFX_RATE, hz(62), 0.4, 0.6, MUSIC_BOX, 1.4), 1.0], [_bell(SFX_RATE, hz(69), 0.3, 0.6, MUSIC_BOX, 1.4), 0.8],
			[_air(1.0, 900.0, 0.1, 0.7), 0.3]]), 1500.0))
	_ws("echo_echo_hollow", 2, 0.35, func(_v: int) -> PackedFloat32Array: return _hollow_echo())
	_ws("echo_whispering_hollow", 2, 0.38, func(_v: int) -> PackedFloat32Array:  # Signature: a faint, warm whisper in it
		return _layers([[_hollow_echo(), 1.0], [_lowpass(_whisper(SFX_RATE, 0.9, 1.0, 4.0), 900.0), 0.3, 0.1]]))

	# Acorn line: wood and bark, support, so quiet.
	_ws("hit_acorn", 2, 0.35, func(_v: int) -> PackedFloat32Array: return _wood_knock(190.0))

	# Memory Wardens.
	_wloop("loop_white_stag", func() -> PackedFloat32Array: return _breathing())
	_ws("place_white_stag", 1, 0.5, func(_v: int) -> PackedFloat32Array:  # A distant antler knock and a warm swell
		return _layers([[_lowpass(_wood_knock(260.0), 1200.0), 0.8], [_soft_hum([50, 57], 1.6), 0.4, 0.1]]))
	_ws("attack_pond_keeper", 2, 0.35, func(_v: int) -> PackedFloat32Array:  # A wet tongue flick
		return _layers([[_lowpass(_nburst(0.08, 0.015), 1200.0), 1.0], [_ring(0.12, [300.0], [1.0], 0.02), 0.4],
			[_air(0.1, 900.0, 0.01, 0.06), 0.3]]))
	_ws("hit_pond_keeper", 2, 0.45, func(_v: int) -> PackedFloat32Array:  # A drag through water
		return _layers([[_wobble(_air(0.6, 500.0, 0.05, 0.3), 7.0), 1.0], [_splash(0.6, 0.2), 0.4]]))
	_ws("plop_pond_keeper", 2, 0.4, func(_v: int) -> PackedFloat32Array:
		return _layers([[_ring(0.3, [220.0], [1.0], 0.06), 1.0], [_lowpass(_nburst(0.1, 0.02), 1000.0), 0.5]]))
	_ws("attack_moon_moth", 2, 0.3, func(_v: int) -> PackedFloat32Array: return _flutter(0.55, 5.0, 700.0))
	_ws("hit_moon_moth", 3, 0.55, func(v: int) -> PackedFloat32Array:  # A cool air rush and a muffled glow bloom
		return _layers([[_air(0.4, 900.0, 0.05, 0.3), 0.5], [_lowpass(_hit("light", v, false), 1500.0), 0.8]]))

	# Nestling line: feathers and wingbeats (full game).
	_ws("attack_nestling", 2, 0.3, func(_v: int) -> PackedFloat32Array: return _flutter(0.25, 14.0, 1200.0))
	_ws("hit_nestling", 3, 0.45, func(_v: int) -> PackedFloat32Array: return _feather_strike(1.0, 14.0))
	_ws("attack_wrens_nest", 2, 0.22, func(_v: int) -> PackedFloat32Array: return _flutter(0.18, 18.0, 1300.0))
	_ws("hit_wrens_nest", 3, 0.35, func(_v: int) -> PackedFloat32Array: return _feather_strike(0.7, 18.0))
	_ws("attack_starling_murmuration", 2, 0.4, func(_v: int) -> PackedFloat32Array:  # A soft flock whoosh
		var flock := _air(0.6, 700.0, 0.1, 0.4)
		for k in 5:
			_mix(flock, _flutter(0.45, 11.0 + k * 1.5, 1100.0), SFX_RATE, rng.randf() * 0.12, 0.35)
		return flock)
	_ws("hit_starling_murmuration", 3, 0.4, func(_v: int) -> PackedFloat32Array:  # Three strikes as a soft patter
		return _layers([[_thump(0.15, 170.0, 0.03), 1.0], [_thump(0.15, 190.0, 0.03), 0.8, 0.05], [_thump(0.15, 160.0, 0.03), 0.7, 0.11]]))
	_ws("attack_magpie_perch", 2, 0.35, func(_v: int) -> PackedFloat32Array: return _flutter(0.35, 9.0, 900.0))
	_ws("hit_magpie_perch", 3, 0.5, func(_v: int) -> PackedFloat32Array: return _beak_strike())
	_ws("attack_magpies_hoard", 2, 0.35, func(_v: int) -> PackedFloat32Array: return _flutter(0.35, 9.0, 900.0))
	_ws("hit_magpies_hoard", 3, 0.5, func(_v: int) -> PackedFloat32Array: return _beak_strike())
	_ws("dew_magpies_hoard", 2, 0.3, func(_v: int) -> PackedFloat32Array:  # A soft, low clutter of trinkets (no coin, no bell)
		return _lowpass(_pebbles(6, 0.3, 0.9), 1500.0))
	_ws("attack_hummingbird_bower", 2, 0.2, func(_v: int) -> PackedFloat32Array: return _flutter(0.3, 40.0, 700.0))
	_ws("hit_hummingbird_bower", 3, 0.25, func(_v: int) -> PackedFloat32Array: return _tiny_tap())
	_ws("attack_jewelwing_court", 2, 0.25, func(_v: int) -> PackedFloat32Array:  # Hum from three birds
		return _layers([[_flutter(0.3, 38.0, 700.0), 1.0], [_flutter(0.3, 42.0, 700.0), 0.8], [_flutter(0.3, 46.0, 700.0), 0.6]]))
	_ws("hit_jewelwing_court", 3, 0.25, func(_v: int) -> PackedFloat32Array: return _tiny_tap())
	_ws("crit_jewelwing_court", 2, 0.4, func(_v: int) -> PackedFloat32Array:  # Signature: the Flurry crit, a fuller tap
		return _layers([[_tiny_tap(), 1.0], [_thump(0.12, 200.0, 0.03), 0.7]]))

	# Whirligig line: moving air and spinning wood (full game).
	_ws("hit_whirligig", 3, 0.4, func(_v: int) -> PackedFloat32Array:  # A soft gust that nudges
		return _layers([[_air(0.4, 300.0, 0.05, 0.3, 0.8), 1.0], [_rumble(0.4, 150.0, 0.05, 0.3), 0.3]]))
	_ws("attack_gust", 2, 0.3, func(_v: int) -> PackedFloat32Array: return _spin_up())
	_ws("hit_gust", 2, 0.35, func(_v: int) -> PackedFloat32Array: return _swirl(0.6))
	_ws("attack_zephyr", 2, 0.3, func(_v: int) -> PackedFloat32Array: return _spin_up())
	_ws("hit_zephyr", 2, 0.4, func(_v: int) -> PackedFloat32Array:  # Signature: a longer, sighing breeze
		return _layers([[_swirl(0.6), 1.0], [_air(1.2, 350.0, 0.3, 0.8), 0.5, 0.1]]))
	_wloop("loop_pinwheel", func() -> PackedFloat32Array: return _whirr_bed(14.0, 260.0))
	_ws("hit_pinwheel", 3, 0.25, func(_v: int) -> PackedFloat32Array: return _air_cut(0.12, 900.0))
	_wloop("loop_windmill", func() -> PackedFloat32Array: return _whirr_bed(8.0, 180.0))
	_ws("hit_windmill", 3, 0.3, func(_v: int) -> PackedFloat32Array: return _air_cut(0.16, 750.0))
	_ws("turn_windmill", 2, 0.35, func(_v: int) -> PackedFloat32Array:  # Signature: the mill's low creak each turn
		return _lowpass(_creak(SFX_RATE, 0.8, 8.0, 16.0, 220.0), 700.0))
	_ws("attack_samara", 2, 0.25, func(_v: int) -> PackedFloat32Array: return _seed_whir(25.0))
	_ws("hit_samara", 3, 0.25, func(_v: int) -> PackedFloat32Array: return _air_cut(0.12, 850.0))
	_ws("catch_samara", 2, 0.35, func(_v: int) -> PackedFloat32Array: return _clack())
	_ws("attack_autumn_gale", 2, 0.28, func(_v: int) -> PackedFloat32Array:
		return _layers([[_seed_whir(25.0), 1.0], [_seed_whir(29.0), 0.8, 0.04]]))
	_ws("hit_autumn_gale", 3, 0.25, func(_v: int) -> PackedFloat32Array: return _air_cut(0.12, 850.0))
	_ws("catch_autumn_gale", 2, 0.4, func(_v: int) -> PackedFloat32Array:  # Signature: a gust rising in volume
		return _layers([[_clack(), 1.0], [_air(0.8, 400.0, 0.6, 0.15), 0.5]]))
	_make_ascended()

# Ascended Wardens and the Heartwood Sapling (audio_direction.md 4d1f283). Each Ascended Warden: a very
# quiet presence loop (loop_<id>), its big periodic event (event_<id>, or its hit when it has no
# event), and its ascension swell (ascend_<id>: the family's material, slow and deep). Big = low and
# wide, never bright.
func _make_ascended() -> void:
	# Presence loops.
	_wloop("loop_sporemother", func() -> PackedFloat32Array:  # Slow, deep fungal breathing
		return _layers([[_breathing(), 1.0], [_breath_bed(600.0, 0.6), 0.3]]))
	_wloop("loop_tidecaller", func() -> PackedFloat32Array: return _surf_bed())  # Distant, low surf
	_wloop("loop_stormheart", func() -> PackedFloat32Array:  # A warm, low storm hum
		return _layers([[_hum_bed([38, 45]), 1.0], [_breath_bed(120.0, 0.5), 0.6]]))
	_wloop("loop_old_mountain", func() -> PackedFloat32Array:  # A very low, slow earth groan
		return _layers([[_breath_bed(70.0, 0.6), 1.0], [_slow_creak_bed(2.0, 120.0), 0.4]]))
	_wloop("loop_world_root", func() -> PackedFloat32Array:  # A faint, deep creak of huge roots
		return _layers([[_slow_creak_bed(3.0, 160.0), 1.0], [_breath_bed(90.0, 0.4), 0.6]]))
	_wloop("loop_grandmother_oak", func() -> PackedFloat32Array:  # A slow warm wooden heartbeat, leaves stirring low
		return _layers([[_heartbeat_bed(4), 1.0], [_breath_bed(300.0, 0.3), 0.35]]))
	_wloop("loop_tempest", func() -> PackedFloat32Array:  # The cyclone: a low, rotating wind roar
		return _layers([[_wobble(_breath_bed(260.0, 0.3), 0.5), 1.0], [_breath_bed(90.0, 0.4), 0.6]]))

	# The big events.
	_ws("event_sporemother", 2, 0.75, func(_v: int) -> PackedFloat32Array:  # The spore storm: a soft wind and a rolling fwoomp
		return _layers([[_air(1.8, 450.0, 0.3, 1.2, 0.9), 0.8], [_thump(0.8, 80.0, 0.2), 1.0, 0.2], [_rumble(1.8, 150.0, 0.2, 1.2), 0.5]]))
	_ws("pop_sporemother", 2, 0.6, func(_v: int) -> PackedFloat32Array:  # The Puffball pop, for its crowds
		return _layers([[_thump(0.6, 90.0, 0.15), 1.0], [_air(0.9, 500.0, 0.02, 0.65, 0.9), 0.6], [_rumble(0.9, 200.0, 0.02, 0.55), 0.4]]))
	_ws("event_tidecaller", 2, 0.8, func(_v: int) -> PackedFloat32Array:  # The tide: a long low wave, then a heavy wash
		return _layers([[_rumble(2.4, 300.0, 0.8, 1.2), 1.0], [_air(2.4, 500.0, 0.9, 1.0, 0.8), 0.5], [_splash(2.0, 0.6), 0.7, 1.0]]))
	_ws("event_stormheart", 2, 0.8, func(v: int) -> PackedFloat32Array:  # One big warm bloom over a far thunder roll
		return _layers([[_lowpass(_hit("light", v, false), 1600.0), 1.0], [_glow_swell(1.2), 0.5], [_thunder_roll(), 0.8]]))
	_ws("attack_old_mountain", 2, 0.5, func(_v: int) -> PackedFloat32Array: return _stone_grunt(90.0))
	_ws("hit_old_mountain", 3, 0.9, func(_v: int) -> PackedFloat32Array:  # The heaviest thud, a ground shake, rubble
		return _layers([[_lowpass(_stone_thud(2.2), 1200.0), 1.0], [_rumble(1.2, 70.0, 0.02, 0.9), 0.8], [_pebbles(10, 0.8, 0.5), 0.35, 0.1]]))
	_ws("event_world_root", 2, 0.8, func(_v: int) -> PackedFloat32Array:  # A vast root heave: sub boom and a slow groan
		return _layers([[_thump(1.0, 60.0, 0.3), 1.0], [_lowpass(_creak(SFX_RATE, 1.4, 4.0, 9.0, 160.0), 500.0), 0.6, 0.1],
			[_rumble(1.6, 80.0, 0.1, 1.2), 0.8]]))
	var toll_notes := [38, 45, 50]  # D2 A2 D3
	for i in toll_notes.size():  # The toll: one deep, soft bell with a long hum tail
		var n: int = toll_notes[i]
		_w("event_great_bell_%02d" % (i + 1), _own("great_bell%d" % i, func() -> PackedFloat32Array:
			return _layers([[_lowpass(_bell(SFX_RATE, hz(n), 0.7, 2.2, BELL, 6.0), 1400.0), 1.0], [_soft_hum([n + 12], 5.0), 0.2]])), 0.85)
	_ws("sap_grandmother_oak", 2, 0.4, func(_v: int) -> PackedFloat32Array: return _sap_welling(1.0))  # Never a coin
	_ws("hit_dawnwing", 3, 0.5, func(_v: int) -> PackedFloat32Array:  # A soft, heavy feathered thump
		return _layers([[_thump(0.35, 120.0, 0.08), 1.0], [_air(0.3, 500.0, 0.02, 0.2), 0.35]]))
	_ws("hit_tempest", 3, 0.3, func(_v: int) -> PackedFloat32Array: return _swirl(0.5))  # Soft swirls as it passes

	# Ascending: a slow, deep swell of the family's material (after the evolve bloom, before the first event).
	var materials := {"sporemother": [450.0, 90.0], "tidecaller": [400.0, 120.0], "stormheart": [700.0, 100.0],
		"old_mountain": [250.0, 60.0], "world_root": [300.0, 60.0], "great_bell": [350.0, 80.0],
		"grandmother_oak": [350.0, 90.0], "dawnwing": [500.0, 100.0], "tempest": [400.0, 90.0]}
	for id in materials:
		var m: Array = materials[id]
		_w("ascend_" + id, _own("ascend_" + id, func() -> PackedFloat32Array:
			return _layers([[_air(2.2, m[0], 1.2, 0.9, 0.7), 0.6], [_rumble(2.2, m[1], 1.1, 1.0), 1.0]])), 0.7)

	# The Heartwood Sapling (no attack).
	_ws("plant_heartwood_sapling", 1, 0.7, func(_v: int) -> PackedFloat32Array:  # A big rooting, the earth settling
		return _layers([[_rumble(1.6, 90.0, 0.3, 1.0), 1.0], [_lowpass(_creak(SFX_RATE, 1.0, 10.0, 25.0, 250.0), 700.0), 0.5, 0.3],
			[_pebbles(8, 0.8, 0.4), 0.25, 0.6]]))
	_ws("sap_heartwood_sapling", 2, 0.3, func(_v: int) -> PackedFloat32Array: return _sap_welling(0.7))
	_ws("ripen_heartwood_sapling", 1, 0.4, func(_v: int) -> PackedFloat32Array:  # A slow warm glow swell, a hummed D
		return _layers([[_glow_swell(1.6), 0.7], [_soft_hum([62], 1.6), 0.4]]))
	_ws("wither_heartwood_sapling", 2, 0.3, func(_v: int) -> PackedFloat32Array:  # A low, dry creak (soft, not a crack)
		return _lowpass(_creak(SFX_RATE, 0.7, 8.0, 14.0, 260.0), 700.0))
	_ws("recover_heartwood_sapling", 1, 0.3, func(_v: int) -> PackedFloat32Array: return _exhale(1.2, 400.0))  # A warm exhale
	_make_nurture()

# Nurture and the approved follow-ups (audio_direction.md 1728070). A rank-up is a soft ~0.6 s swell
# of the Warden's family material ending in a gentle settle (nurture_<line>; SoundHooks pitches it
# ~1 semitone lower per rank). Choosing a Focus adds a lean (focus_<name>). Dawnwing gets two synced
# wingbeat loops (calm and busy). The Sapling's offer card and the Great Bell's Static bloom too.
func _make_nurture() -> void:
	var swells := {
		"spore": func() -> PackedFloat32Array: return _air(0.5, 600.0, 0.35, 0.15),  # A spore breath
		"stone": func() -> PackedFloat32Array: return _rumble(0.5, 160.0, 0.35, 0.15),  # Stone settling
		"water": func() -> PackedFloat32Array: return _wobble(_rumble(0.5, 250.0, 0.35, 0.15), 4.0),  # Water welling
		"light": func() -> PackedFloat32Array: return _glow_swell(0.5),  # A warm glow
		"root": func() -> PackedFloat32Array: return _layers([[_rumble(0.5, 120.0, 0.35, 0.15), 1.0], [_lowpass(_creak(SFX_RATE, 0.5, 10.0, 20.0, 260.0), 700.0), 0.5]]),
		"song": func() -> PackedFloat32Array: return _soft_hum([50, 57], 0.5),  # A low bell hum
		"acorn": func() -> PackedFloat32Array: return _air(0.5, 300.0, 0.35, 0.15, 0.6),  # Bark
		"wall": func() -> PackedFloat32Array: return _air(0.5, 300.0, 0.35, 0.15, 0.6),
		"wing": func() -> PackedFloat32Array: return _flutter(0.5, 6.0, 800.0),  # A wingbeat
		"wind": func() -> PackedFloat32Array: return _air(0.5, 400.0, 0.35, 0.15),  # A gust
		"sprout": func() -> PackedFloat32Array: return _air(0.5, 800.0, 0.35, 0.15, 0.9),  # A leafy breath
		"memory": func() -> PackedFloat32Array: return _layers([[_soft_hum([50], 0.5), 0.6], [_air(0.5, 450.0, 0.35, 0.15), 1.0]]),
		"heartwood": func() -> PackedFloat32Array: return _wobble(_rumble(0.5, 230.0, 0.35, 0.15), 3.0),  # Sap
	}
	var settles := {"spore": 120.0, "stone": 100.0, "water": 150.0, "light": 130.0, "root": 90.0, "song": 110.0,
		"acorn": 140.0, "wall": 140.0, "wing": 150.0, "wind": 130.0, "sprout": 170.0, "memory": 110.0, "heartwood": 110.0}
	for line in swells:
		var settle: float = settles[line]
		var wooden: bool = line in ["acorn", "wall", "root", "heartwood", "sprout"]
		_ws("nurture_" + line, 2, 0.35, func(_v: int) -> PackedFloat32Array:
			var settle_layer := _wood_knock(settle * 1.4) if wooden else _thump(0.2, settle, 0.04)
			return _layers([[swells[line].call(), 1.0], [settle_layer, 0.45, 0.45]]))
	# Choosing a Focus at rank III: the material leans toward it (played with the nurture swell).
	_ws("focus_power", 1, 0.4, func(_v: int) -> PackedFloat32Array: return _thump(0.4, 80.0, 0.1))  # Heavier body
	_ws("focus_swift", 1, 0.3, func(_v: int) -> PackedFloat32Array:  # A quick double pulse
		return _layers([[_air(0.12, 600.0, 0.02, 0.08), 1.0], [_air(0.12, 650.0, 0.02, 0.08), 0.8, 0.12]]))
	_ws("focus_reach", 1, 0.3, func(_v: int) -> PackedFloat32Array: return _air(1.2, 500.0, 0.1, 1.0))  # A longer airy tail
	_ws("focus_deep", 1, 0.4, func(_v: int) -> PackedFloat32Array: return _rumble(1.0, 60.0, 0.2, 0.7))  # A lower, slower settle
	# Dawnwing: calm and busy wingbeats, same length and phase, crossfaded by how many nightmares walk.
	_wloop("loop_dawnwing", func() -> PackedFloat32Array: return _wingbeat_bed(1.5))
	_wloop("loop_dawnwing_busy", func() -> PackedFloat32Array: return _wingbeat_bed(3.0))
	# The Heartwood Sapling's offer card: the family bell's warmth without the bell.
	_ws("offer_heartwood_sapling", 1, 0.4, func(_v: int) -> PackedFloat32Array:
		return _layers([[_soft_hum([50, 57, 62], 2.2), 1.0], [_air(2.2, 400.0, 0.8, 1.0), 0.4]]))
	# The Great Bell's toll setting off Static: one soft warm bloom under the tail.
	_ws("bloom_great_bell", 2, 0.45, func(_v: int) -> PackedFloat32Array:
		return _lowpass(_layers([[_glow_swell(1.4), 1.0], [_air(1.4, 600.0, 0.2, 1.0), 0.4]]), 1500.0))
	_make_reactions()
	_make_kinships()
	_make_economy()

# Reactions (audio_direction.md 5594129): two statuses' materials meeting and resolving warm; no
# crackle, zaps or sparkle. reaction_<id>, the shared crown layer (crown_swell), each Crowned
# Reaction's signature (crowned_<id>), the chain swell, surge and Dawnburst (+ its music stinger),
# Smother's loop and the discovery breath. SoundHooks sizes each by how many nightmares it caught.
func _make_reactions() -> void:
	_ws("reaction_thunderclap", 2, 0.75, func(v: int) -> PackedFloat32Array:  # A warm bloom bursting through water
		return _layers([[_splash(1.3, 0.3), 0.7], [_lowpass(_hit("light", v, false), 1500.0), 0.8], [_thunder_roll(), 0.6, 0.1]]))
	_ws("reaction_ignite", 2, 0.75, func(_v: int) -> PackedFloat32Array:  # A deep, soft fwoomp of warm air
		return _layers([[_thump(0.7, 75.0, 0.18), 1.0], [_lowpass(_air(0.9, 450.0, 0.04, 0.7, 0.9), 900.0), 0.8], [_rumble(0.9, 160.0, 0.03, 0.6), 0.4]]))
	_ws("reaction_mushrooming", 2, 0.65, func(_v: int) -> PackedFloat32Array:  # Wet earth bursting, a damp spore exhale
		return _layers([[_earth_pops(6), 1.0], [_thump(0.4, 110.0, 0.08), 0.6], [_exhale(1.0, 420.0), 0.6, 0.2]]))
	_ws("reaction_shatter", 2, 0.7, func(_v: int) -> PackedFloat32Array:  # The ice giving way: a muffled thunk, shards settling
		return _layers([[_lowpass(_ring(0.5, [180.0, 420.0, 700.0], [0.8, 0.4, 0.2], 0.06), 900.0), 1.0], [_thump(0.4, 90.0, 0.09), 0.8],
			[_lowpass(_pebbles(10, 0.6, 0.6), 1200.0), 0.35, 0.08]]))
	_ws("reaction_drown", 2, 0.6, func(_v: int) -> PackedFloat32Array:  # A slow sink: a low gulp, a sleepy exhale bubbling away
		return _layers([[_wobble(_ring(0.5, [150.0, 230.0], [0.8, 0.4], 0.12), 6.0), 1.0], [_thump(0.4, 100.0, 0.1), 0.6],
			[_wobble(_exhale(1.2, 380.0), 5.0), 0.6, 0.25]]))
	_ws("reaction_pinned", 2, 0.5, func(_v: int) -> PackedFloat32Array:  # A low, tight held breath: a wooden clench, a glow hum
		return _layers([[_air(0.35, 500.0, 0.25, 0.08), 0.5], [_lowpass(_wood_knock(150.0), 900.0), 1.0, 0.25], [_soft_hum([57], 0.9), 0.3, 0.25]]))
	_ws("reaction_smother", 1, 0.5, func(_v: int) -> PackedFloat32Array:  # The spore breath pressed tight
		return _layers([[_lowpass(_air(0.8, 350.0, 0.05, 0.5), 600.0), 1.0], [_thump(0.3, 100.0, 0.06), 0.5]]))
	_wloop("loop_smother", func() -> PackedFloat32Array:  # A muffled, low smothering hum while it lasts
		return _layers([[_hum_bed([43]), 0.7], [_breath_bed(300.0, 0.4), 1.0]]))
	_ws("reaction_lightning_rod", 2, 0.6, func(v: int) -> PackedFloat32Array:  # A warm pull: a reversed swell landing in a low bloom
		var out := _seg(1.2, SFX_RATE)
		_mix(out, _normalize(_reverse(_glow_swell(0.6)), 1.0), SFX_RATE, 0.0, 0.8)
		_mix(out, _normalize(_lowpass(_hit("light", v, false), 1400.0), 1.0), SFX_RATE, 0.55, 1.0)
		return out)

	# Crowned Reactions: the shared crown (a slow, warm, low hummed swell in key) + each signature.
	_ws("crown_swell", 1, 0.5, func(_v: int) -> PackedFloat32Array: return _soft_hum([50, 57, 62], 1.8))
	_ws("crowned_tempest", 1, 0.8, func(_v: int) -> PackedFloat32Array:  # Thunder and fwoomp rolling into one swell (no wind)
		return _layers([[_thunder_roll(), 1.0], [_thump(0.7, 75.0, 0.18), 0.7, 0.3], [_rumble(2.0, 140.0, 0.4, 1.2), 0.5, 0.5]]))
	_ws("crowned_still_pool", 1, 0.55, func(_v: int) -> PackedFloat32Array:  # A deep, glassy-calm water hush
		return _layers([[_rumble(1.8, 300.0, 0.5, 1.2), 1.0], [_ring(1.6, [90.0, 135.0], [0.5, 0.3], 0.6), 0.4]]))
	_ws("crowned_fever_dream", 1, 0.55, func(_v: int) -> PackedFloat32Array:  # A warm, dizzy, wavering exhale spreading
		return _wobble(_exhale(1.8, 450.0), 2.5))
	_ws("crowned_starfall", 1, 0.85, func(_v: int) -> PackedFloat32Array:  # Bolts drawn in, then the deepest warm boom
		var out := _seg(3.0, SFX_RATE)
		for k in 3:
			_mix(out, _normalize(_reverse(_air(0.9 - k * 0.15, 500.0 + k * 150.0, 0.05, 0.6)), 1.0), SFX_RATE, 0.1 + k * 0.15, 0.5)
		_mix(out, _layers([[_thump(1.0, 50.0, 0.3), 1.0], [_rumble(1.8, 70.0, 0.02, 1.3), 0.8], [_glow_swell(1.4), 0.5]]), SFX_RATE, 1.0, 1.0)
		return out)
	_ws("crowned_avalanche", 1, 0.8, func(_v: int) -> PackedFloat32Array:  # A rolling ice-and-stone rumble moving outward
		return _layers([[_rumble(2.0, 110.0, 0.1, 1.5), 1.0], [_lowpass(_pebbles(18, 1.6, 0.6), 1200.0), 0.4, 0.1], [_thump(0.6, 80.0, 0.15), 0.7]]))
	_ws("crowned_prismstorm", 1, 0.7, func(v: int) -> PackedFloat32Array:  # Shatter's thunk + warm blooms scattering
		var out := _layers([[_lowpass(_ring(0.5, [180.0, 420.0], [0.8, 0.4], 0.06), 900.0), 1.0], [_thump(0.4, 90.0, 0.09), 0.7]])
		for k in 4:
			_mix(out, _normalize(_lowpass(_hit("light", (v + k) % 3, false), 1400.0), 1.0), SFX_RATE, 0.1 + k * 0.09, 0.45 - k * 0.07)
		return out)
	_ws("crowned_nightbloom", 1, 0.45, func(_v: int) -> PackedFloat32Array:  # Two low sung notes in key, very soft
		return _layers([[_soft_hum([57], 1.0), 1.0], [_soft_hum([62], 1.2), 0.9, 0.7], [_breath_bed(300.0, 0.4), 0.2]]))
	_ws("crowned_fairy_circle", 1, 0.55, func(_v: int) -> PackedFloat32Array:  # A ring of 8 quick, soft pops
		var out := _seg(1.0, SFX_RATE)
		for k in 8:
			_mix(out, _layers([[_thump(0.08, 280.0, 0.012), 1.0], [_ring(0.08, [500.0 + 40.0 * k], [1.0], 0.01), 0.2]]), SFX_RATE, k * 0.06, 0.8)
		return out)

	# Chains: fuller and warmer each link, never higher (no rising chime: coins).
	_ws("chain_swell", 2, 0.45, func(_v: int) -> PackedFloat32Array:
		return _layers([[_soft_hum([50, 57], 1.0), 0.8], [_air(1.0, 400.0, 0.3, 0.6), 0.5]]))
	_ws("chain_surge", 1, 0.7, func(_v: int) -> PackedFloat32Array:  # Chain 5: a short warm swell, a soft low boom
		return _layers([[_soft_hum([50, 57, 62], 1.4), 0.7], [_thump(0.8, 65.0, 0.2), 1.0, 0.2], [_air(1.4, 400.0, 0.4, 0.8), 0.4]]))
	_ws("chain_dawnburst", 1, 0.9, func(_v: int) -> PackedFloat32Array:  # Chain 10: a deep, warm boom of light
		return _layers([[_thump(1.4, 45.0, 0.4), 1.0], [_rumble(2.4, 70.0, 0.02, 1.8), 0.8], [_air(2.4, 450.0, 0.2, 1.8, 0.7), 0.6],
			[_glow_swell(2.0), 0.4]]))
	_ws("stinger_dawnburst", 1, 0.6, func(_v: int) -> PackedFloat32Array:  # A sustained warm D major chord, 2–3 s
		var chord := _seg(3.0, SFX_RATE)
		for m in [38, 50, 54, 57, 62]:
			_mix(chord, _choir(SFX_RATE, hz(m), 3.0), SFX_RATE, 0.0, 0.3)
		_mix(chord, _lowpass(_bell(SFX_RATE, hz(50), 0.5, 1.2, BELL, 3.0), 1400.0), SFX_RATE, 0.0, 0.5)
		return _env(_lowpass(chord, 1800.0), SFX_RATE, swell(0.25, 1.2, 3.0)))

	# Discovery (first time a Reaction, Crowned or chain goes off): the Dream-screen breath in, a soft shimmer.
	_ws("discover_reaction", 1, 0.45, func(_v: int) -> PackedFloat32Array:
		var out := _normalize(_lowpass(_filter(_noise(SFX_RATE, 0.7, swell(0.6, 0.08, 0.7)), SFX_RATE, glide(300.0, 1400.0, 0.7), 0.6, "bp"), 1800.0), 1.0)
		for k in 3:
			_mix(out, _lowpass(_bell(SFX_RATE, hz([62, 66, 69][k]), 0.25, 0.4, MUSIC_BOX, 1.1), 1600.0), SFX_RATE, 0.65, 0.5)
		return out)

func _wingbeat_bed(beats: float) -> PackedFloat32Array:  # Phase 0, a whole number of beats per loop: in sync
	var length := LOOP_LEN + 0.5
	var n := _noise(SFX_RATE, length, func(t: float) -> float: return pow(maxf(sin(TAU * beats * t), 0.0), 2.0))
	return _normalize(_lowpass(_lowpass(n, 500.0), 500.0), 1.0)

func _sap_welling(size: float) -> PackedFloat32Array:  # Sap welling up: slow, low, liquid
	return _layers([[_wobble(_rumble(1.2 * size, 250.0, 0.4, 0.6), 3.0), 1.0], [_ring(0.8 * size, [180.0, 260.0], [0.5, 0.3], 0.25), 0.4, 0.2],
		[_air(1.0 * size, 350.0, 0.3, 0.6), 0.3]])

func _surf_bed() -> PackedFloat32Array:  # Two slow waves per loop, far away
	var length := LOOP_LEN + 0.5
	var n := _noise(SFX_RATE, length, func(t: float) -> float: return 0.3 + 0.7 * pow(sin(PI * 2.0 * t / LOOP_LEN), 2.0))
	return _normalize(_lowpass(_lowpass(n, 300.0), 300.0), 1.0)

func _slow_creak_bed(clicks_hz: float, body: float) -> PackedFloat32Array:
	return _normalize(_lowpass(_creak(SFX_RATE, LOOP_LEN + 0.5, clicks_hz, clicks_hz * 1.6, body), 600.0), 1.0)

func _heartbeat_bed(beats: int) -> PackedFloat32Array:
	var out := _seg(LOOP_LEN + 0.5, SFX_RATE)
	for k in beats:
		var at := k * LOOP_LEN / beats
		_mix(out, _wood_knock(110.0), SFX_RATE, at, 1.0)
		_mix(out, _wood_knock(95.0), SFX_RATE, at + 0.28, 0.6)
	return _normalize(_lowpass(out, 800.0), 1.0)

# Saves `count` variants of `id` (id_01.. when more than one), each from its own seeded RNG.
func _ws(id: String, count: int, peak: float, make: Callable) -> void:
	for v in count:
		var seg := _own("%s#%d" % [id, v], make.bind(v))
		_w(id if count == 1 else "%s_%02d" % [id, v + 1], seg, peak)

func _w(id: String, seg: PackedFloat32Array, peak: float) -> void:
	var onset := HIT_ONSET if id.begins_with("hit_") else SFX_ONSET
	_sfx(id, seg, peak, onset)

func _own(key: String, make: Callable) -> PackedFloat32Array:
	var main := rng
	rng = RandomNumberGenerator.new()
	rng.seed = hash(key)
	var out: PackedFloat32Array = make.call()
	rng = main
	return out

# A seamless loop (LOOP_LEN s): rendered longer, the tail crossfaded into the start. Loops skip the
# onset fade (it would click at the seam) and are saved as loop_<id>.wav.
func _wloop(id: String, make: Callable) -> void:
	var seg := _own(id, make)
	var loop_samples := int(LOOP_LEN * SFX_RATE)
	seg.resize(maxi(seg.size(), loop_samples + int(0.5 * SFX_RATE)))
	var tail := seg.size() - loop_samples
	for i in tail:
		var w := float(i) / tail
		seg[i] = seg[i] * w + seg[loop_samples + i] * (1.0 - w)
	seg.resize(loop_samples)
	_save(_normalize(_filter(seg, SFX_RATE, SFX_TOP_HZ, 0.7), 0.4), SFX_RATE, SFX_DIR + id + ".wav")

# Mixes [seg, gain, (at s)] layers into one, each normalised first so gains mean what they say.
func _layers(parts: Array) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for p in parts:
		_mix(out, _normalize(p[0], 1.0), SFX_RATE, p[2] if p.size() > 2 else 0.0, p[1])
	return out

func _lowpass(seg: PackedFloat32Array, cutoff: float) -> PackedFloat32Array:
	return _filter(seg, SFX_RATE, cutoff, 0.7)

# --- Organic building blocks (noise shaped by materials; no oscillator as the main sound) ---------

func _nburst(length: float, tau: float) -> PackedFloat32Array:
	return _noise(SFX_RATE, length, perc(0.004, tau, length))

# A short noise burst ringing a few narrow resonances: the voice of wood, stone or a hollow.
func _ring(length: float, freqs: Array, gains: Array, tau: float) -> PackedFloat32Array:
	var burst := _nburst(0.03, 0.004)
	burst.resize(int(length * SFX_RATE))
	var out := _seg(length, SFX_RATE)
	for k in freqs.size():
		var ring := _filter(burst, SFX_RATE, freqs[k], 0.03, "bp")
		ring = _env(ring, SFX_RATE, perc(0.001, tau / (1.0 + 0.3 * k), length))
		_mix(out, _normalize(ring, 1.0), SFX_RATE, 0.0, gains[k])
	return out

# A low thump: noise lowpassed twice (the weight), no tone.
func _thump(length: float, cutoff: float, tau: float) -> PackedFloat32Array:
	var n := _noise(SFX_RATE, length, perc(0.004, tau, length))
	return _normalize(_filter(_filter(n, SFX_RATE, cutoff, 0.6), SFX_RATE, cutoff, 0.6), 1.0)

func _air(length: float, center: float, attack: float, release: float, damp := 0.8) -> PackedFloat32Array:
	var n := _noise(SFX_RATE, length, swell(attack, release, length))
	# Lowpassed above ~2× the band, so a wide band of air never leaks brightness
	return _normalize(_lowpass(_lowpass(_filter(n, SFX_RATE, center, damp, "bp"), minf(center * 2.2, 2400.0)), minf(center * 2.2, 2400.0)), 1.0)

func _rumble(length: float, cutoff: float, attack: float, release: float) -> PackedFloat32Array:
	var n := _noise(SFX_RATE, length, swell(attack, release, length))
	return _normalize(_filter(_filter(n, SFX_RATE, cutoff, 0.6), SFX_RATE, cutoff, 0.6), 1.0)

# Wingbeats: noise gated by a soft beat of `beats` per second, lowpassed.
func _flutter(length: float, beats: float, cutoff: float) -> PackedFloat32Array:
	var phase := rng.randf()
	var n := _noise(SFX_RATE, length, func(t: float) -> float:
		return pow(maxf(sin(TAU * (beats * t + phase)), 0.0), 2.0) * swell(0.03, 0.1, length).call(t))
	return _normalize(_filter(_filter(n, SFX_RATE, cutoff, 0.7), SFX_RATE, cutoff, 0.7), 1.0)

# A rough scrape: grainy noise through a low band.
func _scrape(length: float, center: float) -> PackedFloat32Array:
	var grain := rng.randf_range(60.0, 90.0)
	var n := _noise(SFX_RATE, length, func(t: float) -> float:
		return (0.5 + 0.5 * absf(sin(t * grain + sin(t * 23.0)))) * swell(0.02, 0.2, length).call(t))
	return _normalize(_lowpass(_filter(n, SFX_RATE, center, 0.6, "bp"), 1500.0), 1.0)

func _wobble(seg: PackedFloat32Array, rate_hz: float) -> PackedFloat32Array:
	return _env(seg, SFX_RATE, func(t: float) -> float: return 0.6 + 0.4 * sin(TAU * rate_hz * t))

# A low hummed tone (only for the few "hum" layers the sheet names), lowpassed.
func _soft_hum(notes: Array, length: float) -> PackedFloat32Array:
	var out := _seg(length, SFX_RATE)
	for n in notes:
		_mix(out, _choir(SFX_RATE, hz(n), length), SFX_RATE, 0.0, 1.0)
	return _env(_lowpass(out, 700.0), SFX_RATE, swell(minf(0.2, length * 0.3), minf(0.5, length * 0.5), length))

func _puff(length: float, size: float) -> PackedFloat32Array:
	return _layers([[_air(length, 900.0, 0.01, length * 0.7, 0.9), 0.6], [_thump(length, 120.0 / size, 0.05 * size), 0.8]])

func _cap_thup(cutoff: float) -> PackedFloat32Array:
	return _layers([[_thump(0.25, cutoff, 0.04), 1.0], [_ring(0.2, [220.0, 470.0], [0.5, 0.3], 0.03), 0.4]])

func _exhale(length: float, center: float) -> PackedFloat32Array:
	return _layers([[_air(length, center, 0.15, length * 0.75, 0.7), 0.7], [_rumble(length, 120.0, 0.2, length * 0.65), 0.4]])

func _earth_pops(count: int) -> PackedFloat32Array:
	var out := _seg(0.5, SFX_RATE)
	for k in count:
		_mix(out, _layers([[_thump(0.08, 300.0, 0.012), 1.0], [_ring(0.08, [rng.randf_range(450.0, 750.0)], [1.0], 0.01), 0.25]]),
			SFX_RATE, rng.randf() * 0.4, rng.randf_range(0.5, 1.0))
	return out

func _stone_thud(size: float) -> PackedFloat32Array:
	var base := 110.0 / size
	return _layers([[_thump(0.35 * size, base, 0.07 * size), 1.0],
		[_ring(0.15, [310.0 / size, 620.0 / size, 1040.0 / size], [0.5, 0.3, 0.15], 0.015), 0.45],
		[_rumble(0.3 * size, 250.0, 0.005, 0.12 * size), 0.3]])

func _stone_grunt(cutoff: float) -> PackedFloat32Array:
	return _layers([[_rumble(0.35, cutoff, 0.15, 0.15), 0.7], [_ring(0.3, [180.0, 390.0], [0.4, 0.2], 0.05), 0.3]])

func _whoom() -> PackedFloat32Array:  # A stone slung far
	return _layers([[_air(0.6, 250.0, 0.2, 0.3, 0.7), 1.0], [_rumble(0.6, 120.0, 0.2, 0.3), 0.5]])

func _far_crack() -> PackedFloat32Array:  # Stone on stone, far away
	return _lowpass(_layers([[_ring(0.4, [260.0, 540.0, 930.0, 1400.0], [0.6, 0.5, 0.35, 0.2], 0.03), 1.0],
		[_thump(0.4, 90.0, 0.08), 0.7]]), 1200.0)

func _lob() -> PackedFloat32Array:  # A stone lifted and lobbed: a low grunt and an arcing rush of air
	return _layers([[_rumble(0.25, 150.0, 0.08, 0.12), 0.6], [_air(0.5, 400.0, 0.15, 0.25), 0.6, 0.1]])

func _pebbles(count: int, spread: float, gain: float) -> PackedFloat32Array:
	var out := _seg(spread + 0.1, SFX_RATE)
	for k in count:
		var at := spread * pow(rng.randf(), 1.6)  # Denser at the start, settling out
		_mix(out, _ring(0.08, [rng.randf_range(500.0, 1100.0)], [1.0], 0.01), SFX_RATE, at,
			gain * rng.randf_range(0.3, 1.0) * (1.0 - at / (spread + 0.1)))
	return _lowpass(out, 2000.0)

func _mortar(pebbles: int, spread: float) -> PackedFloat32Array:  # Stone landing among many
	return _layers([[_thump(0.45, 100.0, 0.09), 1.0], [_pebbles(pebbles, spread, 0.8), 0.25, 0.01]])

func _splash(size: float, spray: float) -> PackedFloat32Array:  # A water slap, a low plunk, a spray tail
	return _layers([[_lowpass(_nburst(0.12 * size, 0.02 * size), 1800.0), 1.0],
		[_ring(0.3 * size, [260.0 / size], [1.0], 0.05 * size), 0.6],
		[_lowpass(_air(0.3 + spray, 1100.0, 0.01, 0.2 + spray * 0.5, 0.8), 1600.0), 0.12 + spray * 0.25]])

func _glow_swell(length: float) -> PackedFloat32Array:  # The Firefly Jar's warm swell, heavier
	var glow := _seg(length, SFX_RATE)
	for m in [62, 69]:
		_mix(glow, _tone(SFX_RATE, length, hz(m), swell(0.05, length * 0.6, length), "tri"), SFX_RATE, 0.0, 0.5)
	_mix(glow, _normalize(_lowpass(_noise(SFX_RATE, length, swell(0.05, length * 0.6, length)), 700.0), 1.0), SFX_RATE, 0.0, 0.5)
	return glow

func _thunder_roll() -> PackedFloat32Array:  # Low and distant, no crack
	var roll := _rumble(2.2, 110.0, 0.3, 1.5)
	roll = _env(roll, SFX_RATE, func(t: float) -> float: return 0.6 + 0.4 * absf(sin(t * 3.1 + sin(t * 1.7))))
	return _layers([[roll, 1.0], [_rumble(2.2, 300.0, 0.4, 1.3), 0.3]])

func _earth_glow(cavern: bool) -> PackedFloat32Array:
	var parts := [[_rumble(0.9, 200.0, 0.2, 0.55), 0.6], [_soft_hum([50], 0.9), 0.2]]
	if cavern:
		parts.append([_ring(1.2, [110.0, 173.0, 260.0], [0.4, 0.3, 0.2], 0.4), 0.3])
	return _layers(parts)

func _thread_rustle() -> PackedFloat32Array:
	return _layers([[_flutter(0.3, 16.0, 1400.0), 0.4], [_air(0.3, 1100.0, 0.03, 0.2), 0.3]])

func _thrum(size: float) -> PackedFloat32Array:  # A low, woven thrum (D2 A2 D3)
	return _lowpass(_layers([[_ring(0.6 * size, [73.4, 110.0, 146.8], [0.6, 0.4, 0.25], 0.2 * size), 1.0],
		[_thump(0.3, 110.0, 0.05), 0.4]]), 1200.0)

func _hollow_echo() -> PackedFloat32Array:  # From inside a log: hollow, lowpassed
	return _lowpass(_layers([[_ring(0.8, [180.0, 410.0, 690.0], [0.6, 0.4, 0.2], 0.12), 1.0], [_air(0.8, 400.0, 0.1, 0.5), 0.2]]), 900.0)

func _wood_knock(freq: float) -> PackedFloat32Array:
	return _layers([[_ring(0.25, [freq, freq * 2.7, freq * 4.6], [0.7, 0.35, 0.15], 0.04), 1.0], [_thump(0.2, 140.0, 0.03), 0.5]])

func _feather_strike(size: float, beats: float) -> PackedFloat32Array:  # A muffled strike, then the flutter home
	return _layers([[_thump(0.2 * size, 160.0 / size, 0.04 * size), 1.0], [_air(0.15, 800.0, 0.01, 0.1), 0.3],
		[_flutter(0.3 * size, beats, 1000.0), 0.35, 0.12]])

func _beak_strike() -> PackedFloat32Array:  # A strike and a faint beak tap
	return _layers([[_feather_strike(1.1, 9.0), 1.0], [_ring(0.08, [900.0, 1500.0], [0.5, 0.3], 0.012), 0.3]])

func _tiny_tap() -> PackedFloat32Array:
	return _layers([[_thump(0.06, 400.0, 0.01), 1.0], [_ring(0.05, [rng.randf_range(650.0, 800.0)], [1.0], 0.01), 0.3]])

func _spin_up() -> PackedFloat32Array:  # Air gathering (a gently moving band of noise, no tone)
	var n := _noise(SFX_RATE, 0.4, swell(0.25, 0.1, 0.4))
	return _normalize(_lowpass(_filter(n, SFX_RATE, glide(300.0, 700.0, 0.4), 0.7, "bp"), 1400.0), 1.0)

func _swirl(length: float) -> PackedFloat32Array:
	return _wobble(_air(length, 500.0, 0.15, length * 0.6), 3.0)

func _air_cut(length: float, center: float) -> PackedFloat32Array:
	return _lowpass(_air(length, center, 0.01, length * 0.7, 0.7), 1600.0)

func _seed_whir(rate_hz: float) -> PackedFloat32Array:  # A spinning maple seed
	var n := _noise(SFX_RATE, 0.5, func(t: float) -> float:
		return (0.5 + 0.5 * sin(TAU * rate_hz * t)) * swell(0.05, 0.3, 0.5).call(t))
	return _normalize(_filter(n, SFX_RATE, 700.0, 0.7, "bp"), 1.0)

func _clack() -> PackedFloat32Array:  # A light wooden clack
	return _layers([[_ring(0.1, [600.0, 1150.0, 1800.0], [0.6, 0.4, 0.2], 0.015), 1.0], [_thump(0.08, 250.0, 0.015), 0.4]])

# --- Loop beds (LOOP_LEN + 0.5 s, crossfaded by _wloop) --------------------------------------------

func _hum_bed(notes: Array) -> PackedFloat32Array:
	var length := LOOP_LEN + 0.5
	var out := _seg(length, SFX_RATE)
	for n in notes:
		_mix(out, _choir(SFX_RATE, hz(n), length), SFX_RATE, 0.0, 1.0)
	return _normalize(_lowpass(out, 800.0), 1.0)

func _breath_bed(center: float, depth: float) -> PackedFloat32Array:
	var length := LOOP_LEN + 0.5
	var n := _noise(SFX_RATE, length, func(t: float) -> float: return 1.0 - depth + depth * sin(TAU * t / LOOP_LEN))
	return _normalize(_lowpass(_filter(n, SFX_RATE, center, 0.8, "bp"), 1200.0), 1.0)

func _cavern_bed() -> PackedFloat32Array:
	var length := LOOP_LEN + 0.5
	var n := _noise(SFX_RATE, length, 1.0)
	var out := _seg(length, SFX_RATE)
	for f in [55.0, 110.0, 165.0]:
		_mix(out, _normalize(_filter(n, SFX_RATE, f, 0.05, "bp"), 1.0), SFX_RATE, 0.0, 0.5)
	return _normalize(out, 1.0)

func _whirr_bed(rate_hz: float, center: float) -> PackedFloat32Array:  # Spinning wood
	var length := LOOP_LEN + 0.5
	var n := _noise(SFX_RATE, length, func(t: float) -> float: return 0.4 + 0.6 * pow(absf(sin(PI * rate_hz * t)), 2.0))
	return _normalize(_lowpass(_filter(n, SFX_RATE, center, 0.5, "bp"), 900.0), 1.0)

func _breathing() -> PackedFloat32Array:  # The White Stag: one slow warm breath per loop
	var length := LOOP_LEN + 0.5
	var n := _noise(SFX_RATE, length, func(t: float) -> float: return pow(sin(PI * t / LOOP_LEN), 2.0))
	return _layers([[_filter(_filter(n, SFX_RATE, 300.0, 0.6), SFX_RATE, 300.0, 0.6), 1.0], [_hum_bed([50]), 0.12]])

# Nightmare signature sounds (played when one enters, and on their special moments).
func _make_signatures() -> void:
	var r := SFX_RATE
	_sfx("sig_shade", _taps(r, 0.7, 14.0, 300.0, 500.0), 0.35)  # Soft, muffled skittering

	var husk := _seg(1.4, r)  # Creaking bark, heavy steps
	_mix(husk, _creak(r, 0.8, 18.0, 30.0, 400.0), r, 0.0, 0.8)
	for k in 2:
		_mix(husk, _knock(r, 60.0, 0.15), r, 0.4 + k * 0.6, 0.9)
	_sfx("sig_husk", husk, 0.5)

	_sfx("sig_lurker", _filter(_whisper(r, 1.5, 1.0, 6.0), r, 1500.0, 0.7), 0.3)  # Only a faint whisper

	var phantom := _seg(1.6, r)  # Breathy whoosh, reversed choir
	var choir := _seg(1.2, r)
	for m in [62, 63, 69]:
		_mix(choir, _choir(r, hz(m), 1.2), r, 0.0, 0.3)
	_mix(phantom, _reverse(_env(choir, r, perc(0.02, 0.4, 1.2))), r, 0.0, 0.7)
	_mix(phantom, _filter(_noise(r, 1.0, swell(0.6, 0.3, 1.0)), r, glide(300.0, 1400.0, 1.0), 0.5, "bp"), r, 0.4, 0.6)
	_sfx("sig_phantom", phantom, 0.4)

	var growl := _tone(r, 0.9, func(t: float) -> float: return 78.0 + 6.0 * sin(t * 4.0), func(t: float) -> float: return swell(0.15, 0.3, 0.9).call(t) * (0.5 + 0.5 * absf(sin(t * 31.0 + sin(t * 7.0)))), "saw")
	_sfx("sig_hound", _filter(growl, r, 600.0, 0.4), 0.5)  # Low growl

	var howl := _tone(r, 1.6, func(t: float) -> float: return 300.0 + 180.0 * sin(PI * minf(t / 1.2, 1.0)) , swell(0.2, 0.6, 1.6), "saw")
	_sfx("hound_howl", _filter(howl, r, 1200.0, 0.3), 0.45)

	var procession := _seg(2.0, r)  # Distant chain-clink and a slow drum
	for k in 5:
		_mix(procession, _bell(r, 1000.0 + rng.randf() * 300.0, 0.3, 0.05, [[1.0, 1.0, 1.0], [1.47, 0.6, 0.8], [2.09, 0.4, 0.6]], 0.2), r, 0.1 + k * 0.23 + rng.randf() * 0.05)
	for k in 2:
		_mix(procession, _knock(r, 75.0, 0.3), r, k * 1.0, 0.8)
	_sfx("sig_procession", procession, 0.4)

	var sleepy := _tone(r, 1.4, glide(210.0, 150.0, 1.4), swell(0.3, 0.6, 1.4), "tri")  # A sleepy hum
	_mix(sleepy, _filter(_noise(r, 1.2, swell(0.4, 0.6, 1.2)), r, 900.0, 0.5), r, 0.1, 0.4)
	_sfx("sig_sleepwalker", _filter(sleepy, r, 900.0, 0.7), 0.35)

	var sob := _seg(1.5, r)  # Faint sobbing
	for k in 3:
		var hitch := _tone(r, 0.25, func(t: float) -> float: return 330.0 - 60.0 * t + 12.0 * sin(t * 40.0), perc(0.02, 0.08, 0.25), "saw")
		_mix(sob, _filter(hitch, r, 1100.0, 0.3), r, k * 0.33, 0.6)
		_mix(sob, _filter(_noise(r, 0.2, perc(0.05, 0.08, 0.2)), r, 1200.0, 0.6, "bp"), r, k * 0.33 + 0.15, 0.4)
	_sfx("sig_mourner", sob, 0.35)

	var widow := _taps(r, 0.9, 30.0, 250.0, 420.0)  # A soft chitter of low taps and a whisper
	_mix(widow, _filter(_whisper(r, 0.9, 0.4, 9.0), r, 1500.0, 0.7), r, 0.0)
	_sfx("sig_widow", widow, 0.4)

	var stag := _seg(2.2, r)  # Deep bellow, a low roaring hush of ghost-fire
	var bellow := _tone(r, 1.6, func(t: float) -> float: return 95.0 - 20.0 * t + 4.0 * sin(t * 9.0), swell(0.2, 0.7, 1.6), "saw")
	_mix(stag, _filter(bellow, r, func(t: float) -> float: return 300.0 + 400.0 * sin(PI * t / 1.6), 0.25), r, 0.0)
	_mix(stag, _filter(_noise(r, 2.0, swell(0.4, 0.6, 2.0)), r, 450.0, 0.7), r, 0.1, 0.8)
	_sfx("sig_stag", stag, 0.7)

	var hag := _seg(1.8, r)  # Wet gurgling laugh
	for k in 4:
		var heh := _tone(r, 0.14, glide(260.0, 220.0, 0.14), perc(0.01, 0.05, 0.14), "saw")
		_mix(hag, _filter(heh, r, 900.0, 0.3), r, 0.3 + k * 0.17, 0.7)
	_mix(hag, _bubbles(r, 1.6, 18.0), r, 0.0, 0.8)
	_sfx("sig_hag", hag, 0.6)

	_sfx("hag_sink", _bubbles(r, 0.9, 30.0), 0.5)
	var splash := _filter(_noise(r, 0.6, perc(0.01, 0.15, 0.6)), r, glide(2000.0, 500.0, 0.6), 0.6)
	_mix(splash, _bubbles(r, 0.5, 20.0), r, 0.1, 0.5)
	_sfx("hag_rise", splash, 0.55)

# Soft, muffled taps (skittering legs): little low sine blips at random times, no noise.
func _taps(rate: int, length: float, per_second: float, low_hz: float, high_hz: float) -> PackedFloat32Array:
	var seg := _seg(length, rate)
	var t := rng.randf_range(0.0, 0.5) / per_second
	while t < length - 0.05:
		_mix(seg, _tone(rate, 0.04, rng.randf_range(low_hz, high_hz), perc(0.004, 0.01, 0.04)), rate, t, rng.randf_range(0.4, 1.0))
		t += rng.randf_range(0.3, 1.7) / per_second
	return _env(seg, rate, swell(0.1, 0.25, length))

# Wood creaking: a slowing/speeding train of tiny clicks through a resonance.
func _creak(rate: int, length: float, from_hz: float, to_hz: float, body: float) -> PackedFloat32Array:
	var seg := _seg(length, rate)
	var phase := 0.0
	for i in seg.size():
		var t := float(i) / rate
		phase += lerpf(from_hz, to_hz, t / length) / rate
		if phase >= 1.0:
			phase -= 1.0
			seg[i] = rng.randf_range(0.5, 1.0)
	seg = _filter(seg, rate, body, 0.08, "bp")
	return _env(seg, rate, swell(0.05, 0.1, length))

# A soft wooden knock: a pitched thump with a rounded tap on top (no click).
func _knock(rate: int, freq: float, tau := 0.04) -> PackedFloat32Array:
	var length := tau * 6.0
	var seg := _tone(rate, length, glide(freq * 1.6, freq, 0.02), perc(0.003, tau, length))
	var tap := _tone(rate, 0.03, minf(freq * 3.0, 900.0), perc(0.003, 0.006, 0.03), "tri")
	_mix(seg, _filter(tap, rate, 1200.0, 0.7), rate, 0.0, 0.4)
	return seg

# A hummed "ooh": a soft saw through a vowel formant, with slow vibrato.
func _choir(rate: int, freq: float, length: float) -> PackedFloat32Array:
	var voice := _seg(length, rate)
	for detune in [-0.004, 0.0, 0.005]:
		var vib := rng.randf() * TAU
		_mix(voice, _tone(rate, length, func(t: float) -> float: return freq * (1.0 + detune + 0.004 * sin(t * 5.0 * TAU + vib)), swell(0.3, 0.5, length), "saw"), rate, 0.0, 0.33)
	return _filter(_filter(voice, rate, 500.0, 0.5, "bp"), rate, 1800.0, 0.7)

func _bubbles(rate: int, length: float, per_second: float) -> PackedFloat32Array:
	var seg := _seg(length, rate)
	var t := 0.0
	while t < length - 0.06:
		var f := rng.randf_range(200.0, 700.0)
		_mix(seg, _tone(rate, 0.05, glide(f, f * 2.2, 0.05), perc(0.003, 0.015, 0.05)), rate, t, rng.randf_range(0.3, 1.0))
		t += rng.randf_range(0.2, 1.8) / per_second
	return _env(seg, rate, swell(0.1, 0.2, length))


# --- Music (act 1: synced stems) ------------------------------------------------------------------

func _make_music() -> void:
	rng.seed = 9091  # Its own seed, so adding sound effects doesn't change the music
	var r := MUSIC_RATE
	var total := LOOP + TAIL

	# Warm base: music box melody over a harp waltz and a soft pad.
	var base := _seg(total, r)
	for bar in BARS:
		var chord: Array = CHORDS[bar]
		var root: int = chord[0]
		var third: int = chord[1]
		var t0 := bar * BEATS_PER_BAR * BEAT
		_mix(base, _pluck(r, hz(root), 0.5, 2.6, 0.7, 0.998), r, t0)
		_mix(base, _pluck(r, hz(root + 7), 0.35, 2.0, 0.6, 0.998), r, t0 + BEAT)
		_mix(base, _pluck(r, hz(root + 12 + third), 0.3, 2.0, 0.6, 0.998), r, t0 + 2.0 * BEAT)
		for m in [root + 12, root + 12 + third, root + 19]:
			_mix(base, _tone(r, BEAT * 3.2, hz(m), swell(0.8, 0.8, BEAT * 3.2), "tri"), r, t0, 0.035)
	for note in MELODY:
		_mix(base, _bell(r, hz(note[1] + 12), 0.3, 0.7, MUSIC_BOX, 2.5), r, note[0] * BEAT)
	_music("mus_act1_base", base, 0.6)

	# Dread 1: a detuned low drone and a slow pulse.
	var dread1 := _seg(total, r)
	for detune in [0.997, 1.003]:
		var drone := _tone(r, total, hz(38) * detune, func(t: float) -> float: return 0.5 + 0.2 * sin(t * TAU / LOOP * 2.0), "saw")
		_mix(dread1, _filter(drone, r, func(t: float) -> float: return 220.0 + 80.0 * sin(t * TAU / LOOP * 4.0), 0.5), r, 0.0, 0.5)
	for beat in BARS * BEATS_PER_BAR:
		if beat % BEATS_PER_BAR == 0:
			_mix(dread1, _tone(r, 0.6, glide(70.0, 42.0, 0.3), perc(0.005, 0.15, 0.6)), r, beat * BEAT, 0.7)
	_music("mus_act1_dread1", dread1, 0.5, true)

	# Dread 2: whispers and tremolo strings on a cold minor second.
	var dread2 := _seg(total, r)
	for m in [62, 63]:
		var strings := _tone(r, total, hz(m), func(t: float) -> float: return 0.3 * (0.6 + 0.4 * sin(t * 7.5 * TAU)), "saw")
		_mix(dread2, _filter(strings, r, 1400.0, 0.6), r, 0.0, 0.5)
	var at := 0.5
	while at < LOOP - 1.0:
		_mix(dread2, _whisper(r, rng.randf_range(1.0, 2.2), 1.0), r, at, rng.randf_range(0.8, 1.6))
		at += rng.randf_range(1.5, 3.5)
	_music("mus_act1_dread2", dread2, 0.45, true)

	# Heartbeat (5 leaves or fewer): lub-dub on every beat.
	var heart := _seg(total, r)
	for beat in BARS * BEATS_PER_BAR:
		_mix(heart, _tone(r, 0.25, glide(65.0, 45.0, 0.12), perc(0.005, 0.06, 0.25)), r, beat * BEAT)
		_mix(heart, _tone(r, 0.2, glide(55.0, 40.0, 0.1), perc(0.005, 0.05, 0.2)), r, beat * BEAT + 0.28, 0.7)
	_music("mus_act1_heartbeat", heart, 0.7)

	# Boss drums: heavy toms on the waltz.
	var drums := _seg(total, r)
	for beat in BARS * BEATS_PER_BAR:
		var accent := beat % BEATS_PER_BAR == 0
		_mix(drums, _tom(r, 58.0 if accent else 80.0), r, beat * BEAT, 1.0 if accent else 0.55)
		if beat % 6 == 5:
			_mix(drums, _tom(r, 90.0), r, beat * BEAT + BEAT * 0.5, 0.45)
	_music("mus_act1_boss", drums, 0.6)

	# Ambience: a spring-dusk forest edge, felt more than heard (stereo). Low wind in gusts with calm
	# stretches between them, and rare soft events: a far owl, a low creak, a whisper. No hiss and no
	# leaf rustles (the second listen: they hurt the ear).
	var left := _seg(total, r)
	var right := _seg(total, r)
	var gust := func(t: float) -> float:
		var loop_t := fposmod(t, LOOP)  # Wraps, so the loop's crossfaded tail matches its start
		var g := 0.0
		for span in AMB_GUSTS:
			var x: float = (loop_t - span[0]) / span[1]
			if x > 0.0 and x < 1.0:
				g = maxf(g, pow(sin(PI * x), 2.0))
		return g
	for channel in [left, right]:  # Separate noise per side: a wide, soft bed
		var wind := _noise(r, total, func(t: float) -> float: return 0.12 + 0.88 * gust.call(t))
		_mix(channel, _filter(wind, r, func(t: float) -> float: return 110.0 + 270.0 * gust.call(t), 0.5), r, 0.0, 1.0)
	for hoot_at in [3.0, 12.5]:
		var hoot := _seg(1.0, r)
		for k in 2:
			_mix(hoot, _tone(r, 0.35, glide(410.0, 360.0, 0.35), swell(0.08, 0.2, 0.35)), r, k * 0.5)
		_pan_mix(left, right, hoot, hoot_at, 0.1, rng.randf_range(0.2, 0.8))
	_pan_mix(left, right, _filter(_creak(r, 0.9, 10.0, 22.0, 300.0), r, 600.0, 0.7), 6.0, 0.25, 0.7)
	_pan_mix(left, right, _filter(_whisper(r, 1.5, 1.0), r, 1200.0, 0.7), 8.0, 0.2, 0.2)
	_pan_mix(left, right, _filter(_whisper(r, 1.2, 1.0), r, 1200.0, 0.7), 16.5, 0.16, 0.8)
	_music_stereo("amb_act1", left, right, 0.5)

	_make_boss_themes()

# One theme per boss (audio_direction.md "Music"): a stem that replaces the generic boss drums while
# that boss walks (mus_act1_boss_<boss>), and a warm counter-melody that enters below half health
# (mus_act1_boss_<boss>_warm). Same 20 s loop, key and waltz as the act's stems, so they stay in sync.
# Each has its own seeded RNG, so the act stems above never change.
func _make_boss_themes() -> void:
	var r := MUSIC_RATE
	var total := LOOP + TAIL
	var beats := BARS * BEATS_PER_BAR
	# The Hollow Stag: heavy drums and a bowed bass.
	_music("mus_act1_boss_stag", _own("boss_stag", func() -> PackedFloat32Array:
		var s := _seg(total, r)
		for beat in beats:
			var accent := beat % BEATS_PER_BAR == 0
			_mix(s, _tom(r, 50.0 if accent else 72.0), r, beat * BEAT, 1.0 if accent else 0.5)
		for bar in BARS:
			var root: int = CHORDS[bar][0] - 12
			var bow := _tone(r, BEAT * 3.3, hz(root) * 1.002, swell(0.5, 0.6, BEAT * 3.3), "saw")
			_mix(s, _filter(bow, r, 380.0, 0.5), r, bar * BEATS_PER_BAR * BEAT, 0.5)
		return s), 0.6)
	# The Mire Hag: bubbling low reeds and a crooked waltz (the second beat always a little late).
	_music("mus_act1_boss_hag", _own("boss_hag", func() -> PackedFloat32Array:
		var s := _seg(total, r)
		for bar in BARS:
			var t0 := bar * BEATS_PER_BAR * BEAT
			var root: int = CHORDS[bar][0]
			var reed := _tone(r, BEAT * 3.2, hz(root - 12), func(t: float) -> float:
				return swell(0.2, 0.4, BEAT * 3.2).call(t) * (0.7 + 0.3 * sin(t * 37.0 + sin(t * 11.0))), "square")
			_mix(s, _filter(reed, r, 520.0, 0.35), r, t0, 0.35)
			_mix(s, _knock(r, 70.0, 0.12), r, t0, 0.8)
			_mix(s, _knock(r, 95.0, 0.08), r, t0 + BEAT * 1.28, 0.5)  # Crooked
			_mix(s, _knock(r, 95.0, 0.08), r, t0 + BEAT * 2.0, 0.45)
		return s), 0.55)
	# The Moth Queen: a tremolo shimmer on a cold minor second over a soft wingbeat pulse.
	_music("mus_act1_boss_moth", _own("boss_moth", func() -> PackedFloat32Array:
		var s := _seg(total, r)
		for m in [57, 58]:
			var strings := _tone(r, total, hz(m), func(t: float) -> float: return 0.3 * (0.55 + 0.45 * sin(t * 6.0 * TAU)), "saw")
			_mix(s, _filter(strings, r, 900.0, 0.6), r, 0.0, 0.4)
		var wings := _noise(r, total, func(t: float) -> float: return pow(maxf(sin(TAU * t / BEAT), 0.0), 3.0))
		_mix(s, _filter(_filter(wings, r, 400.0, 0.7), r, 400.0, 0.7), r, 0.0, 2.0)
		return s), 0.5, true)
	# The Hollow Oak: deep wooden drums and a low hummed drone with a slow creak.
	_music("mus_act1_boss_oak", _own("boss_oak", func() -> PackedFloat32Array:
		var s := _seg(total, r)
		for beat in beats:
			if beat % BEATS_PER_BAR != 1:
				_mix(s, _knock(r, 48.0 if beat % BEATS_PER_BAR == 0 else 62.0, 0.2), r, beat * BEAT, 1.0 if beat % BEATS_PER_BAR == 0 else 0.6)
		for m in [38, 45]:
			_mix(s, _filter(_choir(r, hz(m), total), r, 500.0, 0.7), r, 0.0, 0.5)
		_mix(s, _filter(_creak(r, total, 1.5, 3.0, 180.0), r, 600.0, 0.7), r, 0.0, 0.4)
		return s), 0.6)
	# The warm counter-melodies (the player is winning): chord tones in the warm instruments, never the
	# boss's own colour. Stag: a warm low horn; Hag: a harp; Moth Queen: a breathy flute; Oak: a choir.
	for boss in ["stag", "hag", "moth", "oak"]:
		_music("mus_act1_boss_%s_warm" % boss, _own("warm_" + boss, func() -> PackedFloat32Array:
			var s := _seg(total, r)
			for bar in BARS:
				var root: int = CHORDS[bar][0]
				var third: int = CHORDS[bar][1]
				var t0 := bar * BEATS_PER_BAR * BEAT
				var notes := [root + 12 + third, root + 19] if bar % 2 == 0 else [root + 19, root + 24]
				for k in 2:
					var n: int = notes[k]
					var at := t0 + k * BEAT * 1.5
					var length := BEAT * 1.6
					match boss:
						"stag":
							_mix(s, _filter(_tone(r, length, hz(n - 12), swell(0.15, 0.5, length), "saw"), r, 700.0, 0.6), r, at, 0.35)
						"hag":
							_mix(s, _pluck(r, hz(n), 0.4, length * 1.5, 0.6, 0.998), r, at)
						"moth":
							_mix(s, _tone(r, length, hz(n), swell(0.12, 0.5, length), "tri"), r, at, 0.3)
							_mix(s, _filter(_noise(r, length, swell(0.1, 0.4, length)), r, hz(n) * 2.0, 0.5, "bp"), r, at, 0.08)
						"oak":
							_mix(s, _choir(r, hz(n - 12), length), r, at, 0.5)
			return s), 0.45)

# Trims to exactly one loop and saves. Notes (`sustained` false): the tail past the loop end is
# added back onto the start, so they ring across the loop point. Drones and beds (`sustained`):
# the tail is crossfaded into the start instead, so there's no seam and no doubled level.
func _music(sound_name: String, seg: PackedFloat32Array, peak: float, sustained := false) -> void:
	_fold_loop(seg, sustained)
	_save(_normalize(seg, peak), MUSIC_RATE, MUSIC_DIR + sound_name + ".wav")

# A stereo bed (the ambience): both sides folded as sustained, normalised together.
func _music_stereo(sound_name: String, left: PackedFloat32Array, right: PackedFloat32Array, peak: float) -> void:
	var size := maxi(left.size(), right.size())
	left.resize(size)
	right.resize(size)
	_fold_loop(left, true)
	_fold_loop(right, true)
	var top := 0.0
	for i in left.size():
		top = maxf(top, maxf(absf(left[i]), absf(right[i])))
	var gain := peak / top if top > 0.0 else 1.0
	var both := PackedFloat32Array()
	both.resize(left.size() * 2)
	for i in left.size():
		both[i * 2] = left[i] * gain
		both[i * 2 + 1] = right[i] * gain
	_save(both, MUSIC_RATE, MUSIC_DIR + sound_name + ".wav", true)

func _fold_loop(seg: PackedFloat32Array, sustained: bool) -> void:
	var loop_samples := int(LOOP * MUSIC_RATE)
	var tail := seg.size() - loop_samples
	for i in tail:
		if sustained:
			var w := float(i) / tail
			seg[i] = seg[i] * w + seg[loop_samples + i] * (1.0 - w)
		else:
			seg[i] += seg[loop_samples + i]
	seg.resize(loop_samples)

# Mixes a mono `src` into a stereo pair at `at` s; `pan` 0 = left, 1 = right (equal power).
func _pan_mix(left: PackedFloat32Array, right: PackedFloat32Array, src: PackedFloat32Array, at: float,
		gain: float, pan: float) -> void:
	_mix(left, src, MUSIC_RATE, at, gain * cos(pan * PI / 2.0))
	_mix(right, src, MUSIC_RATE, at, gain * sin(pan * PI / 2.0))

func _tom(rate: int, freq: float) -> PackedFloat32Array:
	var seg := _tone(rate, 0.6, glide(freq * 1.8, freq, 0.08), perc(0.002, 0.14, 0.6))
	_mix(seg, _filter(_noise(rate, 0.08, perc(0.001, 0.02, 0.08)), rate, 900.0, 0.6), rate, 0.0, 0.5)
	return seg

# Kinships (tower_design.md "Kinships", 834fdd0): rewarding but quiet, rounded. A two-note chord per
# family when kin bond (its own interval and colour, D minor pentatonic, low), a gentle chime when a
# bond grows, a very quiet chime for the Harmony strike, and a warm swell when a family is Whole.
func _make_kinships() -> void:
	var bonds := {  # family: [two notes, colour]
		"spore": [[50, 57], "hum"], "stone": [[50, 53], "stone"], "water": [[53, 60], "bell"],
		"light": [[57, 62], "glow"], "root": [[38, 45], "hum"], "song": [[62, 65], "bell"],
		"acorn": [[55, 62], "wood"], "wing": [[60, 65], "flute"], "wind": [[55, 60], "hum"],
	}
	for family in bonds:
		var notes: Array = bonds[family][0]
		var colour: String = bonds[family][1]
		_w("kin_bond_" + family, _own("kin_bond_" + family, func() -> PackedFloat32Array:
			var out := _seg(1.8, SFX_RATE)
			for k in 2:
				_mix(out, _normalize(_kin_note(notes[k], colour), 1.0), SFX_RATE, k * 0.12, 1.0 - k * 0.15)
			return _lowpass(out, 1800.0)), 0.4)
	_w("kin_bond", _own("kin_bond", func() -> PackedFloat32Array:  # A family without its own colour
		return _layers([[_kin_note(50, "bell"), 1.0], [_kin_note(57, "bell"), 0.85, 0.12]])), 0.4)
	_ws("kin_stage_up", 1, 0.4, func(_v: int) -> PackedFloat32Array:  # A gentle chime: a bond grows
		return _lowpass(_layers([[_bell(SFX_RATE, hz(62), 0.4, 0.5, MUSIC_BOX, 1.4), 1.0],
			[_bell(SFX_RATE, hz(69), 0.3, 0.5, MUSIC_BOX, 1.4), 0.8, 0.1], [_air(1.2, 500.0, 0.2, 0.8), 0.2]]), 1800.0))
	_ws("harmony_strike", 3, 0.25, func(v: int) -> PackedFloat32Array:  # A very quiet soft chime in combat
		return _lowpass(_bell(SFX_RATE, hz([62, 65, 69][v]), 0.3, 0.2, MUSIC_BOX, 0.6), 1500.0))
	_ws("whole_tree", 1, 0.6, func(_v: int) -> PackedFloat32Array:  # A family made Whole: a warm swell
		var chord := _seg(3.2, SFX_RATE)
		for m in [38, 50, 57, 62, 65]:
			_mix(chord, _choir(SFX_RATE, hz(m), 3.2), SFX_RATE, 0.0, 0.3)
		return _layers([[_env(_lowpass(chord, 1200.0), SFX_RATE, swell(1.0, 1.4, 3.2)), 1.0], [_air(3.2, 400.0, 1.2, 1.4), 0.35],
			[_lowpass(_bell(SFX_RATE, hz(50), 0.5, 1.2, BELL, 3.0), 1200.0), 0.4, 0.8]]))

func _kin_note(midi: int, colour: String) -> PackedFloat32Array:  # One soft note in a family's colour
	match colour:
		"hum":
			return _soft_hum([midi], 1.6)
		"stone":
			var f := hz(midi)
			return _lowpass(_ring(1.6, [f, f * 2.32], [1.0, 0.3], 0.5), 1400.0)
		"glow":
			return _env(_tone(SFX_RATE, 1.6, hz(midi), swell(0.08, 1.0, 1.6), "tri"), SFX_RATE, swell(0.05, 1.0, 1.6))
		"wood":
			var f := hz(midi)
			return _lowpass(_ring(1.2, [f, f * 2.7], [1.0, 0.25], 0.35), 1400.0)
		"flute":
			return _layers([[_env(_tone(SFX_RATE, 1.5, hz(midi), swell(0.15, 0.9, 1.5), "tri"), SFX_RATE, swell(0.1, 0.9, 1.5)), 1.0],
				[_air(1.5, hz(midi) * 2.0, 0.15, 0.9), 0.15]])
	return _lowpass(_bell(SFX_RATE, hz(midi), 0.5, 0.7, BELL, 1.6), 1600.0)  # "bell"

# Economy (screens_ui.md "Support and economy feedback", ad1a055). Dew stays "never a tinkle, bell or
# coin" (third listen): a caught drop is a soft low droplet; the harvest at a rest is a warm pour of
# low droplets and welling water settling into a low hum, fuller with the amount (never higher); the
# Wellspring's interest is a gentle ripple.
func _make_economy() -> void:
	_ws("dew_catch", 3, 0.25, func(_v: int) -> PackedFloat32Array:
		return _lowpass(_layers([[_ring(0.2, [rng.randf_range(380.0, 460.0)], [1.0], 0.03), 1.0],
			[_lowpass(_nburst(0.03, 0.006), 1000.0), 0.3]]), 1500.0))
	_ws("harvest", 1, 0.55, func(_v: int) -> PackedFloat32Array:
		var pour := _seg(2.2, SFX_RATE)
		var t := 0.0
		while t < 1.3:  # Droplets pouring, denser as the catch runs in
			_mix(pour, _ring(0.2, [rng.randf_range(260.0, 480.0)], [1.0], 0.03), SFX_RATE, t, rng.randf_range(0.4, 0.8))
			t += rng.randf_range(0.03, 0.12) * (1.4 - t * 0.6)
		return _lowpass(_layers([[pour, 0.8], [_wobble(_rumble(1.6, 250.0, 0.3, 0.8), 3.0), 0.6],
			[_soft_hum([50, 57], 1.4), 0.4, 0.9]]), 1600.0))
	_ws("interest_ripple", 1, 0.35, func(_v: int) -> PackedFloat32Array:
		return _lowpass(_layers([[_wobble(_air(1.0, 400.0, 0.2, 0.6), 4.0), 1.0], [_ring(0.3, [300.0], [1.0], 0.05), 0.4, 0.2],
			[_ring(0.3, [360.0], [1.0], 0.05), 0.3, 0.45]]), 1500.0))
	# A close call (run_design.md "spend or save"): a nightmare on the last stretch. A soft tension cue,
	# the Heartwood's low tremble under a cold breath; quiet, never an alarm.
	_ws("close_call", 2, 0.4, func(_v: int) -> PackedFloat32Array:
		return _layers([[_wobble(_rumble(0.9, 90.0, 0.08, 0.6), 7.0), 1.0],
			[_lowpass(_creak(SFX_RATE, 0.6, 6.0, 10.0, 180.0), 500.0), 0.4, 0.1], [_air(0.9, 300.0, 0.15, 0.6), 0.35]]))
