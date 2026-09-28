extends SceneTree
# Audio setup: the Sound autoload made its buses and loaded the generated sounds, and every sound
# SoundHooks asks for exists (a missing file would just be silent in game, so check here).
# Run: Godot --headless --path . --script res://tests/test_sound.gd

const HOOK_IDS := [&"dispel", &"dispel_release", &"dispel_boss", &"split", &"leaf_lost", &"dew",
	&"plant", &"evolve", &"sell", &"invalid", &"tend", &"move", &"path_shimmer", &"trample",
	&"attack_spore", &"attack_stone", &"attack_water", &"attack_light", &"attack_root",
	&"attack_sprout", &"attack_acorn", &"ui_click", &"dream_open", &"dream_take_0", &"dream_take_1",
	&"dream_take_2", &"family_bell", &"omen_wind", &"rest", &"drift_start", &"act_swell", &"win",
	&"loss", &"hag_rise", &"crit", &"beam", &"crit_punch", &"hit_full", &"combo_found"]
const HIT_FAMILIES := ["stone", "root", "water", "light", "spore", "sprout"]
const MUSIC_LAYERS := ["base", "dread1", "dread2", "heartbeat", "boss"]

var failures := 0

func _initialize() -> void:
	await process_frame
	var sound := root.get_node_or_null("Sound")
	_check(sound != null, "Sound autoload exists")
	if sound == null:
		quit(failures)
		return
	for bus in Sound.BUSES:
		_check(AudioServer.get_bus_index(bus) != -1, "bus %s exists" % bus)
	for bus in [&"SFX", &"UI"]:  # The softening safety net
		var index := AudioServer.get_bus_index(bus)
		var kinds := []
		for i in AudioServer.get_bus_effect_count(index):
			kinds.append(AudioServer.get_bus_effect(index, i).get_class())
		_check(kinds.has("AudioEffectHighShelfFilter") and kinds.has("AudioEffectHardLimiter"),
			"%s bus has a high shelf and a limiter %s" % [bus, kinds])
	for id in HOOK_IDS:
		_check(sound.has_sound(id), "sound %s exists" % id)
	for id in SoundHooks.SIGNATURES.values():
		_check(sound.has_sound(id), "signature %s exists" % id)
	_check(sound._streams[&"attack_stone"].size() == 3, "variants group under one id")
	_check(SoundHooks.HIT_FAMILIES == HIT_FAMILIES, "SoundHooks hit families match")
	for family in HIT_FAMILIES:
		_check(sound.has_sound(StringName("hit_" + family)), "hit sound %s exists" % family)
		_check(sound.has_sound(StringName("hit_%s_dull" % family)), "resisted hit sound %s exists" % family)
	_check(SoundHooks._weight_pitch_for(3000, false, true) < SoundHooks._weight_pitch_for(20, false, false),
		"big nightmares take lower hits than small ones")
	for layer in MUSIC_LAYERS:
		_check(ResourceLoader.exists("res://assets/audio/music/mus_act1_%s.wav" % layer), "music layer %s exists" % layer)
	_check(ResourceLoader.exists("res://assets/audio/music/amb_act1.wav"), "act 1 ambience exists")

	# Stems loop and share one length, so they stay in sync.
	sound.play_music(&"act1", [&"base", &"dread1"])
	var lengths := []
	for layer in sound._music:
		var wav: AudioStreamWAV = sound._music[layer].stream
		_check(wav.loop_mode == AudioStreamWAV.LOOP_FORWARD, "%s loops" % layer)
		lengths.append(snappedf(wav.get_length(), 0.01))
	_check(lengths.size() == MUSIC_LAYERS.size() and lengths.all(func(l: float) -> bool: return l == lengths[0]),
		"all stems are the same length %s" % [lengths])
	_check(sound._music_target[&"dread1"] == 1.0 and sound._music_target[&"dread2"] == 0.0, "requested layers are audible")
	sound.set_layer(&"dread2", true)
	_check(sound._music_target[&"dread2"] == 1.0, "set_layer turns a layer on")
	# Adding layers never makes the music louder: the stems are trimmed together.
	var base_only := _music_db(sound, [&"base"])
	var all_layers := _music_db(sound, MUSIC_LAYERS.map(func(l: String) -> StringName: return StringName(l)))
	_check(_power(all_layers) <= _power(base_only) * 1.05, "all layers are no louder than the base (%s vs %s)" % [all_layers, base_only])
	_check(Sound.LAYER_GAIN[&"dread1"] < Sound.LAYER_GAIN[&"base"] and Sound.LAYER_GAIN[&"dread2"] < Sound.LAYER_GAIN[&"base"],
		"dread layers are quieter than the base")
	sound.stop_music()

	# Ducking dips the music and ambience, then lets go.
	sound.duck(8.0, 0.1)
	for i in 10:
		sound._process(0.02)
	_check(sound._duck_db > 7.0, "a duck dips ~8 dB (%.1f)" % sound._duck_db)
	OS.delay_msec(150)  # Ducks time out in real time (--fixed-fps runs game time faster)
	for i in 60:
		sound._process(0.02)
	_check(sound._duck_db < 0.1, "the duck releases (%.1f)" % sound._duck_db)
	sound.set_drifting(true)
	for i in 300:
		sound._process(0.02)
	_check(absf(sound._phase_db - Sound.DRIFT_MUSIC_DB) < 0.1, "music is lower during drifts")
	sound.set_drifting(false)
	# Dispels close together get quieter (a softer swell), never higher: no chime combo, no coin.
	_check(not sound.has_sound(&"dispel_chime") and not sound._streams.has(&"dew_01"), "no dispel chime or Dew tinkle")
	sound.play_dispel(Vector2.ZERO)
	sound.play_dispel(Vector2.ZERO)
	_check(sound._dispel_cluster == 1, "a second dispel joins the cluster")
	_check(HeartwoodMemory.defaults().settings.music_volume == 0.55, "music defaults to 55%")

	print("test_sound: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

# The music's layer volumes (dB) once `layers` have fully faded in.
func _music_db(sound: Node, layers: Array) -> Array:
	sound.play_music(&"act1", layers)
	for i in 100:
		sound._process(0.02)
	var out := []
	for layer in sound._music:
		out.append(snappedf(sound._music[layer].volume_db, 0.1))
	return out

func _power(volumes: Array) -> float:
	var total := 0.0
	for db in volumes:
		total += db_to_linear(db) ** 2
	return total

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", what)
