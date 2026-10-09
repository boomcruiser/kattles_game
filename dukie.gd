extends Node2D
## Dukie: one painted sprite (assets/props/dukie.png, faces right), no rig yet.
## While walking he trots with a bouncy hop and a little rock.

@export var move_speed: float = 110.0
@export var natural_dir: float = 1.0
@export var hop: float = 30.0          ## trot hop height, canvas px
@export var trot_rate: float = 13.0    ## hops per ~half second

var directed: bool = true
var walking: bool = false
var _t: float = 0.0
@onready var body: Sprite2D = $Body

func _process(delta: float) -> void:
	_t += delta
	if walking:
		body.position.y = -absf(sin(_t * trot_rate)) * hop
		body.rotation = sin(_t * trot_rate) * 0.05
	else:
		body.position.y = lerpf(body.position.y, 0.0, 0.3)
		body.rotation = lerpf(body.rotation, 0.0, 0.3)
