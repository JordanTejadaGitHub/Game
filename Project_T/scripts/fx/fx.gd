extends RefCounted
class_name Fx

# Plays the combat effect sheets in assets/effects/ (index: effects.json, made by
# tools/effect_art_generator.gd). Static API, so any script can fire an effect without a node in
# the scene. Owns the visual rules from screens_ui.md "Impact tiers": the budget of ~6 full
# Reaction effects per second (the rest swap to their _lite sheet), the reduce-flashes and
# hitstop settings, Reaction callouts and light threads, and chain presentation (badge, surge,
# Dawnburst). Game rules never live here: callers decide what happened, Fx only shows it.
#
#   Fx.play(effect, at, parent, scale, lite_ok, seconds)  one sheet at a world position
#   Fx.segment(effect, from, to, parent, seconds)          arc / light thread / root drag
#   Fx.reaction(reaction, at, parent, towers, seconds)     effect + callout + light threads
#   Fx.chain(count, where, parent, towers)                 x2+ badge, x5 surge + hitstop, x10 Dawnburst
#   Fx.crit(at, parent) / Fx.status_flash(status, at, parent)
#   Fx.rain_sweep(center, radius, parent, seconds)         Monsoon's sheet of rain
#
# `parent`: the run's scene root (world space, scrolls with the map). Never EnemyContainer or
# TowerContainer: other code treats their children as nightmares / Wardens.

const INDEX_PATH := "res://assets/effects/effects.json"
const DIR := "res://assets/effects/"
const FULL_PER_SECOND := 6  # Full Reaction effects per second before the _lite sheets take over
const Z := 20  # Above nightmares and Wardens, under the combat callouts (21)
const SETTINGS_REFRESH_MS := 1000

# Reaction id -> [effect sheet, callout text]. Callout colours come from effects.json.
const REACTIONS := {
	&"thunderclap": [&"thunderclap", "Thunderclap!"],
	&"ignite": [&"ignite", "Ignite!"],
	&"mushrooming": [&"overgrowth", "Mushrooming!"],
	&"shatter": [&"shatter", "Shatter!"],
	&"drown": [&"drown", "Drown!"],
	&"pinned": [&"pinned", "Pinned!"],
	&"smother": [&"smother", "Smother!"],
	&"lightning_rod": [&"lightning_rod", "Lightning Rod!"],
	&"sleepwalk": [&"puffball_bloom", "Sleepwalk!"],  # Sleepwalk / Night Terror (2026-10-17): existing sheets for now;
	&"night_terror": [&"bolt_strike", "Night Terror!"],  # their callout colour comes from the ReactionData (below)
	# Crowned Reactions: gold tier, a crown on the callout.
	&"tempest": [&"crowned_tempest", "Tempest!"],
	&"still_pool": [&"crowned_still_pool", "Still Pool!"],
	&"fever_dream": [&"crowned_fever_dream", "Fever Dream!"],
	&"starfall": [&"crowned_starfall", "Starfall!"],
	&"avalanche": [&"crowned_avalanche", "Avalanche!"],
	&"prismstorm": [&"crowned_prismstorm", "Prismstorm!"],
	&"nightbloom": [&"crowned_nightbloom", "Nightbloom!"],
	&"fairy_circle": [&"crowned_fairy_circle", "Fairy Circle!"],
	# Changeling / Wide Awake (owner 2026-10-17, council reactions_unique.md): other Crowned sheets stand in until their
	# own are drawn; their callout colour comes from the ReactionData (COLOUR_FROM_DATA).
	&"changeling": [&"crowned_nightbloom", "Changeling!"],
	&"wide_awake": [&"crowned_starfall", "Wide Awake!"],
}
const COLOUR_FROM_DATA: Array[StringName] = [&"changeling", &"wide_awake"]
# Sheets that peak small in their frame: shown bigger (screens_ui.md "Size check").
const DEFAULT_SCALE := {&"thunderclap_lite": 1.5, &"ignite_lite": 1.5, &"crit_flare": 1.25}  # (Tower Assets 74b11108: the base Reactions are drawn at full size now)
const RING_SECONDS := 0.45  # The contributing Wardens' pulse ring
const CROWN_OFFSET := Vector2(0, -34)  # The Crowned crown mark over its callout
# Reaction callouts (user 2026-10-20, screens_ui.md 5f7852e2: "Reactions are hard to see and read"): pop in 0.12 s with a
# small overshoot, hold, then rise 6 px and fade over 0.3 s. Crowned ones hold longer. CALLOUT_LIFE = the ordinary whole.
const CALLOUT_HOLD := 0.9
const CALLOUT_HOLD_CROWNED := 1.2
const CALLOUT_FADE := 0.3
const CALLOUT_LIFE := 0.12 + CALLOUT_HOLD + CALLOUT_FADE
const CALLOUT_LIFE_CROWNED := 0.12 + CALLOUT_HOLD_CROWNED + CALLOUT_FADE  # A Crowned callout's whole life (it holds longer)
const CALLOUT_SAME_PX := 28.0  # The same Reaction this close to a live callout is the same nightmare: it bumps "×2"
const REACTION_MIN_PX := 96.0  # Reaction bursts drawn at least 1.5 cells across (whole scale steps, so pixels stay square)
const REACTION_FLASH_SECONDS := 0.05  # The burst's 1-frame bright flash (off under reduce flashes)
const CALLOUT_COOLDOWN := 0.5  # Per reaction, so a chain doesn't wall the screen with words
const MAX_CALLOUTS := 3
const CALLOUT_CLEAR := Vector2(110, 20)  # Two callouts closer than this stack (a line apart)
const BADGE_OFFSET := Vector2(0, -60)
const HITSTOP_SECONDS := 0.07
const HITSTOP_SCALE := 0.05  # Speed during a hitstop
const SURGE_SECONDS := 0.5
const DAWNBURST_SCALE := 2.0

static var _index := {}
static var _textures := {}
static var _full_times: Array[int] = []  # msec of recent full Reaction effects
static var _settings := {}
static var _settings_at := -SETTINGS_REFRESH_MS
static var _callout_cooldown := {}  # reaction -> msec it may pop again
static var _callouts_alive: Array = []
static var _badge: Node2D
static var longest_chain := 0  # This run's longest chain (reset with reset_run())

# --- Data ---------------------------------------------------------------------------------------

# Effects quality (Settings → Display "effects_quality": 0 Full, 1 Reduced) plus the automatic step-down
# when real frames run long (FxCache measures them). Reduced: Reaction sheets play their lite versions,
# fewer full Reactions a second, Kinship root pulses off, off-screen Wardens skip their idle animation.
static var auto_reduced := false
static var view_rect := Rect2()  # The visible world rect (FxCache, each frame)
const REDUCED_FULL_PER_SECOND := 2

static func reduced() -> bool:
	return auto_reduced or int(setting("effects_quality", 0)) == 1

# Whether `at` (world) is on screen, with `margin` px around it (true when the rect isn't known yet).
static func on_screen(at: Vector2, margin: float = 64.0) -> bool:
	if view_rect.size.x < 256.0 or view_rect.size.y < 256.0:
		return true  # Not known yet, or a headless / tiny viewport (64×64): never call the map off-screen
	return view_rect.grow(margin).has_point(at)

# Photosensitivity (user: "a flash in the middle of my screen"): at most MAX_BRIGHT_PER_SECOND bright
# flashes (Dawnburst, chain surges) on screen a second; the rest are skipped. Every effect is at most
# MAX_EFFECT_PX across (2.5 cells).
const MAX_EFFECT_PX := 160.0
const MAX_BRIGHT_PER_SECOND := 3
static var _bright_times: Array[int] = []

static func bright_flash_ok() -> bool:
	var now := Time.get_ticks_msec()
	while not _bright_times.is_empty() and now - _bright_times[0] > 1000:
		_bright_times.pop_front()
	if _bright_times.size() >= MAX_BRIGHT_PER_SECOND:
		return false
	_bright_times.append(now)
	return true

# The small 1-frame flash a Reaction's burst gives (FxFlash: about a cell across, 0.05 s) has its own budget, so a busy
# field of Reactions never uses up the big moments' (the x5 surge, the x10 Dawnburst: bright_flash_ok). Still capped.
const MAX_SMALL_FLASH_PER_SECOND := 4
static var _small_flash_times: Array[int] = []

static func small_flash_ok() -> bool:
	var now := Time.get_ticks_msec()
	while not _small_flash_times.is_empty() and now - _small_flash_times[0] > 1000:
		_small_flash_times.pop_front()
	if _small_flash_times.size() >= MAX_SMALL_FLASH_PER_SECOND:
		return false
	_small_flash_times.append(now)
	return true

# The run's FxCache (weakly: a Node in a static is fine, a Resource isn't). Set up by play / segment.
static var _cache_ref: WeakRef = null

static func _cache() -> FxCache:
	return _cache_ref.get_ref() as FxCache if _cache_ref != null else null

static func _ensure_cache(near: Node) -> void:
	if _cache() == null and near != null and is_instance_valid(near):
		var cache := FxCache.find(near)
		if cache != null:
			_cache_ref = weakref(cache)

static func effect_ids() -> Array:
	info(&"")  # Loads the index
	return _index.keys()

static func info(effect: StringName) -> Dictionary:
	if _index.is_empty() and FileAccess.file_exists(INDEX_PATH):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(INDEX_PATH))
		if typeof(parsed) == TYPE_DICTIONARY:
			_index = parsed.get("effects", {})
	return _index.get(String(effect), {})

# Weak references (exit crash hunt, 2026-09-30): a static dictionary holding Texture2Ds kept them alive
# into the engine's teardown, which can crash on quit after the scene is gone. Effects playing hold their
# own reference; an unused sheet is simply loaded again (ResourceLoader's cache makes that cheap).
static func texture(effect: StringName) -> Texture2D:
	var cache := _cache()
	if cache != null:
		return cache.get_texture(effect)  # The run's strong cache (FxCache): no reloads mid-fight
	var held: WeakRef = _textures.get(effect)
	var tex: Texture2D = held.get_ref() if held != null else null
	if tex == null:
		var entry := info(effect)
		if entry.is_empty():
			return null
		tex = load(DIR + entry.file)
		_textures[effect] = weakref(tex)
	return tex

