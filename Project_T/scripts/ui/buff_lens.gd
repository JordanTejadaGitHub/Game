extends RefCounted
class_name BuffLens

# The buff lens switch (screens_ui.md "Buff readability", Tower Discussion 7cd3c5a): the HUD's "Buffs"
# toggle and the buff_lens action (V) turn it on and off; a toggle, not hold-only, for touch. The lens
# itself (pips, threads, aura areas) is Tower Code's: its node joins GROUP, reads `on` when it's made,
# and gets set_lens(on) on every change.

const GROUP := &"buff_lens"
static var on := false

static func set_on(tree: SceneTree, value: bool) -> void:
	on = value
	if tree != null:
		tree.call_group(GROUP, "set_lens", value)

static func toggle(tree: SceneTree) -> void:
	set_on(tree, not on)
