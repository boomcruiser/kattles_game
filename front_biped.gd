extends Node2D
## Front-facing upright biped walk (e.g. Lieutenant Leather). Parts: LegL, LegR (behind
## the body), Body, ArmL, ArmR (in front). A march: each leg lifts in turn with a small
## sideways step, arms swing inward in turn, body dips per step and rocks toward the
## planted leg. Self-propels between left_bound/right_bound and mirrors to face travel.
## Math is mirrored in tools/cut_front_biped.py (pose()) for the filmstrip check.

@export var steps_per_sec: float = 1.8  ## full L+R cycles per second
@export var lift: float = 14.0          ## foot lift (px, unscaled)
@export var stride: float = 6.0         ## sideways foot shift (px, unscaled)
@export var arm_swing: float = 0.12     ## arm sway (radians)
@export var arm_l_amount: float = 1.0   ## per-arm swing multiplier (0 = arm holds still,
@export var arm_r_amount: float = 1.0   ## e.g. a hand that covers the tail root)
@export var bob: float = 4.0            ## body dip per step (px, unscaled)
@export var tilt: float = 0.025         ## body rock toward the planted leg (radians)
@export var faces_left: bool = false    ## art is turned toward the left (else right)
@export var move_speed: float = 55.0
@export var left_bound: float = 120.0
@export var right_bound: float = 840.0

var _p: float = 0.0
var _dir: float = 1.0
var _bs: float = 1.0
@onready var _body: Sprite2D = $Body
@onready var _leg_l: Sprite2D = $LegL
@onready var _leg_r: Sprite2D = $LegR
@onready var _arm_l: Sprite2D = $ArmL
@onready var _arm_r: Sprite2D = $ArmR
@onready var _base := {
	_body: _body.position, _leg_l: _leg_l.position, _leg_r: _leg_r.position,
}

func _ready() -> void:
	_bs = absf(scale.x)

func _process(delta: float) -> void:
	_p = fposmod(_p + delta * steps_per_sec, 1.0)
	var s := sin(TAU * _p)
	_leg_l.position = _base[_leg_l] + Vector2(stride * s, -lift * maxf(0.0, s))
	_leg_r.position = _base[_leg_r] + Vector2(-stride * s, -lift * maxf(0.0, -s))
	# arms only swing inward (over the torso); an outward swing would open a gap
	# where the forearm was cut out of the body
	_arm_l.rotation = -arm_swing * arm_l_amount * maxf(0.0, -s)
	_arm_r.rotation = arm_swing * arm_r_amount * maxf(0.0, s)
	_body.position = _base[_body] + Vector2(0.0, bob * 0.5 * (1.0 - cos(2.0 * TAU * _p)))
	_body.rotation = tilt * s

	# travel; art is mirrored so it faces the direction of travel
	position.x += _dir * move_speed * delta
	if position.x < left_bound:
		_dir = 1.0
	elif position.x > right_bound:
		_dir = -1.0
	scale.x = _bs * (-_dir if faces_left else _dir)