static func setting(key: String, fallback: Variant) -> Variant:
	var now := Time.get_ticks_msec()
	if now - _settings_at >= SETTINGS_REFRESH_MS:
		_settings = HeartwoodMemory.get_settings()
		_settings_at = now
	return _settings.get(key, fallback)

static func reduce_flashes() -> bool:
	return bool(setting("reduce_flashes", false))

# Forgets the cached settings (after the settings panel saves) and the run's chain record.
static func reset_run() -> void:
	_settings_at = -SETTINGS_REFRESH_MS
	longest_chain = 0
	_hitstop_base = -1.0  # A hitstop cut short by leaving the last run never ends here
	_hitstop_pending = 0

# The sheet to actually show: its _lite variant when flashes are reduced or the budget is spent.
static func _pick(effect: StringName, lite_ok: bool) -> StringName:
	var entry := info(effect)
	var lite := StringName(entry.get("lite", ""))
	if lite == &"":
		return effect
	if reduce_flashes():
		return lite
	var now := Time.get_ticks_msec()
	while not _full_times.is_empty() and now - _full_times[0] > 1000:
		_full_times.pop_front()
	var budget := REDUCED_FULL_PER_SECOND if reduced() else FULL_PER_SECOND  # Effects quality / long frames
	if lite_ok and _full_times.size() >= budget:
		return lite
	_full_times.append(now)
	return effect

# --- Playing ------------------------------------------------------------------------------------

# Plays `effect` once at world position `at` under `parent` (anchor respected) and returns its
# node, which frees itself. Looping sheets loop until freed, or for `seconds` if > 0.
static func play(effect: StringName, at: Vector2, parent: Node, scale: float = 1.0, lite_ok: bool = true,
		seconds: float = 0.0) -> Node2D:
	if parent == null or not is_instance_valid(parent):
		return null
	_ensure_cache(parent)
	var shown := _pick(effect, lite_ok)
	var entry := info(shown)
	var tex := texture(shown)
	if entry.is_empty() or tex == null:
		push_warning("Fx: no effect '%s'" % shown)
		return null
	var final_scale: float = scale * float(DEFAULT_SCALE.get(shown, 1.0))
	# Size cap (user: "a flash in the middle of my screen": Dawnburst at ×2 was 512 px, a gold disc over
	# most of the map): no effect is drawn wider than MAX_EFFECT_PX, so nightmares stay readable.
	var frame_size: Array = entry.get("frame_size", [0, 0])
	var widest: float = maxf(float(frame_size[0]), float(frame_size[1])) * final_scale
	# Ground rings (area_pulse_*, sap_pulse, surge_pulse) mark an area's real size and are drawn thin and quiet: not capped.
	if widest > MAX_EFFECT_PX and entry.get("kind", "") != "ground":
		final_scale *= MAX_EFFECT_PX / widest
		widest = MAX_EFFECT_PX
	# Phones (user 2026-10-18: "a flash on my screen … when a reaction goes off"): zoomed in on a small screen a 160 px
	# burst covered half of it. On screen it is at most PHONE_MAX_SCREEN_SHARE of the shorter side.
	if TouchBuild.mobile_controls() and entry.get("kind", "") != "ground" and parent.is_inside_tree():
		var screen := parent.get_viewport().get_visible_rect().size
		var on_screen_px := widest * parent.get_viewport().get_canvas_transform().get_scale().x
		var cap := minf(screen.x, screen.y) * PHONE_MAX_SCREEN_SHARE
		if on_screen_px > cap and on_screen_px > 0.0:
			final_scale *= cap / on_screen_px
	var node := FxSprite.new(entry, tex, final_scale, seconds)
	node.effect = shown
	node.name = "Fx_" + String(shown)
	parent.add_child(node)
	node.global_position = at
	return node

# Stretches a segment sheet (thunderclap_arc, light_thread, long_way_home_drag) from `from` to `to`
# (world positions), tiling it along the way, for `seconds`, fading out at the end.
static func segment(effect: StringName, from: Vector2, to: Vector2, parent: Node, seconds: float = 0.3) -> Node2D:
	if parent == null or not is_instance_valid(parent) or from.is_equal_approx(to):
		return null
	_ensure_cache(parent)
	var entry := info(effect)
	var tex := texture(effect)
	if entry.is_empty() or tex == null:
		push_warning("Fx: no effect '%s'" % effect)
		return null
	var node := FxSegment.new(entry, tex, from.distance_to(to), seconds)
	parent.add_child(node)
	node.global_position = from
	node.rotation = from.angle_to_point(to)
	return node

static func crit(at: Vector2, parent: Node) -> Node2D:
	return play(&"crit_flare", at, parent)

# A quick ring in the status's colour on the nightmare (a combo just used that status).
static func status_flash(status: StringName, at: Vector2, parent: Node) -> Node2D:
	var node := play(&"status_flash", at, parent)
	if node != null:
		var rows: Array = info(&"status_flash").get("rows", [])
		node.row = maxi(rows.find(String(status)), 0)
	return node

# Reaction accent (visual feedback spec C5, owner 2026-10-18): a Reaction a Dream card changed plays its effect x1.15
# and its callout carries a small warm card pip. The card's cue (DreamState.card_cue reaction_accent, heard by
# TowerPlacer) may come just before or just after the Reaction: either order within ACCENT_MS and ACCENT_NEAR px pairs.
const ACCENT_MS := 150
const ACCENT_NEAR := 64.0
const ACCENT_SCALE := 1.15
static var _accents: Array = []  # [msec, at] of cues not yet paired (plain data)
static var _recent_reactions: Array = []  # [msec, at, weakref(effect), weakref(callout)] not yet accented

static func note_reaction_accent(at: Vector2) -> void:
	var now := Time.get_ticks_msec()
	for r in _recent_reactions:
		if now - int(r[0]) <= ACCENT_MS and (r[1] as Vector2).distance_to(at) <= ACCENT_NEAR:
			_accent((r[2] as WeakRef).get_ref(), (r[3] as WeakRef).get_ref())
			_recent_reactions.erase(r)
			return
	_accents = _accents.filter(func(a: Array) -> bool: return now - int(a[0]) <= ACCENT_MS)
	if _accents.size() < 16:
		_accents.append([now, at])

static func _take_accent(at: Vector2) -> bool:
	var now := Time.get_ticks_msec()
	for a in _accents:
		if now - int(a[0]) <= ACCENT_MS and (a[1] as Vector2).distance_to(at) <= ACCENT_NEAR:
			_accents.erase(a)
			return true
	return false

static func _accent(node, shown) -> void:
	if node is Node2D and is_instance_valid(node):
		node.scale *= ACCENT_SCALE
	if shown is FxCallout and is_instance_valid(shown):
		shown.card_pip = true
		shown.queue_redraw()

# A named Reaction went off at `at`: its effect (budgeted), its callout in its colour, and a light
# thread from each Warden that set it up. Smother loops: pass `seconds` or free the returned node.
static func reaction(reaction: StringName, at: Vector2, parent: Node, towers: Array = [], seconds: float = 0.0,
		follow: Node2D = null) -> Node2D:
	var row: Array = REACTIONS.get(reaction, [reaction, ""])
	var effect: StringName = row[0]
	# At least 1.5 cells across (screens_ui.md 5f7852e2): a 64 px burst is drawn x2, bigger ones as they are.
	var frame_size: Array = info(effect).get("frame_size", [0, 0])
	var widest := maxf(float(frame_size[0]), float(frame_size[1])) * float(DEFAULT_SCALE.get(effect, 1.0))  # As play() draws it
	var burst_scale := ceilf(REACTION_MIN_PX / widest) if widest > 0.0 and widest < REACTION_MIN_PX else 1.0
	var node := play(effect, at, parent, burst_scale, true, seconds)
	_attach(node, follow)  # (Smother's loop too: Reactions keeps it on the nightmare's meta)
	# The base Reactions' ground part (Tower Assets 74b11108, effects.json "ground"): with the full sheet only (not a _lite
	# swap), at the same spot, scale and length, started this same frame, under the nightmares (z -1 in the world).
	if node is FxSprite and node.effect == effect and info(effect).has("ground"):
		var ground_world := Reactions._world(parent) if parent != null else null
		var ground := play(StringName(info(effect)["ground"]), at, ground_world if ground_world != null else parent, burst_scale, false, seconds)
		if ground != null:
			ground.z_index = -1
			_attach(ground, follow)
	var accent_shown: Node2D = null  # Its callout, for the Reaction accent (C5)
	var colour := Color(info(effect).get("callout", "#fff0c0"))
	if node != null and not reduce_flashes() and small_flash_ok():  # Its own budget (the big moments keep bright_flash_ok)
		var flash := FxFlash.new(colour, maxf(widest * burst_scale * 0.35, REACTION_MIN_PX * 0.35))
		parent.add_child(flash)
		flash.global_position = at
	if not info(effect).has("callout") or reaction in COLOUR_FROM_DATA:  # A sheet without its own callout colour (Sleepwalk, Night Terror) or a stand-in: the Reaction's
		var data := Reactions.get_data(reaction)
		if data != null:
			colour = data.callout_color
	if row[1] != "":
		# The name without its "!" and the reaction's icon (the callout redo; the crowned ones by their own id).
		var words := String(row[1]).trim_suffix("!")
		# Power budget (owner review 2026-10-16, "can be seen working"; Roguelite Code 73c2f686): a Reaction the build
		# boosts says so, "Ignite x2.1 from your build", in place of its bare name.
		var dreams := parent.get_tree().get_first_node_in_group(DreamState.GROUP) if parent != null and parent.is_inside_tree() else null
		if dreams != null and dreams.has_method("reaction_build_text"):
			var boosted: String = dreams.reaction_build_text(reaction)
			if boosted != "":
				words = boosted
		var shown := callout(words, colour, at, parent, reaction, IconInfo.icon(reaction), String(effect).begins_with("crowned_"), follow)
		accent_shown = shown
		if shown != null and String(effect).begins_with("crowned_"):
			# The crown mark sits on the callout and goes with it (the sheet loops: never leave it in the
			# world, or every Crowned Reaction leaves a crown behind).
			play(&"crowned_crown", at + CROWN_OFFSET, shown)
	# The Wardens that made it: a soft pulse ring on each (playtest: straight threads to them read as debug lines).
	for tower in towers:
		if tower is Node2D and is_instance_valid(tower):
			var ring := FxRing.new(colour, 14.0, 22.0, RING_SECONDS)
			parent.add_child(ring)
			ring.global_position = tower.global_position
	if String(effect).begins_with("crowned_"):
		add_trauma(TRAUMA_CROWNED, parent)  # Only Crowned Reactions shake (game-feel pass: ordinary ones don't)
	if _take_accent(at):  # A card's cue came first: accent now
		_accent(node, accent_shown)
	else:  # Else a cue just after it may still accent it
		var now := Time.get_ticks_msec()
		_recent_reactions = _recent_reactions.filter(func(r: Array) -> bool: return now - int(r[0]) <= ACCENT_MS)
		if _recent_reactions.size() < 16:
			_recent_reactions.append([now, at, weakref(node), weakref(accent_shown)])
	return node

