extends SceneTree
# Audio setup: the Sound autoload made its buses and loaded the generated sounds, and every sound
# SoundHooks asks for exists (a missing file would just be silent in game, so check here).
# Run: Godot --headless --path . --script res://tests/test_sound.gd

const HOOK_IDS := [&"dispel", &"dispel_chime", &"dispel_boss", &"split", &"leaf_lost", &"dew",
	&"plant", &"evolve", &"sell", &"invalid", &"tend", &"move", &"path_shimmer", &"trample",
	&"attack_spore", &"attack_stone", &"attack_water", &"attack_light", &"attack_root",
	&"attack_sprout", &"attack_acorn", &"ui_click", &"dream_open", &"dream_take_0", &"dream_take_1",
	&"dream_take_2", &"family_bell", &"omen_wind", &"rest", &"drift_start", &"act_swell", &"win",
	&"loss", &"hag_rise"]
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
	for id in HOOK_IDS:
		_check(sound.has_sound(id), "sound %s exists" % id)
	for id in SoundHooks.SIGNATURES.values():
		_check(sound.has_sound(id), "signature %s exists" % id)
	_check(sound._streams[&"attack_stone"].size() == 3, "variants group under one id")
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
	sound.stop_music()

	print("test_sound: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", what)
