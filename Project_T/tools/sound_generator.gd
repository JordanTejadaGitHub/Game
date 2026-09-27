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

# Sum of decaying partials (music box, bell, chime). `decay` = the fundamental's time constant.
func _bell(rate: int, freq: float, amp: float, decay: float, partials: Array, length := -1.0) -> PackedFloat32Array:
	if length < 0.0:
		length = decay * 5.0
	var seg := _seg(length, rate)
	for p in partials:
		var f: float = freq * p[0]
		if f > rate * 0.45:
			continue
		var a: float = amp * p[1]
		var tau: float = decay * p[2]
		var phase := rng.randf() * TAU
		var step := TAU * f / rate
		for i in seg.size():
			var t := float(i) / rate
			seg[i] += sin(phase + step * i) * a * minf(t / 0.003, 1.0) * exp(-t / tau)
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
	return _env(seg, rate, swell(0.002, 0.05, length))

# Sparse random clicks (crackle of ice, dry leaves, embers).
func _crackle(rate: int, length: float, per_second: float, amp, bright := 3000.0) -> PackedFloat32Array:
	var seg := _seg(length, rate)
	var i := 0
	while i < seg.size():
		var click_len := int(rate * rng.randf_range(0.001, 0.006))
		var a := _val(amp, float(i) / rate) * rng.randf_range(0.3, 1.0)
		for k in click_len:
			if i + k < seg.size():
				seg[i + k] += rng.randf_range(-1.0, 1.0) * a * (1.0 - float(k) / click_len)
		i += int(rate * rng.randf_range(0.2, 1.8) / per_second)
	return _filter(seg, rate, bright, 0.9, "hp")

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

func _sfx(sound_name: String, seg: PackedFloat32Array, peak := SFX_PEAK) -> void:
	_save(_normalize(seg, peak), SFX_RATE, SFX_DIR + sound_name + ".wav")


# --- Sound effects --------------------------------------------------------------------------------