# Reactions stay on their nightmare (user screenshot 2026-10-21: "the ignite doesn't happen on top of the enemy"): an
# effect or callout given `follow` moves with it every frame (its position = the nightmare's + the offset it started
# with); once the nightmare is freed or dispelled it stays where it was last and finishes there.
static func _attach(node: Node2D, follow: Node2D) -> void:
	if node == null or not is_instance_valid(follow):
		return
	if node is FxSprite or node is FxCallout:
		node.follow = weakref(follow)
		node.follow_offset = node.global_position - follow.global_position

# The nightmare a follower still follows (null: none, freed or dispelled).
static func _followed(ref: WeakRef) -> Node2D:
	var target = ref.get_ref() if ref != null else null
	if not is_instance_valid(target) or not (target is Node2D) or target.get(&"is_cleansed") == true:
		return null
	return target

# A word popping over the nightmare in `colour` (throttled: a few at a time, one per reaction).
# Returns the callout, or null when it was throttled.
static func callout(text: String, colour: Color, at: Vector2, parent: Node, key: StringName = &"", icon: Texture2D = null,
		crowned: bool = false, follow: Node2D = null) -> Node2D:
	var now := Time.get_ticks_msec()
	_callouts_alive = _callouts_alive.filter(func(c): return is_instance_valid(c))
	var target := follow if is_instance_valid(follow) else null
	# The same Reaction on the same nightmare while its word still holds: "×2" on that word, no second word. With a
	# nightmare to follow, "the same nightmare" is that nightmare (a different one gets its own word); without one, a
	# live word's CURRENT spot within CALLOUT_SAME_PX.
	if key != &"":
		for c in _callouts_alive:
			if not (c is FxCallout) or c.key != key or not c.holding():
				continue
			var theirs: Node2D = Fx._followed(c.follow)
			var same: bool = (theirs == target) if target != null or theirs != null else c.spot.distance_to(at) < CALLOUT_SAME_PX
			if same:
				c.bump()
				return c
	var cooldown_key: Variant = key if target == null else "%s:%d" % [key, target.get_instance_id()]  # Per nightmare when it follows one
	if now < _callout_cooldown.get(cooldown_key, 0):
		return null
	_callout_cooldown[cooldown_key] = now + int(CALLOUT_COOLDOWN * 1000)
	if _callouts_alive.size() >= MAX_CALLOUTS:  # A fourth replaces the oldest
		var oldest = _callouts_alive.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()
	var spot := at
	# Stacked, never drawn over each other (user: "Lightning Rod!" over "Thunderclap!"): a callout that would
	# land on a live one moves up a line, up to MAX_CALLOUTS lines.
	# One column for every word at a spot (WorldLabel.callout_slot, shared with CombatCallouts and the chain badge):
	# a word that would land on a live one moves up a line; a line is a whole callout tall.
	at = WorldLabel.callout_slot(at + Vector2(0.0, -FxCallout.LIFT), key if key != &"" else StringName(text), CALLOUT_LIFE) + Vector2(0.0, FxCallout.LIFT)
	var node := FxCallout.new(text, colour, icon, crowned)
	node.key = key
	node.spot = spot
	parent.add_child(node)
	node.global_position = at
	_attach(node, target)
	_callouts_alive.append(node)
	return node

# Monsoon's signature: a sheet of warm-lit rain over a square of `radius` pixels round `center`.
static func rain_sweep(center: Vector2, radius: float, parent: Node, seconds: float = 0.8) -> Node2D:
	var entry := info(&"monsoon_sweep")
	var tex := texture(&"monsoon_sweep")
	if parent == null or entry.is_empty() or tex == null:
		return null
	var node := FxRain.new(entry, tex, radius, seconds)
	parent.add_child(node)
	node.global_position = center
	return node

# --- Chains -------------------------------------------------------------------------------------

# A chain reached `count` at `where`. x2+: badge; x5: hitstop + warm surge; x10: Dawnburst and
# every Warden in `towers` flares. Call once per step of the chain.
static func chain(count: int, where: Vector2, parent: Node, towers: Array = []) -> void:
	if parent == null or not is_instance_valid(parent) or count < 2:
		return
	longest_chain = maxi(longest_chain, count)
	# The count rides on the newest Reaction word near the chain's link (the callout redo).
	var newest: FxCallout = null
	for c in _callouts_alive:
		if is_instance_valid(c) and c is FxCallout and absf(c.global_position.x - where.x) < CALLOUT_CLEAR.x \
				and absf(c.global_position.y - where.y) < WorldLabel.CALLOUT_CLEAR.y * MAX_CALLOUTS:  # The shared column's lines (40 px since 065db19e: a callout two lines up is still in reach)
			newest = c
	if newest != null:
		newest.set_count(count)
	# One badge, updated in place (the callout redo); a new one only when there's none here.
	if is_instance_valid(_badge) and _badge.get_parent() == parent and _badge is FxBadge:
		(_badge as FxBadge).set_count(count)
		_badge.global_position = WorldLabel.callout_slot(where + BADGE_OFFSET, &"chain_badge", 1.2)
	else:
		if is_instance_valid(_badge):
			_badge.queue_free()
		_badge = FxBadge.new(count)
		parent.add_child(_badge)
		_badge.global_position = WorldLabel.callout_slot(where + BADGE_OFFSET, &"chain_badge", 1.2)
	if count == 5 or count == 10:
		_hitstop(parent)
		add_trauma(TRAUMA_CHAIN_10 if count == 10 else TRAUMA_CHAIN_5, parent)
		if not reduce_flashes() and bright_flash_ok():
			_local_surge(where, parent)  # A local burst (playtest: the old full-screen gold wash)
	if count == 10 and bright_flash_ok():
		play(&"dawnburst", where, parent, DAWNBURST_SCALE, true)  # lite_ok: reduce flashes = its lite sheet; capped size
		for tower in towers:
			if tower is Node2D and is_instance_valid(tower):
				play(&"crit_flare", tower.global_position + Vector2(0, -16), parent, 1.6)

# A brief slow-down on a big chain. Overlapping hitstops extend one hitstop instead of stacking: the
# old version saved "the speed before" each time, so a second hitstop inside the first saved the
# slowed speed and restored to it, leaving the game at 5% speed for good (found by the act 3 probe).
static var _hitstop_base := -1.0  # The speed to return to (-1 = no hitstop on)
static var _hitstop_pending := 0  # Hitstop timers still running (the last one to end restores the speed)

static func _hitstop(parent: Node) -> void:
	if not bool(setting("hitstop", true)) or Engine.time_scale <= 0.0:
		return
	if _hitstop_base < 0.0 or not is_equal_approx(Engine.time_scale, _hitstop_base * HITSTOP_SCALE):
		_hitstop_base = Engine.time_scale  # Not in a hitstop (or the speed was changed meanwhile)
		Engine.time_scale = _hitstop_base * HITSTOP_SCALE
	_hitstop_pending += 1
	parent.get_tree().create_timer(HITSTOP_SECONDS, true, false, true).timeout.connect(_end_hitstop)

static func _end_hitstop() -> void:
	_hitstop_pending = maxi(_hitstop_pending - 1, 0)
	if _hitstop_base < 0.0 or _hitstop_pending > 0:
		return  # A later hitstop extended it; its own timer ends it
	if is_equal_approx(Engine.time_scale, _hitstop_base * HITSTOP_SCALE):
		Engine.time_scale = _hitstop_base  # (If the player changed speed meanwhile, keep theirs)
	_hitstop_base = -1.0

# The first grow into a final form each run: two swelling gold rings and the form's name over it.
static func final_bloom(tower: Node2D, title: String) -> void:
	var parent := Reactions._world(tower)
	if parent == null:
		return
	for i in 2:
		var ring := FxRing.new(Palette.GLOW, 20.0 + 16.0 * i, 130.0 + 40.0 * i, 0.8 + 0.25 * i)
		ring.z_index = Z
		parent.add_child(ring)
		ring.global_position = tower.global_position
	callout(title, Palette.GLOW, tower.global_position + Vector2(0, -56), parent, StringName("final_" + title))

# A chain of 5 or 10: a big gold ring swelling around where it happened, never a screen tint.
static func _local_surge(where: Vector2, parent: Node) -> void:
	var ring := FxRing.new(Palette.GLOW, 20.0, 60.0, 0.5)  # ~2.5 cells at its widest (was 4+)
	ring.z_index = Z
	parent.add_child(ring)
	ring.global_position = where

