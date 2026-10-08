extends Node2D
## Side-profile quadruped walk (shared by all Cattles; assets face LEFT). Self-propels
## between left_bound/right_bound and flips to face travel. Draw order lives in the .tscn.
##
## Gait: 4-beat cow walk. Each leg spends `duty` of the cycle planted, sweeping back
## linearly (stance), then lifts and swings forward (swing). The cycle rate is derived
## from move_speed and leg length so planted hooves move exactly with the ground (no
## sliding). Legs: Leg1 far front, Leg2 near front, Leg3 far back, Leg4 near back.
## A leg may have a "Lower" child (knee rig): during swing it folds back at the knee,
## which lifts the hoof; rigid legs (no Lower) get a straight vertical lift instead.

@export var swing: float = 0.22    ## half the leg sweep (radians, ~12.5deg)
@export var duty: float = 0.65     ## fraction of the cycle each hoof is on the ground
@export var lift: float = 14.0     ## hoof lift during swing (px, unscaled)
@export var bob: float = 3.0       ## body dip per step (px, unscaled)
@export var knee_bend: float = 0.7 ## max knee fold during swing (radians), knee rigs only
@export var move_speed: float = 70.0
@export var left_bound: float = 560.0
@export var right_bound: float = 900.0
## cycle phase offset per leg (Leg1..Leg4). Default = lateral walk:
## near back -> near front -> far back -> far front.
@export var phases: Vector4 = Vector4(0.75, 0.25, 0.5, 0.0)
## >0: fixed gait cycles/sec instead of the no-slide derivation. Use with swing = 0 for
## a front-ish 3/4 rig that stomps in place (hooves lift, no fore-aft sweep, so the
## gait has no direction to read "backwards").
@export var step_rate: float = 0.0
## Driven by a Director (episodes): the Actor wrapper owns travel and facing, the gait
## runs only while `walking`, and the legs rest in their base pose otherwise.
@export var directed: bool = false
var walking: bool = true

var _p: float = 0.0                ## cycle phase, 0..1
var _dir: float = -1.0             ## start walking left (asset's natural facing)
var _bs: float = 1.0
var _freq: float = 1.0             ## cycles per second
var _legs: Array[Sprite2D] = []
var _base: Array[Vector2] = []
var _lower: Array[Sprite2D] = []   ## knee child per leg, or null
@onready var _body: Sprite2D = $Body

func _ready() -> void:
	_bs = absf(scale.x)
	_legs = [$Leg1, $Leg2, $Leg3, $Leg4]
	var total_len := 0.0
	for leg in _legs:
		_base.append(leg.position)
		_lower.append(leg.get_node_or_null("Lower"))
		total_len += _leg_length(leg)
	var leg_len := total_len / _legs.size()
	# stance sweeps the hoof 2*swing*leg_len (local px) in duty/_freq seconds;
	# match that to the ground moving past at move_speed (screen px)
	if step_rate > 0.0:
		_freq = step_rate
	else:
		_freq = move_speed * duty / (2.0 * swing * leg_len * _bs)

## Pivot-to-hoof distance in texture px (hoof = lowest opaque row of the leg, or of
## its Lower part on a knee rig).
func _leg_length(leg: Sprite2D) -> float:
	var part: Sprite2D = leg.get_node_or_null("Lower")
	if part == null:
		part = leg
	var img := part.texture.get_image()
	var pivot_y := leg.position.y + img.get_height() / 2.0
	return maxf(float(img.get_used_rect().end.y) - pivot_y, 40.0)

func _process(delta: float) -> void:
	if directed and not walking:
		for i in _legs.size():
			_legs[i].rotation = 0.0
			_legs[i].position = _base[i]
			if _lower[i]:
				_lower[i].rotation = 0.0
		_body.position.y = 0.0
		return
	_p = fposmod(_p + delta * _freq, 1.0)
	for i in _legs.size():
		var q := fposmod(_p + phases[i], 1.0)
		var leg := _legs[i]
		if q < duty:
			# stance: hoof planted, sweeps from forward (+swing) to back (-swing)
			leg.rotation = lerpf(swing, -swing, q / duty)
			leg.position = _base[i]
			if _lower[i]:
				_lower[i].rotation = 0.0
		else:
			# swing: lift and carry the hoof forward again
			var s := (q - duty) / (1.0 - duty)
			leg.rotation = lerpf(-swing, swing, smoothstep(0.0, 1.0, s))
			if _lower[i]:
				# fold the lower leg back (hoof moves backward + up), then straighten
				_lower[i].rotation = -knee_bend * sin(PI * s)
				leg.position = _base[i]
			else:
				leg.position = _base[i] + Vector2(0.0, -lift * sin(PI * s))
	# body dips slightly twice per cycle (once per front/back pair)
	_body.position.y = bob * 0.5 * (1.0 - cos(TAU * 2.0 * _p))
	if directed:
		return

	# travel + face direction (asset faces left, so flip when going right)
	position.x += _dir * move_speed * delta
	if position.x < left_bound:
		_dir = 1.0
	elif position.x > right_bound:
		_dir = -1.0
	scale.x = _bs * -_dir
