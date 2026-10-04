extends Node2D
## Character review stage: one puppet at a time, big and centered, walking back and
## forth. Left/Right (or A/D) switch characters.

const CHARACTERS := [
	"res://Whispy.tscn",
	"res://Puffalo.tscn",
	"res://Moosteam.tscn",
	"res://Snortle.tscn",
	"res://Clatterhoof.tscn",
	"res://Bubblehorn.tscn",
	"res://InspectorVapour.tscn",
	"res://Steamy.tscn",
	"res://Hissy.tscn",
	"res://Grimey.tscn",
	"res://Bubbly.tscn",
	"res://Brewster.tscn",
	"res://Boilbert.tscn",
	"res://Wanderella.tscn",
	"res://Nocturna.tscn",
	"res://LieutenantLeather.tscn",
	"res://Spotilda.tscn",
	"res://Buttercup.tscn",
	"res://Daisybell.tscn",
	"res://Fluffhorn.tscn",
	"res://Moozie.tscn",
]
const GROUND_Y := 470.0
const TARGET_HEIGHT := 400.0   ## on-screen height each puppet is scaled to

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
	var ext := _extent(_current)
	var k := TARGET_HEIGHT / (ext.y - ext.x)
	_current.scale = Vector2(k, k)
	_current.position = Vector2(480.0, GROUND_Y - ext.y * k)
	_current.set("left_bound", 260.0)
	_current.set("right_bound", 700.0)
	add_child(_current)
	_label.text = "%s   (%d/%d)   ← → to switch" % [_current.name, _i + 1, CHARACTERS.size()]

## Vertical extent of the puppet in canvas px relative to texture center:
## x = top of the highest part, y = bottom of the lowest (feet).
func _extent(puppet: Node2D) -> Vector2:
	var top := INF
	var bottom := -INF
	for part in puppet.find_children("*", "Sprite2D", true, false):
		var img: Image = (part as Sprite2D).texture.get_image()
		var r := img.get_used_rect()
		top = minf(top, r.position.y - img.get_height() / 2.0)
		bottom = maxf(bottom, r.end.y - img.get_height() / 2.0)
	return Vector2(top, bottom)