# (Unused since the playtest: a whole-screen tint read as a glitch.)
static func _surge(parent: Node) -> void:
	var tex := texture(&"surge")
	if tex == null:
		return
	var layer := CanvasLayer.new()
	layer.layer = 90
	var rect := TextureRect.new()
	rect.texture = tex
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.modulate.a = 0.0
	layer.add_child(rect)
	parent.get_tree().root.add_child(layer)
	var tween := rect.create_tween()
	tween.set_ignore_time_scale(true)
	tween.tween_property(rect, "modulate:a", 0.8, SURGE_SECONDS * 0.3)
	tween.tween_property(rect, "modulate:a", 0.0, SURGE_SECONDS * 0.7)
	tween.tween_callback(layer.queue_free)

const PHONE_MAX_SCREEN_SHARE := 0.2  # Phones: an effect's widest on screen, as a share of the screen's shorter side

# --- Screen shake: one decaying trauma value (screens_ui.md a8471922, game-feel pass) ---------------------------------
# The old shake tweened the camera to a fresh random spot each step and back to the offset it found at the start, so on
# PC two overlapping shakes kept the first one's off-centre offset as "rest" and the map drifted. Now one FxShaker per
# camera owns Camera2D.offset: every caller adds trauma (0..1), it decays over time, and the offset is smooth waves
# scaled by trauma², always measured from the true centre (offset 0 when it settles). Nothing else writes the offset.
# Off under reduced motion. Who shakes: Crowned Reactions, x5 / x10 chains, T3 heavy hits (Enemy's BIG_HIT_NUDGE through
# _shake), and add_trauma() for leaf / boss moments; ordinary Reactions don't.
const SHAKE_MAX_PX := 6.0  # The offset at trauma 1 (on screen on phones: divided by the zoom)
const SHAKE_DECAY := 1.6  # Trauma lost a second (a full shake settles in ~0.6 s)
const TRAUMA_CROWNED := 0.4
const TRAUMA_CHAIN_5 := 0.45
const TRAUMA_CHAIN_10 := 0.7

# Adds `amount` (0..1) of trauma to the camera of `near`'s viewport (or the last one shaken). Public: leaf and boss moments.
static func add_trauma(amount: float, near: Node = null) -> void:
	if amount <= 0.0 or bool(setting("reduced_motion", false)):
		return
	var shaker := FxShaker.for_node(near)
	if shaker != null:
		shaker.trauma = minf(shaker.trauma + amount, 1.0)

# Old callers' nudge in pixels (Enemy's T3 big hit): the trauma whose peak offset is about `pixels`.
static func _shake(parent: Node, pixels: float) -> void:
	add_trauma(sqrt(clampf(pixels / SHAKE_MAX_PX, 0.0, 1.0)), parent)

class FxShaker extends Node:
	var trauma := 0.0
	var _camera: WeakRef = null
	var _time := randf() * 10.0
	static var _last: WeakRef = null  # The shaker last used (weak: no Node in a static at exit)

	static func for_node(near: Node) -> FxShaker:
		if near == null or not is_instance_valid(near) or not near.is_inside_tree():
			var last = _last.get_ref() if _last != null else null
			if last != null:
				return last as FxShaker
			var tree := Engine.get_main_loop() as SceneTree  # add_trauma(amount) with no node, before any shake: the game's camera
			near = tree.root if tree != null else null
			if near == null:
				return null
		var camera := near.get_viewport().get_camera_2d()
		if camera == null:
			return null
		var found := camera.get_node_or_null("FxShaker") as FxShaker
		if found == null:
			found = FxShaker.new()
			found.name = "FxShaker"
			found._camera = weakref(camera)
			found.process_mode = Node.PROCESS_MODE_ALWAYS  # Settles through pauses and hitstops
			camera.add_child(found)
		_last = weakref(found)
		return found

	func _process(delta: float) -> void:
		var camera := _camera.get_ref() as Camera2D if _camera != null else null
		if camera == null:
			return
		var real := delta / maxf(Engine.time_scale, 0.01)  # Real time: hitstops and fast-forward don't change the feel
		if trauma <= 0.0:
			if camera.offset != Vector2.ZERO:
				camera.offset = Vector2.ZERO  # Settled: exactly the true centre
			return
		trauma = maxf(trauma - SHAKE_DECAY * real, 0.0)
		_time += real
		var pixels := SHAKE_MAX_PX * trauma * trauma
		if TouchBuild.mobile_controls():
			pixels /= maxf(camera.zoom.x, 0.01)  # Phones: on-screen pixels, not world ones
		# Two smooth waves per axis at unrelated rates: a rumble, never a fresh random jump each frame.
		var x := sin(_time * 37.0) * 0.6 + sin(_time * 59.0 + 1.3) * 0.4
		var y := sin(_time * 43.0 + 2.1) * 0.6 + sin(_time * 67.0 + 0.4) * 0.4
		camera.offset = Vector2(x, y) * pixels if trauma > 0.0 else Vector2.ZERO


# --- Exposed at full stacks is visible (screens_ui.md, last section; the user 2026-10-13: "when Exposed has full
# stacks, being hit should have a visual effect") ---------------------------------------------------
# Completing: a flare on the nightmare and one "Exposed" callout. While full: a quiet mark that follows it and goes
# the moment it's no longer Exposed (or is dispelled). Each hit that took the bonus: a small warm spark at the hit
# point. Tower Assets' exposed_complete / exposed_mark / exposed_hit when the sheets exist; stand-ins until then.
const EXPOSED_COMPLETE := &"exposed_complete"
const EXPOSED_MARK := &"exposed_mark"
const EXPOSED_HIT := &"exposed_hit"
const EXPOSED_META := &"fx_exposed_mark"  # On the nightmare: its mark node while it's fully Exposed
const EXPOSED_MARKS_MAX := 40  # Marks drawn at once (Beacon can fill a whole drift); the rest are tracked, not drawn
const EXPOSED_MARKS_REDUCED := 16
const EXPOSED_HIT_GAP_MS := 40  # Sparks at most this often (a pulse over a full drift is one spark a frame, not fifty)
const EXPOSED_HIT_GAP_REDUCED_MS := 150
static var _exposed_marks := 0
static var _exposed_hit_msec := 0

static func has_effect(effect: StringName) -> bool:
	return not info(effect).is_empty()

# An Exposed application landed on `enemy` (Reactions.on_status): if that filled its stacks, the completion shows.
# True when this call completed it (once per time it fills).
static func exposed_check(enemy: Node2D) -> bool:
	if not is_instance_valid(enemy) or enemy.is_cleansed or not enemy.statuses.is_exposed():
		return false
	var held = enemy.get_meta(EXPOSED_META) if enemy.has_meta(EXPOSED_META) else null
	if held != null and is_instance_valid(held) and not held.ending:
		return false  # Already full: nothing new
	var world := Reactions._world(enemy)
	if world == null:
		return false
	var mark := FxExposedMark.new(enemy, _exposed_marks >= (EXPOSED_MARKS_REDUCED if reduced() else EXPOSED_MARKS_MAX))
	world.add_child(mark)  # Never under %EnemyContainer (its children are all nightmares)
	enemy.set_meta(EXPOSED_META, mark)
	if not reduce_flashes():  # Reduce flashes: no flare; the mark stays
		if has_effect(EXPOSED_COMPLETE):
			play(sized(EXPOSED_COMPLETE, enemy), Tower.aim_at(enemy), world)
		else:
			status_flash(&"marked", enemy.global_position, world)  # Stand-in until the sheet lands
	var callouts := enemy.get_tree().get_first_node_in_group(&"combat_callouts") if enemy.is_inside_tree() else null
	if callouts != null and callouts.has_method("status_complete"):
		callouts.status_complete(enemy, &"marked")  # "Exposed", once, throttled like the combo words
	return true

# The nightmare's mark while it's fully Exposed (null otherwise).
static func exposed_mark_of(enemy: Node) -> Node2D:
	if not is_instance_valid(enemy) or not enemy.has_meta(EXPOSED_META):
		return null
	var held = enemy.get_meta(EXPOSED_META)
	return held if held != null and is_instance_valid(held) and not held.ending else null

# A hit on a fully Exposed nightmare took the bonus: a small warm spark at the hit point (thinned when busy).
static func exposed_hit(enemy: Node2D, at: Vector2) -> Node2D:
	if not is_instance_valid(enemy):
		return null
	var now := Time.get_ticks_msec()
	if now - _exposed_hit_msec < (EXPOSED_HIT_GAP_REDUCED_MS if reduced() else EXPOSED_HIT_GAP_MS):
		return null
	var world := Reactions._world(enemy)
	if world == null or not on_screen(at):
		return null
	_exposed_hit_msec = now
	if has_effect(EXPOSED_HIT):
		return play(EXPOSED_HIT, at, world)
	var spark := play(&"area_hit", at, world, 0.75)  # Stand-in until the sheet lands
	if spark != null:
		spark.modulate = Palette.GOLD  # multiplier (the Exposed colour on the pale spark)
	return spark


# --- Hit feedback on nightmares (screens_ui.md "Hit feedback on nightmares", layers 2 and 3; the user 2026-10-13:
# "being hit by different Wardens and statuses should have different hit feedback, like being hit by a Sprout vs the
# Jarlink's link") ---------------------------------------------------------------------------------------------
# Layer 2: one small effect at the hit point, by the source's family. Tower Assets' sheet `hit_<line>` (hit_thorns
# for thorns) when it exists; until then the nearest existing effect, [id, scale]. Layer 3: continuous damage keeps
# a looping overlay on the nightmare (`sustain_<kind>` when the sheet exists, drawn until then) and sets its
# sustained state (Fx.sustained(enemy), for Enemy's flinch: a tick isn't a hit). DamageLog.report calls
# damage_feedback for every damage event; the Jarlink link attaches its own overlay (it knows the segment).
const HIT_STAND_INS := {
	"sprout": [&"sprout_puff", 0.7], "spore": [&"dream_spore_puff", 0.8], "light": [&"spark_burst", 0.6],
	"water": [&"harvest_splash", 0.6], "stone": [&"landing_dust", 0.9], "root": [&"root_lash", 1.0],
	"song": [&"toll_ring", 0.5], "acorn": [&"firework_pop", 0.6], "wing": [&"peck_spark", 1.0],
	"wind": [&"dark_swirl", 0.6], "thorns": [&"thorns", 0.7], "wall": [&"thorns", 0.7]}
