extends ConfirmationDialog
class_name BlightPicker

# Pick a Blight Level before a run (meta_design.md "Blight Levels"): opens after the first win, each
# level adds its modifier on top of the ones below it, +10% Seeds per level. Emits `picked(level)`.

signal picked(level: int)

const LEVELS: Array[String] = [
	"No Blight",
	"Nightmares +10% health",
	"Starting Dew −20",
	"Bosses +25% health",
	"Rest bonus −25%",
	"One nightmare per drift is Deeply Blighted",
	"No leaves regrow at act breaks",
	"Nightmares +10% speed",
	"Let it pass gives no Dew · Dreams lean Common",
	"Clearing obstacles costs twice as much",
	"The Hollow Oak Remembers",
]

var _pick := OptionButton.new()
var _detail := Label.new()

func _init() -> void:
	title = "Blight Level"
	ok_button_text = "Start run"
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(420, 0)
	_pick.item_selected.connect(_describe)
	box.add_child(_pick)
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_detail)
	add_child(box)
	confirmed.connect(func() -> void: picked.emit(_pick.selected))

# Shows levels 0..`max_level` (the highest you may pick).
func open(max_level: int) -> void:
	_pick.clear()
	for level in max_level + 1:
		_pick.add_item("Level %d" % level if level > 0 else "No Blight")
	_pick.selected = mini(MetaRun.blight_level, max_level)
	_describe(_pick.selected)
	popup_centered()

func _describe(level: int) -> void:
	var lines: Array[String] = []
	for i in range(1, level + 1):
		lines.append("%d. %s" % [i, LEVELS[i]])
	_detail.text = ("\n".join(lines) + "\n\n+%d%% Seeds" % (level * 10)) if level > 0 else "The forest as it is."
