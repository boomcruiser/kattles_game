extends Node2D
## Rusty puppet — procedural walk/idle from cutout parts (body + 2 feet).
## PoC v1: feet translate (lift + stride), body bobs + tilts. No skeleton yet.

@export var walking: bool = true
@export var speed: float = 8.0      ## gait cycle speed
@export var stride: float = 14.0    ## foot forward/back travel (px)
@export var lift: float = 18.0      ## foot lift height (px)
@export var bob: float = 10.0       ## body vertical bob (px)
@export var tilt: float = 0.03      ## body sway (radians)
## Walk back and forth on its own (the viewer turns this on; the old Main stage moves
## Rusty from main.gd instead, so it stays off there). Art faces right.
@export var self_propel: bool = false
@export var move_speed: float = 60.0
@export var left_bound: float = 120.0
@export var right_bound: float = 840.0

var _dir: float = 1.0
var _bs: float = 1.0

func _ready() -> void:
	_bs = absf(scale.x)

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
		if self_propel:
			position.x += _dir * move_speed * delta
			if position.x < left_bound:
				_dir = 1.0
			elif position.x > right_bound:
				_dir = -1.0
			scale.x = _bs * _dir
	else:
		# idle: gentle breathing
		_t += delta * 2.0
		var b := sin(_t)
		_body.position.y = -2.0 * b
		_body.rotation = 0.008 * b
		_foot_l.position = Vector2.ZERO
		_foot_r.position = Vector2.ZERO