const HIT_DEFAULT := [&"area_hit", 0.75]
# Tower Assets f37e0b90: sheets not named hit_<line>. The Rootling line keeps root_lash (its scale from the stand-ins).
const HIT_ART := {"song": &"hit_bell", "thorns": &"hit_thorn", "wall": &"hit_thorn", "root": &"hit_root"}
const BODY_MID := 30.0  # Body sizes the sheets come in: up to 30 px across plain, up to 54 "_mid", larger "_big"
const BODY_BIG := 54.0
const BODY_META := &"fx_body_suffix"

# `effect` in the size that fits the nightmare's drawn body (exposed_mark, link_arcs…: "", "_mid", "_big"), by its
# art's solid height (Enemy's bounds.json) at its scale; the plain sheet when there is no sized one.
static func sized(effect: StringName, enemy: Node) -> StringName:
	if not is_instance_valid(enemy):
		return effect
	if not enemy.has_meta(BODY_META):
		var suffix := ""
		var sprite: AnimatedSprite2D = enemy.get("sprite") as AnimatedSprite2D
		var frames := sprite.sprite_frames if sprite != null else null
		if frames != null and frames.has_animation(&"walk_side") and frames.get_frame_count(&"walk_side") > 0:
			var tex := frames.get_frame_texture(&"walk_side", 0)
			var sheet: String = tex.atlas.resource_path if tex is AtlasTexture else tex.resource_path
			var all_bounds: Dictionary = enemy._art_bounds() if enemy.has_method("_art_bounds") else {}  # (enemy.gd has no class_name)
			var bounds: Dictionary = all_bounds.get(sheet.get_file().get_basename(), {})
			var tall: float = float(bounds.bottom) - float(bounds.top) if bounds.has("top") and bounds.has("bottom") else tex.get_height() * 0.6
			tall *= absf(sprite.scale.y)
			suffix = "_big" if tall > BODY_BIG else ("_mid" if tall > BODY_MID else "")
		enemy.set_meta(BODY_META, suffix)
	var fitted := StringName(String(effect) + String(enemy.get_meta(BODY_META)))
	return fitted if has_effect(fitted) else effect
const HIT_GAP_MS := 150  # One hit effect per nightmare per source
const HIT_PER_SECOND := 40  # Small puffs a second on screen; past it they thin out (the flinch doesn't)
const HIT_PER_SECOND_REDUCED := 14
const HIT_TIMES_META := &"fx_hit_times"  # On the nightmare: {source id: msec of its last hit effect}
const SUSTAIN_META := &"fx_sustained"  # On the nightmare: {kind: its FxSustain}
const SUSTAIN_LINK := &"link"  # Jarlink / Lightning Fence: arcs wrapping it
const SUSTAIN_BEAM := &"beam"  # The landing spot, growing with the ramp
const SUSTAIN_POISON := &"poison"  # Bubbles, more with more stacks
const SUSTAIN_ZONE := &"zone"  # Clouds, fog, rain, whirlpools: drips in the zone's colour
const SUSTAIN_MAX := 48  # Overlays drawn at once; the rest only keep the state
const SUSTAIN_MAX_REDUCED := 20
const BOLT_GAP_MS := 120  # Charged bolts' strikes from above, at most this often
static var _hit_times: Array[int] = []
static var _sustains := 0
static var _bolt_msec := 0
static var last_hit_effect := &""  # The last hit effect played (tests)

# The hit effect for a source of `line` whose damage carried `tag`: [effect id, scale].
static func hit_effect(line: String, tag: StringName = &"") -> Array:
	var key := "thorns" if tag == &"thorns" else line
	var art: StringName = HIT_ART.get(key, StringName("hit_" + key))
	if has_effect(art):
		return [art, 1.0]
	return HIT_STAND_INS.get(key, HIT_DEFAULT)

# Every damage event (DamageLog.report). Chooses the layer: a looping overlay for continuous damage, the strike for
# a Charged bolt, nothing for Reactions (their own bursts), the family's hit effect for the rest.
static func damage_feedback(event) -> void:
	var enemy: Node2D = event.enemy
	if not is_instance_valid(enemy) or not enemy.is_inside_tree():
		return
	var tag: StringName = event.tag
	var tower: Tower = event.source as Tower if is_instance_valid(event.source) else null
	if tag == &"fence":
		return  # BranchKit keeps the link's overlay
	if tag == &"spored":
		sustain(enemy, SUSTAIN_POISON, null, float(enemy.statuses.stacks(EnemyStatuses.SPORED)))
		return
	if tag == &"cloud" or tag == &"rain" or tag == &"fog" or tag == &"drown":
		sustain(enemy, SUSTAIN_ZONE, tower)
		return
	if tag == &"static":
		_bolt_strike(enemy)
		return
	if tower == null or (tag != &"thorns" and tag != &"" and tag != &"conducted" and tag != &"flurry_copy"):
		return  # Reactions and other effect damage show themselves
	if tag == &"" and tower.attack_data != null and tower.attack_data.attack_kind == TowerData.AttackKind.BEAM \
			and tower._beam_target == enemy:
		var top: float = maxf(tower.attack_data.beam_ramp_max - 1.0, 0.01)
		sustain(enemy, SUSTAIN_BEAM, tower, clampf((tower._beam_ramp - 1.0) / top, 0.0, 1.0))
		return
	# Performance (2026-10-17): the budget first (a busy field is when this is called most), then the per-nightmare reads.
	var now := Time.get_ticks_msec()
	while not _hit_times.is_empty() and now - _hit_times[0] > 1000:
		_hit_times.pop_front()
	if _hit_times.size() >= (HIT_PER_SECOND_REDUCED if reduced() else HIT_PER_SECOND):
		return  # Busy: the small puffs thin first
	var zone := sustain_of(enemy, SUSTAIN_ZONE)
	if zone != null and zone.source == tower and zone.fresh():
		return  # A whirlpool's or puddle's tick, not a hit
	var times: Dictionary = enemy.get_meta(HIT_TIMES_META) if enemy.has_meta(HIT_TIMES_META) else {}
	var id := tower.get_instance_id()
	if now - int(times.get(id, -HIT_GAP_MS)) < HIT_GAP_MS:
		return
	var at: Vector2 = Tower.aim_at(enemy)
	if not on_screen(at):
		return
	var world := Reactions._world(enemy)
	if world == null:
		return
	times[id] = now
	enemy.set_meta(HIT_TIMES_META, times)
	_hit_times.append(now)
	var chosen := hit_effect(tower.tower_data.line, tag)
	last_hit_effect = chosen[0]
	play(chosen[0], at, world, chosen[1])

# A Charged bolt: the strike from above, the biggest single reaction.
static func _bolt_strike(enemy: Node2D) -> void:
	var now := Time.get_ticks_msec()
	if now - _bolt_msec < BOLT_GAP_MS or not on_screen(enemy.global_position):
		return
	var world := Reactions._world(enemy)
	if world == null:
		return
	_bolt_msec = now
	last_hit_effect = &"bolt_strike" if has_effect(&"bolt_strike") else &"thunderhead_strike"  # Tower Assets f37e0b90: its anchor is the strike point
	play(last_hit_effect, Tower.aim_at(enemy) if last_hit_effect == &"bolt_strike" else enemy.global_position, world, 1.0 if last_hit_effect == &"bolt_strike" else 0.7)

# Continuous damage on `enemy`: attaches (or refreshes) the looping overlay of `kind` and sets its sustained state.
# The overlay goes the frame its source stops: the link when the nightmare leaves the segment (`link` = the two
# jars), the beam when it leaves the target, Poisoned when the stacks go, a zone when its ticks stop. `strength`:
# the beam's ramp 0..1, Poisoned's stacks.
static func sustain(enemy: Node2D, kind: StringName, source: Node = null, strength: float = 1.0, link: Array = []) -> Node2D:
	if not is_instance_valid(enemy) or enemy.is_cleansed or not enemy.is_inside_tree():
		return null
	var held := sustain_of(enemy, kind)
	if held != null:
		held.refresh(source, strength, link)
		return held
	var world := Reactions._world(enemy)
	if world == null:
		return null
	var node := FxSustain.new(enemy, kind, _sustains >= (SUSTAIN_MAX_REDUCED if reduced() else SUSTAIN_MAX))
	node.refresh(source, strength, link)
	var all: Dictionary = enemy.get_meta(SUSTAIN_META) if enemy.has_meta(SUSTAIN_META) else {}
	all[kind] = node
	enemy.set_meta(SUSTAIN_META, all)
	world.add_child(node)  # Never under %EnemyContainer (its children are all nightmares)
	return node

# The nightmare's live overlay of `kind` (null when none).
static func sustain_of(enemy: Node, kind: StringName) -> FxSustain:
	if not is_instance_valid(enemy) or not enemy.has_meta(SUSTAIN_META):
		return null
	var held = (enemy.get_meta(SUSTAIN_META) as Dictionary).get(kind)
	return held if held != null and is_instance_valid(held) and not held.is_queued_for_deletion() else null

# The kinds of continuous damage on `enemy` right now (its sustained state; empty = none).
static func sustained(enemy: Node) -> Array[StringName]:
	var kinds: Array[StringName] = []
	if is_instance_valid(enemy) and enemy.has_meta(SUSTAIN_META):
		var all: Dictionary = enemy.get_meta(SUSTAIN_META)
		for kind in all:
			if sustain_of(enemy, kind) != null:
				kinds.append(kind)
	return kinds

