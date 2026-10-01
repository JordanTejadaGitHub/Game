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
	process_mode = Node.PROCESS_MODE_ALWAYS  # Frame time counts while paused too

# Real frame time (platforms.md: decorative effects thin first, automatically, when frames run long):
# a smoothed frame time steps Fx down above SLOW_MS and back up below FAST_MS (hysteresis, so it doesn't
# flicker). Also the visible world rect, for skipping off-screen decoration (Fx.on_screen).
const SLOW_MS := 22.0
const FAST_MS := 14.0
const SMOOTHING := 0.1
var _last_usec := 0
var _average_ms := 16.0

func _process(_delta: float) -> void:
	var now := Time.get_ticks_usec()
	if _last_usec > 0:
		var ms := minf((now - _last_usec) / 1000.0, 100.0)  # A one-off stall (loading) can't decide alone
		_average_ms = lerpf(_average_ms, ms, SMOOTHING)
		if not Fx.auto_reduced and _average_ms > SLOW_MS:
			Fx.auto_reduced = true
		elif Fx.auto_reduced and _average_ms < FAST_MS:
			Fx.auto_reduced = false
	_last_usec = now
	var viewport := get_viewport()
	if viewport != null:
		Fx.view_rect = viewport.get_canvas_transform().affine_inverse() * viewport.get_visible_rect()

func average_ms() -> float:
	return _average_ms

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
