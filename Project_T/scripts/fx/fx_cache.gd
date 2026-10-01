extends Node
class_name FxCache

# Holds every effect sheet strongly for the run (user: "pretty laggy"). Fx's own static cache may only hold
# weak references (a Resource in a static crashed the game at exit, bb5076e2), so a sheet with no effect
# playing was freed and loaded from disk again on its next use: a hitch in the middle of a fight. This
# node lives in the run's scene and goes away with it. It loads all of effects.json's sheets once (107
# small PNGs, ~0.4 MB), so even a first Crowned Reaction doesn't stall. Made by Fx on first use.

const GROUP := &"fx_cache"

var textures := {}  # effect id -> Texture2D

static func find(near: Node) -> FxCache:
	if near == null or not near.is_inside_tree():
		return null
	var cache := near.get_tree().get_first_node_in_group(GROUP) as FxCache
	if cache == null:
		cache = FxCache.new()
		cache.name = "FxCache"
		var scene := near
		while scene.get_parent() != null and scene.get_parent() != near.get_tree().root:
			scene = scene.get_parent()
		scene.add_child(cache)
		cache.warm()
	return cache

func _init() -> void:
	add_to_group(GROUP)

# Loads every sheet in the index now (once per run).
func warm() -> void:
	for effect in Fx.effect_ids():
		get_texture(effect)

func get_texture(effect: StringName) -> Texture2D:
	var tex: Texture2D = textures.get(effect)
	if tex == null:
		var entry := Fx.info(effect)
		if entry.is_empty() or not ResourceLoader.exists(Fx.DIR + entry.file):
			return null
		tex = load(Fx.DIR + entry.file)
		textures[effect] = tex
	return tex