# Its source stopped: the overlay goes now.
static func sustain_end(enemy: Node, kind: StringName) -> void:
	var held := sustain_of(enemy, kind)
	if held != null:
		held.end()


# --- Nodes --------------------------------------------------------------------------------------

# A looping overlay on a nightmare taking continuous damage (see sustain). Follows it, checks its source every
# frame and frees itself the frame the source stops. `quiet` = over the cap: it keeps the state, drawing nothing.
class FxSustain extends Node2D:
	const HOLD := {&"link": 0.4, &"beam": 0.3, &"poison": 0.8, &"zone": 0.6}  # Seconds without a tick before it goes anyway
	const FRESH_MS := 60
	const ROLL := 0.07  # The arcs re-roll this often
	var enemy: Node2D
	var kind: StringName
	var source: Node
	var strength := 1.0
	var quiet := false
	var _link: Array = []
	var _left := 0.0
	var _age := 0.0
	var _roll := 0.0
	var _seed := 0
	var _stamp := 0
	var _art: Node2D = null
	var _art_shown := &"-"

	func _init(target: Node2D, of_kind: StringName, is_quiet: bool = false) -> void:
		enemy = target
		kind = of_kind
		quiet = is_quiet
		name = "Fx_sustain_" + String(of_kind)
		z_index = 2  # Over the nightmare, under the lighting pass

	func _ready() -> void:
		Fx._sustains += 1
		_follow()
		_fit_art()

	# Tower Assets' looping sheet for this overlay now (f37e0b90), &"" = drawn: the link's arcs in the body's size,
	# Poisoned's bubbles by stacks (each denser sheet keeps the sparser one's bubbles), the beam's spot by its ramp.
	func _art_id() -> StringName:
		var id := &""
		if kind == Fx.SUSTAIN_LINK:
			id = Fx.sized(&"link_arcs", enemy)
		elif kind == Fx.SUSTAIN_POISON:
			id = &"poison_bubbles_3" if strength >= 24.0 else (&"poison_bubbles_2" if strength >= 10.0 else &"poison_bubbles_1")
		elif kind == Fx.SUSTAIN_BEAM:
			id = &"beam_spot_big" if strength >= 0.5 else &"beam_spot"
		return id if id != &"" and Fx.has_effect(id) else &""

	func _fit_art() -> void:
		if quiet:
			return
		var id := _art_id()
		if id == _art_shown:
			return
		_art_shown = id
		if _art != null and is_instance_valid(_art):
			_art.queue_free()
		_art = Fx.play(id, global_position, self, 1.0, true, 9999.0) if id != &"" else null  # Loops until this node goes

	func _exit_tree() -> void:
		Fx._sustains = maxi(Fx._sustains - 1, 0)
		_forget()

	func refresh(from: Node, power: float, link: Array) -> void:
		source = from
		strength = power
		_link = link
		_left = HOLD.get(kind, 0.5)
		_stamp = Time.get_ticks_msec()

	# Refreshed just now (this frame's tick came from its source).
	func fresh() -> bool:
		return Time.get_ticks_msec() - _stamp <= FRESH_MS

	func end() -> void:
		_forget()
		queue_free()

	func _forget() -> void:
		if is_instance_valid(enemy) and enemy.has_meta(Fx.SUSTAIN_META):
			var all: Dictionary = enemy.get_meta(Fx.SUSTAIN_META)
			if all.get(kind) == self:
				all.erase(kind)

	func _follow() -> void:
		if is_instance_valid(enemy):
			global_position = Tower.aim_at(enemy)

	# Whether its source still reaches the nightmare.
	func _still() -> bool:
		if not is_instance_valid(enemy) or enemy.is_cleansed or _left <= 0.0:
			return false
		if kind == Fx.SUSTAIN_POISON:
			return enemy.statuses.has(EnemyStatuses.SPORED)
		if kind == Fx.SUSTAIN_LINK and _link.size() == 2:
			var a = _link[0]
			var b = _link[1]
			return is_instance_valid(a) and is_instance_valid(b) and a.is_inside_tree() and b.is_inside_tree() \
				and BranchKit.on_link(enemy.global_position, BranchKit.link_end(a), BranchKit.link_end(b))
		if kind == Fx.SUSTAIN_BEAM:
			return is_instance_valid(source) and source is Tower and source._beam_target == enemy
		return true

	func _process(delta: float) -> void:
		_left -= delta
		if not _still():
			end()
			return
		_follow()
		_age += delta
		_roll -= delta
		if _roll <= 0.0:
			_roll = ROLL * (4.0 if Fx.reduce_flashes() else 1.0)  # Reduce flashes: the arcs barely jitter
			_seed += 1
			_fit_art()  # The stacks or the ramp may have moved to the next sheet
		if not quiet and _art == null:
			queue_redraw()

	func _draw() -> void:
		if quiet or _art != null:
			return
		if kind == Fx.SUSTAIN_LINK:
			_draw_arcs()
		elif kind == Fx.SUSTAIN_BEAM:
			var r := 3.0 + 5.0 * strength
			draw_circle(Vector2.ZERO, r + 2.0, Color(Palette.GOLD, 0.35))
			draw_circle(Vector2.ZERO, r, Color(Palette.HEARTLIGHT, 0.85))
		elif kind == Fx.SUSTAIN_POISON:
			_draw_rising(clampi(int(strength / 8.0) + 1, 1, 6), EnemyStatuses.COLORS.get(EnemyStatuses.SPORED, Palette.MOSS), -1.0)
		else:
			var line: String = source.tower_data.line if is_instance_valid(source) and source is Tower else "water"
			_draw_rising(3, EnemyStatuses.COLORS.get(EnemyStatuses.SPORED, Palette.MOSS) if line == "spore" else Palette.DEW, 1.0)

	# Three short jittering arcs wrapping the body, in the link's colour.
	func _draw_arcs() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = _seed * 7919 + get_instance_id() % 1000
		for i in 3:
			var turn := rng.randf() * TAU
			var points := PackedVector2Array()
			for step in 5:
				var angle := turn + step * 0.45
				points.append(Vector2.from_angle(angle) * Vector2(12.0, 15.0) + Vector2(rng.randf_range(-3, 3), rng.randf_range(-3, 3)))
			draw_polyline(points, Color(BranchKit.LINK_COLOR, 0.9), 1.0)
			draw_circle(points[points.size() - 1], 1.0, Color(Palette.HEARTLIGHT, 0.9))

	# `count` small dots in `colour` around the body: rising (direction -1: bubbles) or falling (1: drips).
	func _draw_rising(count: int, colour: Color, direction: float) -> void:
		var still := bool(Fx.setting("reduced_motion", false))
		for i in count:
			var phase := fmod(_age * 0.9 + i * 0.37, 1.0) if not still else 0.4
			var x := -10.0 + fmod(i * 7.3, 20.0)
			var y := (6.0 - 22.0 * phase) if direction < 0.0 else (-12.0 + 20.0 * phase)
			draw_circle(Vector2(x, y), 1.5 if direction < 0.0 else 1.0, Color(colour, 0.85 * (1.0 - phase)))

# The quiet mark on a fully Exposed nightmare: Tower Assets' looping exposed_mark, or a thin warm ring with a glint
# circling it. Follows the nightmare; fades out and frees itself once it isn't Exposed any more. `quiet` = over the
# cap: it only keeps track (so the completion doesn't fire again), drawing nothing.
class FxExposedMark extends Node2D:
	const FADE := 0.25
	const RADIUS := 15.0
	var enemy: Node2D
	var quiet := false
	var ending := false
	var _age := 0.0
	var _fade := 1.0
	var _art: Node2D = null

	func _init(target: Node2D, is_quiet: bool = false) -> void:
		enemy = target
		quiet = is_quiet
		name = "Fx_exposed_mark"
		z_index = 2  # Over the nightmare, under the lighting pass

	func _ready() -> void:
		Fx._exposed_marks += 1
		if is_instance_valid(enemy):
			global_position = Tower.aim_at(enemy)  # The body centre (the sheets' anchor)
		if not quiet and Fx.has_effect(Fx.sized(Fx.EXPOSED_MARK, enemy)):
			_art = Fx.play(Fx.sized(Fx.EXPOSED_MARK, enemy), global_position, self, 1.0, true, 9999.0)  # Loops until this node goes

	func _exit_tree() -> void:
		Fx._exposed_marks = maxi(Fx._exposed_marks - 1, 0)
		if is_instance_valid(enemy) and enemy.has_meta(Fx.EXPOSED_META) and enemy.get_meta(Fx.EXPOSED_META) == self:
			enemy.remove_meta(Fx.EXPOSED_META)

	func _process(delta: float) -> void:
		if not ending and (not is_instance_valid(enemy) or enemy.is_cleansed or not enemy.statuses.is_exposed()):
			ending = true  # The stacks dropped, or it was dispelled
		if ending:
			_fade -= delta / FADE
			if _fade <= 0.0:
				queue_free()
				return
			modulate.a = _fade  # multiplier (the fade)
		if is_instance_valid(enemy):
			global_position = Tower.aim_at(enemy)  # The body centre (the sheets' anchor)
		_age += delta
		if not quiet and _art == null:
			queue_redraw()

	func _draw() -> void:
		if quiet or _art != null:
			return
		var colour: Color = EnemyStatuses.COLORS.get(EnemyStatuses.MARKED, Palette.GOLD)
		draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 28, Color(colour, 0.45), 1.0)
		if not bool(Fx.setting("reduced_motion", false)):
			draw_circle(Vector2.from_angle(_age * 2.4) * RADIUS, 1.5, Color(Palette.HEARTLIGHT, 0.9))  # The glint circling it

