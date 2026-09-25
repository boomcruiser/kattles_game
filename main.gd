extends Node2D
## PoC demo: Rusty patrols left/right across the screen, flipping to face travel.

@export var move_speed: float = 90.0
var _dir: float = 1.0
@onready var _rusty: Node2D = $Rusty
var _base_scale: float

func _ready() -> void:
	_base_scale = absf(_rusty.scale.x)

func _process(delta: float) -> void:
	_rusty.position.x += _dir * move_speed * delta
	if _rusty.position.x > 560.0:
		_dir = -1.0
	elif _rusty.position.x < 180.0:
		_dir = 1.0
	# face direction of travel
	_rusty.scale.x = _base_scale * _dir