func _make_sfx() -> void:
	var r := SFX_RATE

	# The dispel (the most important sound): shriek -> crack. The warm release chime is its own
	# sound so the game can step its pitch up when several dispels land close together.
	for v in 4:
		var s := _seg(0.5, r)
		var top := rng.randf_range(800.0, 1050.0)
		var shriek := _tone(r, 0.2, glide(top, top * 0.35, 0.2), perc(0.01, 0.07, 0.2), "saw")
		_mix(s, _filter(shriek, r, 2200.0, 0.4), r, 0.0, 0.5)
		_mix(s, _filter(_noise(r, 0.2, perc(0.005, 0.05, 0.2)), r, glide(3000.0, 800.0, 0.2), 0.5, "bp"), r, 0.0, 0.3)
		_mix(s, _crackle(r, 0.18, 90.0, perc(0.002, 0.07, 0.18), 2500.0), r, 0.1, 0.9)
		_sfx("dispel_%02d" % (v + 1), s, 0.55)
	_sfx("dispel_chime", _bell(r, hz(86), 0.8, 0.45, CHIME, 1.6))  # D6

	var boss := _seg(3.0, r)
	var roar := _tone(r, 0.8, glide(420.0, 90.0, 0.8), perc(0.02, 0.3, 0.8), "saw")
	_mix(boss, _filter(roar, r, 1500.0, 0.5), r, 0.0, 0.5)
	_mix(boss, _crackle(r, 0.6, 120.0, perc(0.005, 0.25, 0.6), 1800.0), r, 0.35, 1.0)
	for m in [62, 66, 69, 74, 78]:  # D major, the Heartwood wins
		_mix(boss, _bell(r, hz(m), 0.3, 0.9, CHIME, 2.2), r, 0.6 + (m - 62) * 0.012)
	_sfx("dispel_boss", boss)

	var split := _seg(0.5, r)
	_mix(split, _bell(r, hz(93), 0.4, 0.12, CHIME, 0.4), r, 0.0)
	_mix(split, _bell(r, hz(93) * 1.03, 0.3, 0.1, CHIME, 0.4), r, 0.01)
	_mix(split, _crackle(r, 0.12, 120.0, perc(0.002, 0.05, 0.12)), r, 0.0, 0.8)
	_sfx("split", split, 0.45)

	# The Heartwood loses a leaf: lunge, groan, a leaf crackling as it falls. Cuts through.
	var leaf := _seg(1.6, r)
	var whoosh := _noise(r, 0.5, swell(0.3, 0.2, 0.5))
	_mix(leaf, _filter(whoosh, r, func(t: float) -> float: return 300.0 + 2800.0 * sin(PI * t / 0.5), 0.5), r, 0.0, 0.9)
	var groan := _tone(r, 1.1, func(t: float) -> float: return 72.0 - 14.0 * t + 3.0 * sin(t * 23.0), swell(0.1, 0.4, 1.1), "saw")
	_mix(leaf, _filter(groan, r, 500.0, 0.3), r, 0.3, 0.9)
	_mix(leaf, _crackle(r, 0.5, 60.0, perc(0.01, 0.2, 0.5), 2000.0), r, 0.7, 0.8)
	_sfx("leaf_lost", leaf, 0.8)

	for v in 3:  # Dew landing: a tiny tinkle
		var dew := _seg(0.35, r)
		var notes: Array = [[86, 90], [88, 93], [90, 95]][v]
		_mix(dew, _bell(r, hz(notes[0]), 0.5, 0.06, CHIME, 0.3), r, 0.0)
		_mix(dew, _bell(r, hz(notes[1]), 0.4, 0.07, CHIME, 0.3), r, 0.04)
		_sfx("dew_%02d" % (v + 1), dew, 0.35)

	# Building and the map.
	var plant := _seg(0.9, r)
	_mix(plant, _filter(_noise(r, 0.5, swell(0.05, 0.3, 0.5)), r, 160.0, 0.6), r, 0.0, 2.5)
	_mix(plant, _tone(r, 0.45, glide(45.0, 70.0, 0.45), swell(0.05, 0.25, 0.45)), r, 0.0, 0.5)
	_mix(plant, _creak(r, 0.4, 35.0, 90.0, 700.0), r, 0.2, 0.7)
	_mix(plant, _pluck(r, hz(62), 0.4, 0.5, 0.7), r, 0.45)
	_sfx("plant", plant)

	var evolve := _seg(1.4, r)
	for i in 4:  # D F# A D: a rising bloom
		_mix(evolve, _bell(r, hz([74, 78, 81, 86][i]), 0.4, 0.35, MUSIC_BOX, 1.0), r, i * 0.07)
	_mix(evolve, _filter(_noise(r, 0.6, swell(0.2, 0.3, 0.6)), r, 6000.0, 0.8, "hp"), r, 0.0, 0.08)
	_sfx("evolve", evolve)

	var sell := _seg(0.7, r)
	_mix(sell, _filter(_noise(r, 0.5, swell(0.02, 0.3, 0.5)), r, glide(3000.0, 300.0, 0.5), 0.5, "bp"), r, 0.0, 0.8)
	_mix(sell, _pluck(r, hz(55), 0.4, 0.5, 0.8), r, 0.2)
	_sfx("sell", sell, 0.55)

	var invalid := _seg(0.3, r)
	for k in 2:
		_mix(invalid, _knock(r, 170.0 - k * 20.0), r, k * 0.09)
	_sfx("invalid", invalid, 0.5)

	var tend := _seg(0.7, r)
	_mix(tend, _filter(_noise(r, 0.4, func(t: float) -> float: return swell(0.05, 0.1, 0.4).call(t) * (0.4 + 0.6 * absf(sin(t * 40.0)))), r, 4000.0, 0.8, "hp"), r, 0.0, 0.5)
	_mix(tend, _crackle(r, 0.3, 40.0, 0.7, 1500.0), r, 0.0)
	_mix(tend, _filter(_noise(r, 0.06, perc(0.001, 0.015, 0.06)), r, 1800.0, 0.4, "bp"), r, 0.35, 2.0)  # Snap
	_sfx("tend", tend, 0.6)

	var move := _seg(0.9, r)
	var grind_rate := rng.randf_range(9.0, 14.0)
	var grind := _noise(r, 0.7, func(t: float) -> float: return swell(0.1, 0.2, 0.7).call(t) * (0.5 + 0.5 * sin(t * grind_rate * TAU) * sin(t * 3.7)))
	_mix(move, _filter(grind, r, 450.0, 0.5), r, 0.0, 2.0)
	_mix(move, _knock(r, 70.0), r, 0.65, 1.2)
	_sfx("move", move, 0.6)

	var shimmer := _seg(0.6, r)
	for i in 5:
		_mix(shimmer, _bell(r, hz(86 + [0, 3, 5, 7, 10][i]), 0.2, 0.15, CHIME, 0.4), r, i * 0.04)
	_sfx("path_shimmer", shimmer, 0.25)

	var trample := _seg(1.0, r)
	_mix(trample, _knock(r, 55.0), r, 0.0, 1.5)
	_mix(trample, _filter(_noise(r, 0.4, perc(0.002, 0.12, 0.4)), r, 1200.0, 0.7), r, 0.0, 1.0)
	_mix(trample, _crackle(r, 0.5, 80.0, perc(0.005, 0.2, 0.5), 900.0), r, 0.02, 1.5)
	_sfx("trample", trample)

	# Warden attacks (warm and soft; voice-limited in game).
	for v in 3:
		var puff := _seg(0.35, r)
		_mix(puff, _tone(r, 0.08, glide(420.0 + v * 30.0, 140.0, 0.08), perc(0.002, 0.025, 0.08)), r, 0.0, 0.8)
		_mix(puff, _filter(_noise(r, 0.3, swell(0.03, 0.2, 0.3)), r, 1200.0, 0.8), r, 0.01, 0.5)
		_sfx("attack_spore_%02d" % (v + 1), puff, 0.4)
	for v in 3:
		var thock := _knock(r, 190.0 + v * 25.0)
		_mix(thock, _filter(_noise(r, 0.02, perc(0.0005, 0.004, 0.02)), r, 1400.0, 0.3, "bp"), r, 0.0, 1.2)
		_sfx("attack_stone_%02d" % (v + 1), thock, 0.45)
	for v in 3:
		var drop := _seg(0.3, r)
		_mix(drop, _tone(r, 0.09, glide(500.0 + v * 60.0, 1500.0, 0.06), perc(0.002, 0.03, 0.09)), r, 0.0)
		_mix(drop, _bell(r, 1800.0 + v * 100.0, 0.15, 0.04, CHIME, 0.2), r, 0.05)
		_sfx("attack_water_%02d" % (v + 1), drop, 0.4)
	for v in 3:
		var zap := _seg(0.3, r)
		var buzz := _tone(r, 0.18, func(t: float) -> float: return 180.0 + 60.0 * sin(t * 170.0) + rng.randf() * 40.0, perc(0.003, 0.06, 0.18), "square")
		_mix(zap, _filter(buzz, r, 2200.0, 0.6), r, 0.0, 0.35)
		_mix(zap, _crackle(r, 0.2, 150.0, perc(0.002, 0.08, 0.2), 2500.0), r, 0.0)
		_sfx("attack_light_%02d" % (v + 1), zap, 0.35)
	for v in 3:
		var pulse := _knock(r, 110.0 + v * 12.0)
		_mix(pulse, _filter(_noise(r, 0.4, swell(0.02, 0.3, 0.4)), r, 120.0, 0.6), r, 0.0, 3.0)
		_sfx("attack_root_%02d" % (v + 1), pulse, 0.5)
	for v in 3:
		_sfx("attack_sprout_%02d" % (v + 1), _pluck(r, hz([79, 81, 83][v]), 0.5, 0.4, 0.6, 0.99), 0.35)
	_sfx("attack_acorn", _bell(r, hz(74), 0.4, 0.3, MUSIC_BOX, 0.9), 0.3)

	# UI.
	var click := _knock(r, 900.0, 0.012)
	_mix(click, _knock(r, 300.0, 0.02), r, 0.0, 0.5)
	_sfx("ui_click", click, 0.35)

	var dream := _seg(1.8, r)  # A breath in, then a shimmer
	_mix(dream, _filter(_noise(r, 0.7, swell(0.6, 0.08, 0.7)), r, glide(400.0, 2500.0, 0.7), 0.6, "bp"), r, 0.0, 0.8)
	for i in 6:
		_mix(dream, _bell(r, hz([81, 84, 86, 88, 91, 93][i]), 0.25, 0.4, MUSIC_BOX, 1.1), r, 0.65 + i * 0.05)
	_sfx("dream_open", dream, 0.55)
	_sfx("dream_take_0", _bell(r, hz(74), 0.5, 0.5, MUSIC_BOX, 1.5), 0.45)  # Common: a soft note
	var rare := _seg(2.2, r)
	for m in [62, 65, 69, 74]:
		_mix(rare, _choir(r, hz(m), 2.0), r, 0.0, 0.25)
	_mix(rare, _bell(r, hz(81), 0.4, 0.6, MUSIC_BOX, 1.8), r, 0.0)
	_sfx("dream_take_1", rare, 0.55)
	var legendary := _seg(3.2, r)
	for m in [50, 62, 66, 69, 74, 78]:
		_mix(legendary, _choir(r, hz(m), 3.0), r, 0.0, 0.2)
	for i in 5:
		_mix(legendary, _bell(r, hz([74, 78, 81, 86, 90][i]), 0.35, 0.8, CHIME, 2.5), r, i * 0.08)
	_sfx("dream_take_2", legendary, 0.65)

	_sfx("family_bell", _bell(r, hz(50), 0.9, 1.4, BELL, 5.0), 0.6)  # A deep warm bell

	# The Omen: one soft, low gust (under ~400 Hz), not a roar. Rises and falls with the swell.
	var wind := _noise(r, 3.0, swell(1.0, 1.4, 3.0))
	_sfx("omen_wind", _filter(wind, r, func(t: float) -> float: return 140.0 + 240.0 * sin(PI * t / 3.0), 0.5), 0.4)

	var rest := _seg(3.0, r)  # The exhale: breath out and a warm strum
	_mix(rest, _filter(_noise(r, 1.2, swell(0.1, 0.9, 1.2)), r, glide(1500.0, 300.0, 1.2), 0.6, "bp"), r, 0.0, 0.5)
	for i in 5:
		_mix(rest, _pluck(r, hz([50, 57, 62, 66, 69][i]), 0.4, 2.2, 0.5, 0.998), r, 0.15 + i * 0.06)
	_sfx("rest", rest, 0.5)

	var drift := _seg(2.0, r)  # A drift comes: a low drum and a cold swell
	_mix(drift, _knock(r, 60.0, 0.35), r, 0.0, 1.2)
	var cold := _tone(r, 1.8, hz(38), swell(0.8, 0.8, 1.8), "saw")
	_mix(drift, _filter(cold, r, 300.0, 0.4), r, 0.1, 0.5)
	_mix(drift, _whisper(r, 1.4, 0.8), r, 0.3, 0.6)
	_sfx("drift_start", drift, 0.5)

	var act := _seg(4.0, r)  # Act break, leaves regrown: a warm swell and rustling leaves
	for m in [50, 57, 62, 66, 69]:
		_mix(act, _tone(r, 3.5, hz(m), swell(1.5, 1.5, 3.5), "tri"), r, 0.0, 0.12)
	_mix(act, _filter(_noise(r, 3.0, func(t: float) -> float: return swell(1.0, 1.0, 3.0).call(t) * (0.5 + 0.5 * sin(t * 13.0))), r, 3500.0, 0.7, "hp"), r, 0.3, 0.15)
	_sfx("act_swell", act, 0.55)

	var win := _seg(4.0, r)  # A warm resolving chord
	for i in 6:
		_mix(win, _pluck(r, hz([50, 57, 62, 66, 69, 74][i]), 0.4, 3.5, 0.4, 0.998), r, i * 0.09)
	for m in [74, 78, 81]:
		_mix(win, _bell(r, hz(m), 0.3, 1.0, CHIME, 3.0), r, 0.6)
	_sfx("win", win, 0.7)

	var loss := _seg(5.0, r)  # A slow fall into a single cold note
	for i in 5:
		_mix(loss, _pluck(r, hz([74, 70, 65, 62, 57][i]), 0.4, 1.6, 0.5, 0.997), r, i * 0.35)
	var last := _tone(r, 3.2, func(t: float) -> float: return hz(38) * (1.0 + 0.004 * sin(t * 1.3)), swell(1.0, 1.5, 3.2), "saw")
	_mix(loss, _filter(last, r, 400.0, 0.4), r, 1.6, 0.6)
	_mix(loss, _bell(r, hz(51), 0.3, 1.5, BELL, 3.2), r, 1.7)  # Eb: wrong, cold
	_sfx("loss", loss, 0.7)

	_make_signatures()

	# Added after the first batch (kept last so the earlier sounds' random seeds don't shift).
	var crit := _seg(0.6, r)  # The hit's own sound plays too; this is the bright ping on top
	_mix(crit, _bell(r, hz(98), 0.6, 0.12, CHIME, 0.5), r, 0.0)
	_mix(crit, _bell(r, hz(105), 0.3, 0.08, CHIME, 0.4), r, 0.015)
	_sfx("crit", crit, 0.4)
	var beam := _seg(0.3, r)  # One soft warm tick of a held beam; pitched up as it ramps
	for m in [74, 81]:
		_mix(beam, _tone(r, 0.28, hz(m), swell(0.04, 0.15, 0.28), "tri"), r, 0.0, 0.5)
	_mix(beam, _filter(_noise(r, 0.28, swell(0.04, 0.15, 0.28)), r, 3000.0, 0.8, "bp"), r, 0.0, 0.1)
	_sfx("beam", beam, 0.3)

	# Warden hits (after the first listen: attacks had no impact). The launch sounds above stay as the
	# quiet part; these play where the attack lands. Transient (2–4 kHz snap) + body (low thump) + tail
	# (the family's colour). `_dull` = resisted: a muffled transient and less body.
	for family in HIT_FAMILIES:
		for v in 3:
			_sfx("hit_%s_%02d" % [family, v + 1], _hit(family, v, false))
		_sfx("hit_%s_dull" % family, _hit(family, 1, true), 0.45)
	for v in 3:  # Weak to the Warden: a bright snap and a sparkle on top of the hit
		var bright := _filter(_noise(r, 0.012, perc(0.0003, 0.003, 0.012)), r, 3600.0 + v * 300.0, 0.4, "bp")
		_mix(bright, _bell(r, hz(96 + [0, 3, 5][v]), 0.3, 0.05, CHIME, 0.25), r, 0.004)
		_sfx("hit_bright_%02d" % (v + 1), bright, 0.4)
	var punch := _tone(r, 0.3, glide(120.0, 48.0, 0.05), perc(0.001, 0.06, 0.3))  # Crit: the extra low punch
	_mix(punch, _filter(_noise(r, 0.01, perc(0.0003, 0.002, 0.01)), r, 2500.0, 0.5, "bp"), r, 0.0, 0.5)
	_sfx("crit_punch", punch, 0.6)