# One sheet playing at its anchor. Frees itself at the end (or after `seconds` when looping).
# A soft ring that swells and fades on a Warden that helped make a Reaction (under the Wardens).
class FxRing extends Node2D:
	var _colour: Color
	var _age := 0.0
	var _base := 14.0
	var _grow := 22.0
	var _life := 0.45

	func _init(colour: Color, base := 14.0, grow := 22.0, life := 0.45) -> void:
		_colour = colour
		_base = base
		_grow = grow
		_life = life
		z_index = -1

	func _process(delta: float) -> void:
		_age += delta
		if _age >= _life:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var t := _age / _life
		var radius := _base + _grow * t
		var alpha := 1.0 - t
		draw_circle(Vector2(0, 6), radius, Color(_colour, 0.12 * alpha))
		draw_arc(Vector2(0, 6), radius, 0.0, TAU, 32, Color(_colour, 0.7 * alpha), 2.0)


class FxSprite extends Node2D:
	var effect: StringName  # The sheet shown (the _lite one if it was swapped)
	var row := 0
	var still := -1  # >= 0: only this frame is drawn, for the sheet's usual life (reduced motion stills)
	var _tex: Texture2D
	var _size: Vector2
	var _frames: int
	var _fps: float
	var _anchor: Vector2
	var _loop: bool
	var _scale: float
	var _seconds: float
	var _age := 0.0
	var follow: WeakRef = null  # A Reaction's nightmare it rides on (Fx._attach), with its offset
	var follow_offset := Vector2.ZERO

	func _init(entry: Dictionary, tex: Texture2D, scale: float, seconds: float) -> void:
		_tex = tex
		_size = Vector2(entry.frame_size[0], entry.frame_size[1])
		_frames = maxi(int(entry.frames), 1)
		_fps = maxf(float(entry.fps), 1.0)
		_anchor = Vector2(entry.anchor[0], entry.anchor[1])
		_loop = bool(entry.loop)
		_scale = scale
		_seconds = seconds
		z_index = Fx.Z
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	func _process(delta: float) -> void:
		if follow != null:
			var target := Fx._followed(follow)
			if target != null:
				global_position = target.global_position + follow_offset
			else:
				follow = null  # Stays where it was last
		_age += delta
		var done := _age >= _seconds if (_loop and _seconds > 0.0) else (not _loop and _age * _fps >= _frames)
		if done:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var frame := int(_age * _fps)
		frame = frame % _frames if _loop else mini(frame, _frames - 1)
		if still >= 0:
			frame = mini(still, _frames - 1)
		var fade := 1.0
		if _loop and _seconds > 0.0:
			fade = clampf((_seconds - _age) / 0.3, 0.0, 1.0)  # Loops fade out over their last 0.3 s
		draw_texture_rect_region(_tex, Rect2(-_anchor * _scale, _size * _scale),
			Rect2(Vector2(_size.x * frame, _size.y * row), _size), Color(1, 1, 1, fade))


# A segment sheet tiled along +x for `length` pixels, fading out over the second half of its life.
class FxSegment extends Node2D:
	var still := -1  # >= 0: only this frame is drawn (reduced motion stills)
	var _tex: Texture2D
	var _size: Vector2
	var _frames: int
	var _fps: float
	var _anchor_y: float
	var _length: float
	var _seconds: float
	var _age := 0.0

	func _init(entry: Dictionary, tex: Texture2D, length: float, seconds: float) -> void:
		_tex = tex
		_size = Vector2(entry.frame_size[0], entry.frame_size[1])
		_frames = maxi(int(entry.frames), 1)
		_fps = maxf(float(entry.fps), 1.0)
		_anchor_y = float(entry.anchor[1])
		_length = length
		_seconds = maxf(seconds, 0.05)
		z_index = Fx.Z
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	func _process(delta: float) -> void:
		_age += delta
		if _age >= _seconds:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var frame := int(_age * _fps) % _frames if still < 0 else mini(still, _frames - 1)
		var alpha := clampf(2.0 * (1.0 - _age / _seconds), 0.0, 1.0)
		var x := 0.0
		while x < _length:
			var width := minf(_size.x, _length - x)
			draw_texture_rect_region(_tex, Rect2(x, -_anchor_y, width, _size.y),
				Rect2(_size.x * frame, 0, width, _size.y), Color(1, 1, 1, alpha))
			x += _size.x


# Monsoon's rain: the tiling sheet over a square, fading at the corners and in and out.
class FxRain extends Node2D:
	var _tex: Texture2D
	var _size: Vector2
	var _frames: int
	var _fps: float
	var _radius: float
	var _seconds: float
	var _age := 0.0

	func _init(entry: Dictionary, tex: Texture2D, radius: float, seconds: float) -> void:
		_tex = tex
		_size = Vector2(entry.frame_size[0], entry.frame_size[1])
		_frames = maxi(int(entry.frames), 1)
		_fps = maxf(float(entry.fps), 1.0)
		_radius = radius
		_seconds = maxf(seconds, 0.1)
		z_index = Fx.Z
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	func _process(delta: float) -> void:
		_age += delta
		if _age >= _seconds:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var frame := int(_age * _fps) % _frames
		var life := minf(_age / 0.15, 1.0) * clampf((_seconds - _age) / 0.25, 0.0, 1.0)
		var tiles := ceili(_radius / _size.x)
		for ty in range(-tiles, tiles):
			for tx in range(-tiles, tiles):
				var at := Vector2(tx, ty) * _size
				var reach := (at + _size / 2.0).length() / _radius
				if reach > 1.1:
					continue
				draw_texture_rect_region(_tex, Rect2(at, _size), Rect2(_size.x * frame, 0, _size.x, _size.y),
					Color(1, 1, 1, life * clampf(1.3 - reach, 0.0, 1.0)))


# A Reaction's name rising over the nightmare in its colour, with a little pop as it appears.
# The soft edgeless halo behind a callout word and the chain badge (the user's pick, "no pill"): a radial fade, Void
# 0.8 at the centre, 0.5 at 55%, 0 at the edge, an ellipse of half-size `half` round `centre`. Drawn as stacked
# ellipses whose alphas compose to that curve (no gradient texture: textures in statics crash at exit). `origin` /
# `scale` are the canvas transform the caller draws in; it's set back after.
const HALO_LAYERS := 10

static func draw_halo(canvas: CanvasItem, origin: Vector2, scale: float, centre: Vector2, half: Vector2, alpha: float = 1.0) -> void:
	var covered := 0.0  # Alpha so far at this ring (the layers outside it)
	for k in HALO_LAYERS:
		var r := 1.0 - float(k) / HALO_LAYERS  # Outer ring first
		var target := (0.8 - 0.3 * r / 0.55) if r <= 0.55 else 0.5 * (1.0 - r) / 0.45  # The curve's alpha at this ring
		var layer := clampf(1.0 - (1.0 - target) / maxf(1.0 - covered, 0.001), 0.0, 1.0)
		covered = 1.0 - (1.0 - covered) * (1.0 - layer)
		canvas.draw_set_transform(origin + centre * scale, 0.0, half * r * scale)
		canvas.draw_circle(Vector2.ZERO, 1.0, Color(Palette.VOID, layer * alpha))
	canvas.draw_set_transform(origin, 0.0, Vector2(scale, scale))

# The callout word (UI Asset's combat-callout redo, mock-up 3k6Xa3cvGTGFSvvHhuVZSd; the user: "that works"): the
# reaction's icon at ×2, then its name in Cormorant SemiBold 22 in its colour (no "!"), and a running chain's "×N"
# (number font 15, Glow). It pops 125% → 100% over 0.12 s, rises 18 px and fades over CALLOUT_LIFE. Specified at 1280:
# WorldLabel's text scale carries the UI factor (×1.5 at 1920) and the camera zoom. No pill (the user's pick): a 1 px
# Dread outline and the soft halo behind (Fx.draw_halo), padded 12 px up and down, 24 px each side.
# A Reaction burst's 1-frame bright flash (screens_ui.md 5f7852e2): a disc in the Reaction's colour, lightened, gone after
# REACTION_FLASH_SECONDS. Never made under reduce flashes (Fx.reaction checks).
class FxFlash extends Node2D:
	var _colour: Color
	var _radius: float
	var _age := 0.0

	func _init(colour: Color, radius: float) -> void:
		_colour = colour.lightened(0.55)
		_radius = radius
		z_index = Fx.Z + 1

	func _process(delta: float) -> void:
		_age += delta
		if _age >= Fx.REACTION_FLASH_SECONDS:
			queue_free()

	func _draw() -> void:
		draw_circle(Vector2.ZERO, _radius, Color(_colour, 0.55))
		draw_circle(Vector2.ZERO, _radius * 0.55, Color(_colour, 0.85))

