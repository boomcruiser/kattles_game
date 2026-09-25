extends Node2D
## Character review stage: one puppet at a time, big and centered, walking back and
## forth. Left/Right (or A/D) switch characters.

const CHARACTERS := [
	"res://Spotilda.tscn",
	"res://Buttercup.tscn",
	"res://Daisybell.tscn",
	"res://Fluffhorn.tscn",
	"res://Moozie.tscn",
]
const GROUND_Y := 470.0
const SCALE := 0.5

var _i: int = 0
var _current: Node2D
@onready var _label: Label = $Label

func _ready() -> void:
	_show(0)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_right") or (event is InputEventKey and event.pressed and event.keycode == KEY_D):
		_show(_i + 1)
	elif event.is_action_pressed("ui_left") or (event is InputEventKey and event.pressed and event.keycode == KEY_A):
		_show(_i - 1)

func _show(i: int) -> void:
	_i = posmod(i, CHARACTERS.size())
	if _current:
		_current.queue_free()
	_current = load(CHARACTERS[_i]).instantiate()
	# bounds must be set before the puppet's _ready (it reads them each frame, but
	# its step rate is computed from move_speed/scale at _ready)
	_current.scale = Vector2(SCALE, SCALE)
	_current.position = Vector2(480.0, GROUND_Y - _hoof_below_center(_current) * SCALE)
	_current.set("left_bound", 260.0)
	_current.set("right_bound", 700.0)
	add_child(_current)
	_label.text = "%s   (%d/%d)   ← → to switch" % [_current.name, _i + 1, CHARACTERS.size()]

## Canvas px from texture center down to the lowest hoof (from the leg textures).
func _hoof_below_center(puppet: Node2D) -> float:
	var lowest := 0.0
	for leg in ["Leg1", "Leg2", "Leg3", "Leg4"]:
		var part: Sprite2D = puppet.get_node(leg).get_node_or_null("Lower")
		if part == null:
			part = puppet.get_node(leg)
		var img := part.texture.get_image()
		lowest = maxf(lowest, img.get_used_rect().end.y - img.get_height() / 2.0)
	return lowest