# One Warden hit. `v` shifts the pitch a little per variant.
func _hit(family: String, v: int, dull: bool) -> PackedFloat32Array:
	var r := SFX_RATE
	var s := _seg(0.45, r)
	var shift := 1.0 + (v - 1) * 0.06
	# [transient band Hz, transient gain, body Hz, body decay s, body gain]
	var shape: Array = {
		"stone": [3000.0, 1.0, 70.0, 0.05, 1.0],
		"root": [1800.0, 0.5, 48.0, 0.12, 1.0],
		"water": [3400.0, 0.7, 110.0, 0.04, 0.7],
		"light": [3600.0, 0.8, 90.0, 0.035, 0.6],
		"spore": [2200.0, 0.45, 80.0, 0.06, 0.8],
		"sprout": [4000.0, 0.8, 150.0, 0.025, 0.5],
	}[family]
	var t_hz: float = shape[0] * shift
	var t_gain: float = shape[1] * (0.3 if dull else 1.0)
	var click := _noise(r, 0.012, perc(0.0003, 0.003, 0.012))
	_mix(s, _filter(click, r, 1100.0 if dull else t_hz, 0.4, "lp" if dull else "bp"), r, 0.0, t_gain * 1.6)
	var body_hz: float = shape[2] * shift
	var decay: float = shape[3]
	var body := _tone(r, decay * 6.0, glide(body_hz * 1.8, body_hz, 0.02), perc(0.001, decay, decay * 6.0))
	_mix(s, body, r, 0.0, shape[4] * (0.6 if dull else 1.0))
	match family:
		"stone":  # A hard wood/stone crack over the thud
			_mix(s, _crackle(r, 0.12, 110.0, perc(0.001, 0.03, 0.12), 1800.0), r, 0.003, 0.6)
		"root":  # Wooden knock + deep sub rumble, felt more than heard
			_mix(s, _knock(r, 170.0 * shift, 0.03), r, 0.0, 0.5)
			_mix(s, _filter(_noise(r, 0.4, swell(0.02, 0.3, 0.4)), r, 90.0, 0.6), r, 0.0, 3.0)
		"water":  # Droplet snap, low plunk, spray
			_mix(s, _tone(r, 0.05, glide(1200.0 * shift, 3000.0 * shift, 0.03), perc(0.001, 0.012, 0.05)), r, 0.0, 0.5)
			_mix(s, _filter(_noise(r, 0.3, perc(0.01, 0.08, 0.3)), r, 3500.0, 0.7, "hp"), r, 0.01, 0.25)
		"light":  # A warm crackle burst
			_mix(s, _crackle(r, 0.25, 220.0, perc(0.002, 0.07, 0.25), 2200.0), r, 0.0, 0.9)
		"spore":  # A full, round puff
			_mix(s, _filter(_noise(r, 0.3, swell(0.02, 0.22, 0.3)), r, 1100.0, 0.8), r, 0.005, 0.8)
		"sprout":  # A light, bright tock
			_mix(s, _pluck(r, hz(84) * shift, 0.3, 0.2, 0.3, 0.99), r, 0.0)
	if dull:
		s = _filter(s, r, 1400.0, 0.7)
	return s