class FxCallout extends Node2D:
	const TEXT_SIZE := 20  # Phones 24; Crowned 24 / 28 (screens_ui.md 5f7852e2)
	const TEXT_SIZE_PHONE := 24
	const TEXT_SIZE_CROWNED := 24
	const TEXT_SIZE_CROWNED_PHONE := 28
	const COUNT_SIZE := 15
	const ICON_PX := 32.0  # A 16 px icon at ×2
	const GAP := 6.0
	const POP_FROM := 0.7  # Pops in from 70%…
	const POP_OVER := 1.12  # …past full size…
	const POP_TIME := 0.12  # …and settles, over this long
	const RISE := 6.0  # As it fades
	const LIFT := 52.0  # Above the nightmare
	const HALO_PAD := Vector2(24.0, 12.0)  # The halo past the content: 24 px each side, 12 up and down
	var _text: String
	var _colour: Color
	var _icon: Texture2D
	var _count := 0
	var _repeat := 1  # The same Reaction on the same nightmare again while it holds: "×2"
	var _age := 0.0
	var _hold := Fx.CALLOUT_HOLD
	var _size := TEXT_SIZE
	var card_pip := false  # Reaction accent (C5): a small warm card pip before the word
	var key: StringName = &""
	var spot := Vector2.ZERO  # Where it was called (before stacking): the nightmare it belongs to (kept current while it follows)
	var follow: WeakRef = null  # The nightmare it rides on (Fx._attach), with its offset
	var follow_offset := Vector2.ZERO

	# Out of Fx's static list as it leaves (a static holding freed nodes crashed the engine's teardown).
	func _exit_tree() -> void:
		Fx._callouts_alive.erase(self)

	func _init(text: String, colour: Color, icon: Texture2D = null, crowned: bool = false) -> void:
		_text = text
		_colour = colour
		_icon = icon
		_hold = Fx.CALLOUT_HOLD_CROWNED if crowned else Fx.CALLOUT_HOLD
		var phone := UiStyle.is_phone()
		_size = (TEXT_SIZE_CROWNED_PHONE if phone else TEXT_SIZE_CROWNED) if crowned else (TEXT_SIZE_PHONE if phone else TEXT_SIZE)
		z_index = Fx.Z + 2

	func _life() -> float:
		return POP_TIME + _hold + Fx.CALLOUT_FADE

	# Still showing in full (not fading yet).
	func holding() -> bool:
		return _age < POP_TIME + _hold

	# The same Reaction again on its nightmare: count it and hold again.
	func bump() -> void:
		_repeat += 1
		_age = POP_TIME
		queue_redraw()

	# A running chain's length rides on it ("×3").
	func set_count(count: int) -> void:
		_count = count
		queue_redraw()

	func _process(delta: float) -> void:
		var target := Fx._followed(follow)
		if target != null:  # On its nightmare; once it's gone, where it was last
			global_position = target.global_position + follow_offset
			spot = target.global_position
		_age += delta
		if _age >= _life():
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var fading := clampf((_age - POP_TIME - _hold) / Fx.CALLOUT_FADE, 0.0, 1.0)
		var alpha := 1.0 - fading
		var p := clampf(_age / POP_TIME, 0.0, 1.0)
		var pop := lerpf(POP_FROM, POP_OVER, p / 0.7) if p < 0.7 else lerpf(POP_OVER, 1.0, (p - 0.7) / 0.3)
		var s := WorldLabel.text_scale(self) * pop  # Screen size when zoomed in, the UI factor, and the pop
		draw_set_transform(Vector2(0.0, -(LIFT + RISE * fading) * WorldLabel.text_scale(self)), 0.0, Vector2(s, s))
		var font := UiStyle.display_font()
		var count_font := UiStyle.number_font()
		var shown_count := _count if _count > 1 else _repeat
		var count_text := ("×%d" % shown_count) if shown_count > 1 else ""
		var text_w := font.get_string_size(_text, HORIZONTAL_ALIGNMENT_LEFT, -1, _size).x
		var count_w := count_font.get_string_size(count_text, HORIZONTAL_ALIGNMENT_LEFT, -1, COUNT_SIZE).x if count_text != "" else 0.0
		var icon_w := ICON_PX + GAP if _icon != null else 0.0
		var total := icon_w + text_w + (GAP + count_w if count_text != "" else 0.0)
		var x := -total / 2.0
		var baseline := font.get_ascent(_size) / 2.0 - 2.0  # The word centred on the line
		var origin := Vector2(0.0, -(LIFT + RISE * fading) * WorldLabel.text_scale(self))
		Fx.draw_halo(self, origin, s, Vector2.ZERO, Vector2(total / 2.0 + HALO_PAD.x, ICON_PX / 2.0 + HALO_PAD.y), alpha)
		if card_pip:  # A diamond, ember-edged so it reads on the pale path
			var c := Vector2(x - 8.0, 0.0)
			var outer := PackedVector2Array([c + Vector2(0, -6), c + Vector2(5, 0), c + Vector2(0, 6), c + Vector2(-5, 0)])
			var inner := PackedVector2Array([c + Vector2(0, -4), c + Vector2(3, 0), c + Vector2(0, 4), c + Vector2(-3, 0)])
			draw_colored_polygon(outer, Color(Palette.EMBER, alpha))
			draw_colored_polygon(inner, Color(Palette.HEARTLIGHT, alpha))
		if _icon != null:
			draw_texture_rect(_icon, Rect2(x, -ICON_PX / 2.0, ICON_PX, ICON_PX), false, Color(1, 1, 1, alpha))  # multiplier
			x += icon_w
		draw_string_outline(font, Vector2(x, baseline), _text, HORIZONTAL_ALIGNMENT_LEFT, -1, _size, 2, Color(Palette.DREAD, alpha))
		draw_string(font, Vector2(x, baseline), _text, HORIZONTAL_ALIGNMENT_LEFT, -1, _size, Color(_colour, alpha))
		if count_text != "":
			var cx := x + text_w + GAP
			draw_string_outline(count_font, Vector2(cx, baseline), count_text, HORIZONTAL_ALIGNMENT_LEFT, -1, COUNT_SIZE, 2, Color(Palette.DREAD, alpha))
			draw_string(count_font, Vector2(cx, baseline), count_text, HORIZONTAL_ALIGNMENT_LEFT, -1, COUNT_SIZE, Color(Palette.GLOW, alpha))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# The chain badge (the user's pick, the callout redo): no box, the same soft halo as the callout words. "chain" in
# Cormorant SC 12.5 (Mist) then "×N" (number font 21, 24 from ×5) in Glow, over a row of 5 pips: up to ×5 they fill
# Gold, at ×5 all five go bright Glow, from ×6 they count on toward 10. At ×10 the Dawnbreak icon ×1.5 and
# "Dawnbreak" (display 20, Glow). One badge, updated in place (set_count), fading 1 s after the last link.
class FxBadge extends Node2D:
	const HOLD := 1.0  # After the last link
	const FADE := 0.3
	const POP_TIME := 0.12
	const WORD_SIZE := 12.5
	const COUNT_SIZE := 21
	const COUNT_SIZE_BIG := 24  # From ×5
	const DAWN_SIZE := 20
	const PIP := Vector2(6.0, 3.0)
	const PIP_GAP := 3.0
	const HALO_PAD := Vector2(24.0, 12.0)
	var _count := 0
	var _age := 0.0
	var _dawn: Texture2D

	func _exit_tree() -> void:
		if Fx._badge == self:
			Fx._badge = null  # (See FxCallout._exit_tree)

	func _init(count: int) -> void:
		z_index = Fx.Z + 3
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_dawn = IconInfo.icon(&"dawnbreak")
		set_count(count)

	# A new link: the count goes up and the hold starts again (one badge, updated in place).
	func set_count(count: int) -> void:
		_count = count
		_age = 0.0
		queue_redraw()

	func _process(delta: float) -> void:
		_age += delta
		if _age >= HOLD + FADE:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var alpha := clampf((HOLD + FADE - _age) / FADE, 0.0, 1.0)
		var pop := lerpf(1.15, 1.0, clampf(_age / POP_TIME, 0.0, 1.0))
		var s := WorldLabel.text_scale(self) * pop
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(s, s))
		var caps := UiStyle.caps_font()
		var numbers := UiStyle.number_font()
		var display := UiStyle.display_font()
		var dawn := _count >= 10
		var word := "Dawnbreak" if dawn else "chain"
		var word_font := display if dawn else caps
		var word_size := DAWN_SIZE if dawn else int(round(WORD_SIZE))
		var word_w := word_font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, word_size).x
		var count_text := "" if dawn else "×%d" % _count
		var count_size := COUNT_SIZE_BIG if _count >= 5 else COUNT_SIZE
		var count_w := numbers.get_string_size(count_text, HORIZONTAL_ALIGNMENT_LEFT, -1, count_size).x if count_text != "" else 0.0
		var icon_w := 24.0 + 6.0 if dawn and _dawn != null else 0.0  # Dawnbreak's icon at ×1.5
		var line_w := icon_w + word_w + (6.0 + count_w if count_text != "" else 0.0)
		var pips_w := PIP.x * 5 + PIP_GAP * 4
		var total := maxf(line_w, pips_w)
		Fx.draw_halo(self, Vector2.ZERO, s, Vector2(0.0, 2.0), Vector2(total / 2.0 + HALO_PAD.x, 14.0 + HALO_PAD.y), alpha)
		var x := -line_w / 2.0
		var baseline := 4.0
		if icon_w > 0.0:
			draw_texture_rect(_dawn, Rect2(x, baseline - 20.0, 24.0, 24.0), false, Color(1, 1, 1, alpha))  # multiplier
			x += icon_w
		var word_colour := Palette.GLOW if dawn else Palette.MIST
		draw_string_outline(word_font, Vector2(x, baseline), word, HORIZONTAL_ALIGNMENT_LEFT, -1, word_size, 2, Color(Palette.DREAD, alpha))
		draw_string(word_font, Vector2(x, baseline), word, HORIZONTAL_ALIGNMENT_LEFT, -1, word_size, Color(word_colour, alpha))
		if count_text != "":
			var cx := x + word_w + 6.0
			draw_string_outline(numbers, Vector2(cx, baseline), count_text, HORIZONTAL_ALIGNMENT_LEFT, -1, count_size, 2, Color(Palette.DREAD, alpha))
			draw_string(numbers, Vector2(cx, baseline), count_text, HORIZONTAL_ALIGNMENT_LEFT, -1, count_size, Color(Palette.GLOW, alpha))
		# The pips: Gold up to ×5, all Glow at ×5, then counting on toward 10.
		var lit := mini(_count, 5) if _count <= 5 else mini(_count - 5, 5)
		var px := -pips_w / 2.0
		for i in 5:
			var on := i < lit
			var colour := Palette.GLOW if _count == 5 or (_count > 5 and on) or dawn else (Palette.GOLD if on else Palette.DUSK)
			if _count > 5 and not on and not dawn:
				colour = Palette.GOLD  # The first five stay full under the second count
			draw_rect(Rect2(px + i * (PIP.x + PIP_GAP), baseline + 6.0, PIP.x, PIP.y), Color(colour, alpha))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
