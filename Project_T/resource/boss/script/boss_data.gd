extends Resource
class_name BossData

# One entry in an act's boss pool (documentation/enemy_design.md, "Bosses: a pool of 3 per act").
# Each run draws one BossData per act (BossPool); its `drift` replaces the act's boss drift (25, 50,
# 75, 100), so the dossier, the banner and the drift bookkeeping all follow the draw.

@export var id: String = ""  # Unique id (saves, the profile's last_bosses). Empty = the .tres file name
@export var act: int = 1
@export var boss: EnemyData  # The great nightmare itself (its dossier data lives on it)
@export var drift: DriftData  # The whole boss drift: escort groups and the boss
# A player's first run ever meets this one in its act (the Hollow Stag, the Thorned Oak), and the
# demo always does (demo_scope.md).
@export var is_default: bool = false

func get_id() -> String:
	return id if id != "" else resource_path.get_file().get_basename()