# Nightmare signature sounds (played when one enters, and on their special moments).
func _make_signatures() -> void:
	var r := SFX_RATE
	var shade := _crackle(r, 0.7, 45.0, swell(0.1, 0.3, 0.7), 2500.0)  # Dry skittering, faint hiss
	_mix(shade, _filter(_noise(r, 0.6, swell(0.2, 0.3, 0.6)), r, 5000.0, 0.8, "hp"), r, 0.0, 0.15)
	_sfx("sig_shade", shade, 0.35)

	var husk := _seg(1.4, r)  # Creaking bark, heavy steps
	_mix(husk, _creak(r, 0.8, 18.0, 30.0, 400.0), r, 0.0, 0.8)
	for k in 2:
		_mix(husk, _knock(r, 60.0, 0.15), r, 0.4 + k * 0.6, 0.9)
	_sfx("sig_husk", husk, 0.5)

	_sfx("sig_lurker", _whisper(r, 1.5, 1.0, 6.0), 0.3)  # Only a faint whisper

	var phantom := _seg(1.6, r)  # Breathy whoosh, reversed choir
	var choir := _seg(1.2, r)
	for m in [62, 63, 69]:
		_mix(choir, _choir(r, hz(m), 1.2), r, 0.0, 0.3)
	_mix(phantom, _reverse(_env(choir, r, perc(0.02, 0.4, 1.2))), r, 0.0, 0.7)
	_mix(phantom, _filter(_noise(r, 1.0, swell(0.6, 0.3, 1.0)), r, glide(300.0, 1800.0, 1.0), 0.5, "bp"), r, 0.4, 0.6)
	_sfx("sig_phantom", phantom, 0.4)

	var growl := _tone(r, 0.9, func(t: float) -> float: return 78.0 + 6.0 * sin(t * 4.0), func(t: float) -> float: return swell(0.15, 0.3, 0.9).call(t) * (0.5 + 0.5 * absf(sin(t * 31.0 + sin(t * 7.0)))), "saw")
	_sfx("sig_hound", _filter(growl, r, 600.0, 0.4), 0.5)  # Low growl

	var howl := _tone(r, 1.6, func(t: float) -> float: return 300.0 + 180.0 * sin(PI * minf(t / 1.2, 1.0)) , swell(0.2, 0.6, 1.6), "saw")
	_sfx("hound_howl", _filter(howl, r, 1200.0, 0.3), 0.45)

	var procession := _seg(2.0, r)  # Distant chain-clink and a slow drum
	for k in 5:
		_mix(procession, _bell(r, 2100.0 + rng.randf() * 600.0, 0.3, 0.05, [[1.0, 1.0, 1.0], [1.47, 0.6, 0.8], [2.09, 0.4, 0.6]], 0.2), r, 0.1 + k * 0.23 + rng.randf() * 0.05)
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
		_mix(sob, _filter(_noise(r, 0.2, perc(0.05, 0.08, 0.2)), r, 1500.0, 0.6, "bp"), r, k * 0.33 + 0.15, 0.4)
	_sfx("sig_mourner", sob, 0.35)

	var widow := _crackle(r, 0.9, 25.0, swell(0.1, 0.3, 0.9), 1200.0)  # Clicking chitter
	_mix(widow, _whisper(r, 0.9, 0.4, 9.0), r, 0.0)
	_sfx("sig_widow", widow, 0.4)

	var stag := _seg(2.2, r)  # Deep bellow, crackling ghost-fire
	var bellow := _tone(r, 1.6, func(t: float) -> float: return 95.0 - 20.0 * t + 4.0 * sin(t * 9.0), swell(0.2, 0.7, 1.6), "saw")
	_mix(stag, _filter(bellow, r, func(t: float) -> float: return 400.0 + 500.0 * sin(PI * t / 1.6), 0.25), r, 0.0)
	_mix(stag, _crackle(r, 2.0, 70.0, swell(0.3, 0.5, 2.0), 1500.0), r, 0.1, 0.8)
	_sfx("sig_stag", stag, 0.7)

	var hag := _seg(1.8, r)  # Wet gurgling laugh
	for k in 4:
		var heh := _tone(r, 0.14, glide(260.0, 220.0, 0.14), perc(0.01, 0.05, 0.14), "saw")
		_mix(hag, _filter(heh, r, 900.0, 0.3), r, 0.3 + k * 0.17, 0.7)
	_mix(hag, _bubbles(r, 1.6, 18.0), r, 0.0, 0.8)
	_sfx("sig_hag", hag, 0.6)

	_sfx("hag_sink", _bubbles(r, 0.9, 30.0), 0.5)
	var splash := _filter(_noise(r, 0.6, perc(0.005, 0.15, 0.6)), r, glide(4000.0, 700.0, 0.6), 0.6)
	_mix(splash, _bubbles(r, 0.5, 20.0), r, 0.1, 0.5)
	_sfx("hag_rise", splash, 0.55)

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

