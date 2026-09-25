extends Node2D
## Rusty puppet — procedural walk/idle from cutout parts (body + 2 feet).
## PoC v1: feet translate (lift + stride), body bobs + tilts. No skeleton yet.

@export var walking: bool = true
@export var speed: float = 8.0      ## gait cycle speed
@export var stride: float = 14.0    ## foot forward/back travel (px)
@export var lift: float = 18.0      ## foot lift height (px)
@export var bob: float = 10.0       ## body vertical bob (px)
@export var tilt: float = 0.03      ## body sway (radians)

var _t: float = 0.0
@onready var _body: Sprite2D = $Body
@onready var _foot_l: Sprite2D = $FootL
@onready var _foot_r: Sprite2D = $FootR

func _process(delta: float) -> void:
	if walking:
		_t += delta * speed
		var pl := sin(_t)
		var pr := sin(_t + PI)
		# feet: swing forward/back + lift on the up-phase
		_foot_l.position = Vector2(stride * pl, -lift * maxf(0.0, pl))
		_foot_r.position = Vector2(stride * pr, -lift * maxf(0.0, pr))
		# body bobs twice per stride, sways side to side
		_body.position.y = -bob * absf(sin(_t))
		_body.rotation = tilt * sin(_t)
	else:
		# idle: gentle breathing
		_t += delta * 2.0
		var b := sin(_t)
		_body.position.y = -2.0 * b
		_body.rotation = 0.008 * b
		_foot_l.position = Vector2.ZERO
		_foot_r.position = Vector2.ZERO
