extends Node2D
## Buttercup — SIDE-PROFILE walk (asset faces LEFT). 4 legs swing from the hip in a
## diagonal gait (leg1+leg4 vs leg2+leg3), body bobs. Self-propels + flips to face travel.

@export var gait: float = 6.0      ## leg cycle speed (crank up = run)
@export var swing: float = 0.26    ## leg swing amplitude (radians, ~15deg)
@export var bob: float = 8.0       ## body bounce (px)
@export var move_speed: float = 70.0
@export var left_bound: float = 560.0
@export var right_bound: float = 900.0

var _t: float = 0.0
var _dir: float = -1.0             ## start walking left (asset's natural facing)
var _bs: float = 1.0
@onready var _body: Sprite2D = $Body
@onready var _l1: Sprite2D = $Leg1
@onready var _l2: Sprite2D = $Leg2
@onready var _l3: Sprite2D = $Leg3
@onready var _l4: Sprite2D = $Leg4

func _ready() -> void:
	_bs = absf(scale.x)

func _process(delta: float) -> void:
	_t += delta * gait
	var pl := sin(_t)
	var pr := sin(_t + PI)
	# diagonal gait: outer front + outer back together, inner pair opposite
	_l1.rotation = swing * pl
	_l4.rotation = swing * pl
	_l2.rotation = swing * pr
	_l3.rotation = swing * pr
	_body.position.y = -bob * absf(sin(_t))

	# travel + face direction (asset faces left, so flip when going right)
	position.x += _dir * move_speed * delta
	if position.x < left_bound:
		_dir = 1.0
	elif position.x > right_bound:
		_dir = -1.0
	scale.x = _bs * -_dir
