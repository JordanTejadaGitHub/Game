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
# Wardens without sounds of their own (audio_direction.md "Warden sound sheet"): Sprout and Firefly
# Jar are their families' sounds (hit_sprout rebuilt, hit_light approved); Graftlings play the Warden
# they copy, muffled; Thornwall only plants; Echo Hollows sound on echoes; "" = silent by design.
const WARDEN_FALLBACKS := {"sprout": "hit_sprout", "firefly_jar": "hit_light", "graftling": "", "grafted_elder": "",
	"thornwall": ""}
const HIT_FAMILIES :=["stone", "root", "water", "light", "spore", "sprout"]
const MUSIC_LAYERS := ["base", "dread1", "dread2", "heartbeat", "boss", "boss_stag", "boss_stag_warm", "boss_hag",
	"boss_hag_warm", "boss_moth", "boss_moth_warm", "boss_oak", "boss_oak_warm"]

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
	# Warden sound sheet: every built Warden (resource/tower/*.tres) has its own sound (launch, hit,
	# event or loop), except the documented fallbacks.
	for file in DirAccess.get_files_at("res://resource/tower/"):
		if not file.ends_with(".tres"):
			continue
		var data := load("res://resource/tower/" + file) as TowerData
		var wid := SoundHooks.warden_id(data)
		var sounds := SoundHooks.warden_sounds(sound, data)
		if not data.can_attack and not WARDEN_FALLBACKS.has(wid) and sounds.is_empty():
			continue  # Wardens that never attack (walls, economy saplings) only plant, unless given more
		if WARDEN_FALLBACKS.has(wid):
			var fallback: String = WARDEN_FALLBACKS[wid]
			_check(fallback == "" or sounds.has(StringName(fallback)), "%s falls back to %s %s" % [wid, fallback, sounds])
		elif sounds.any(func(id: StringName) -> bool: return String(id).ends_with(wid) or String(id).contains(wid + "_")):
			pass
		else:  # Not on the sound sheet yet (e.g. a new final form): its family's sounds for now
			_check(not sounds.is_empty(), "%s has a sound or a family fallback %s" % [wid, sounds])
			print("NOTE: %s has no sounds of its own yet, using its family's %s" % [wid, sounds])
	_check(SoundHooks._rate_db(6.0) < SoundHooks._rate_db(0.33), "fast Wardens are quieter per shot")
	# Reactions: every Reaction has its sound, every Crowned one its signature (+ the shared crown), and
	# the chain swell / surge / Dawnburst / stinger exist.
	for dir in ["res://resource/reaction/", "res://resource/reaction/crowned/"]:
		for file in DirAccess.get_files_at(dir):
			if not file.ends_with(".tres"):
				continue
			var rid := StringName(file.get_basename())
			var needed := StringName(("crowned_%s" if Reactions.is_crowned(rid) else "reaction_%s") % rid)
			_check(sound.has_sound(needed), "Reaction %s has %s" % [rid, needed])
	for id in [&"crown_swell", &"chain_swell", &"chain_surge", &"chain_dawnburst", &"stinger_dawnburst",
			&"discover_reaction", &"loop_smother"]:
		_check(sound.has_sound(id), "%s exists" % id)
	# Nurture: a swell per family material, Focus leans, and Dawnwing's calm + busy loops in sync.
	for file in DirAccess.get_files_at("res://resource/tower/"):
		if file.ends_with(".tres"):
			var line: String = (load("res://resource/tower/" + file) as TowerData).line
			_check(sound.has_sound(StringName("nurture_" + line)), "nurture sound for the %s family" % line)
	for lean in ["focus_power", "focus_swift", "focus_reach", "focus_deep"]:
		_check(sound.has_sound(StringName(lean)), "%s exists" % lean)
	var calm: AudioStreamWAV = sound._streams.get(&"loop_dawnwing", [null])[0]
	var busy: AudioStreamWAV = sound._streams.get(&"loop_dawnwing_busy", [null])[0]
	_check(calm != null and busy != null and is_equal_approx(calm.get_length(), busy.get_length()),
		"Dawnwing's calm and busy loops exist and share a length")
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
	# A freed voice (a finished player) must not break play() for the same id, and gets pruned
	# (playtest bug: the typed filter lambda errored on freed players many times a second).
	var gone := Node.new()
	sound._voices[&"ui_click"] = [gone]
	gone.free()
	sound._last_start.erase(&"ui_click")
	sound.play(&"ui_click")
	_check(sound._voices[&"ui_click"].all(func(p) -> bool: return is_instance_valid(p)), "freed voices are pruned")
	# One theme per boss: every boss has its stem and a warm counter-melody (the lengths check above keeps
	# them in sync), and Softer nightmares halves the whispering dread layer.
	for key in SoundHooks.BOSS_THEMES:
		_check(ResourceLoader.exists("res://resource/enemy/%s.tres" % key), "boss %s exists" % key)
	sound.set_softer_nightmares(true)
	_check(is_equal_approx(sound._layer_gain(&"dread2"), Sound.LAYER_GAIN[&"dread2"] * Sound.SOFTER_DREAD2), "softer nightmares: quieter whispers")
	sound.set_softer_nightmares(false)
	_check(is_equal_approx(sound._layer_gain(&"dread2"), Sound.LAYER_GAIN[&"dread2"]), "normal nightmares")

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
