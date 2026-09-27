extends Resource
class_name ReactionData

# One Reaction (tower_design.md "Reactions", numbers in dream_design.md "Reaction numbers"): a named
# event when two statuses meet on one nightmare. The rules live in Reactions (one handler per id);
# this is the data the UI, effects and tuning read.

@export var id: StringName = &""
@export var display_name: String = ""  # Callout text without the "!"
@export var statuses: Array[StringName] = []  # The two it needs, for the Codex ("Damp + Static")
# Statuses that can stand in for the second one (Pinned: full Drowsy instead of Held).
@export var alternatives: Array[StringName] = []
@export_multiline var description: String = ""
@export var callout_color: Color = Color.WHITE
@export var effect: StringName = &""  # assets/effects/effects.json entry
@export var effect_scale: float = 1.5  # The sheets peak small in their frames; played bigger
@export var cooldown: float = 1.5  # Seconds before it can fire again on the same nightmare

func get_callout() -> String:
	return display_name + "!"