# A soft wooden knock: a pitched thump with a click.
func _knock(rate: int, freq: float, tau := 0.04) -> PackedFloat32Array:
	var length := tau * 6.0
	var seg := _tone(rate, length, glide(freq * 1.6, freq, 0.02), perc(0.001, tau, length))
	_mix(seg, _filter(_noise(rate, 0.01, perc(0.0005, 0.002, 0.01)), rate, freq * 6.0, 0.5, "bp"), rate, 0.0, 0.6)
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
	# stretches between them, a leaf rustle every few seconds panned somewhere, a far owl, a whisper
	# now and then. No constant hiss (the first listen heard it as static).
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
	var rustle_at := rng.randf_range(0.5, 2.0)
	while rustle_at < LOOP - 1.0:  # Rustles
		var length := rng.randf_range(0.3, 0.8)
		var rustle := _crackle(r, length, rng.randf_range(40.0, 90.0), swell(0.08, 0.2, length), 1500.0)
		_mix(rustle, _filter(_noise(r, length, swell(0.1, 0.2, length)), r, 2200.0, 0.8, "bp"), r, 0.0, 0.25)
		rustle = _filter(rustle, r, 3500.0, 0.7)
		_pan_mix(left, right, rustle, rustle_at, 0.3, rng.randf_range(0.1, 0.9))
		rustle_at += rng.randf_range(2.0, 5.0)
	for hoot_at in [3.0, 12.5]:
		var hoot := _seg(1.0, r)
		for k in 2:
			_mix(hoot, _tone(r, 0.35, glide(410.0, 360.0, 0.35), swell(0.05, 0.2, 0.35)), r, k * 0.5)
		_pan_mix(left, right, hoot, hoot_at, 0.1, rng.randf_range(0.2, 0.8))
	_pan_mix(left, right, _whisper(r, 1.5, 1.0), 8.0, 0.2, 0.2)
	_pan_mix(left, right, _whisper(r, 1.2, 1.0), 16.5, 0.16, 0.8)
	_music_stereo("amb_act1", left, right, 0.5)

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
