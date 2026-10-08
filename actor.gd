class_name Actor
extends Node2D
## Director-side wrapper around a puppet (Rusty / front_biped / side_quad rig). Owns
## travel, facing, talk-bob, idle breathing and squash/hop. Origin = feet on the ground,
## so scaling squashes toward the floor.

signal arrived

var puppet: Node2D
var height: float = 200.0        ## on-screen height (world px at zoom 1)
var natural_dir: float = -1.0    ## direction the art faces: -1 left, +1 right
var facing: float = -1.0
var speed: float = 60.0
var talking: bool = false
var squash: Vector2 = Vector2.ONE  ## tweened by the Director (pop, hop)

var _target: float = NAN
var _t: float = 0.0

## `path` = puppet scene; it is scaled so its full height is `h` and its feet sit on
## this node's origin.
func setup(path: String, h: float) -> void:
	puppet = load(path).instantiate()
	height = h
	var ext := _extent(puppet)
	var k := h / (ext.y - ext.x)
	puppet.scale = Vector2(k, k)
	puppet.position = Vector2(0.0, -ext.y * k)
	puppet.set("directed", true)
	puppet.set("self_propel", false)   # Rusty
	if puppet.get_script().resource_path.ends_with("rusty.gd"):
		natural_dir = 1.0
	elif puppet.get_script().resource_path.ends_with("front_biped.gd"):
		natural_dir = -1.0 if puppet.get("faces_left") else 1.0
	var ms = puppet.get("move_speed")
	if ms != null:
		speed = ms
	add_child(puppet)
	_set_walking(false)
	facing = natural_dir

func walk_to(x: float, speed_mul: float = 1.0) -> void:
	_target = x
	_speed_mul = speed_mul
	if absf(x - position.x) > 0.5:
		facing = signf(x - position.x)
		_set_walking(true)

var _speed_mul: float = 1.0

func head_pos() -> Vector2:
	return global_position + Vector2(0.0, -height * squash.y)

func _process(delta: float) -> void:
	if not is_nan(_target):
		var dx := _target - position.x
		var step := speed * _speed_mul * delta
		if absf(dx) <= step:
			position.x = _target
			_target = NAN
			_set_walking(false)
			arrived.emit()
		else:
			position.x += signf(dx) * step
	_t += delta
	var sy := 1.0 + 0.012 * sin(_t * 2.2)              # idle breathing
	if talking:
		sy += 0.035 * absf(sin(_t * 13.0))             # talk bounce
	scale = Vector2(facing * natural_dir * squash.x, squash.y * sy)

func _set_walking(on: bool) -> void:
	puppet.set("walking", on)

## Vertical extent of the puppet in canvas px relative to texture center:
## x = top of the highest part, y = bottom of the lowest (feet).
static func _extent(p: Node2D) -> Vector2:
	var top := INF
	var bottom := -INF
	for part in p.find_children("*", "Sprite2D", true, false):
		var img: Image = (part as Sprite2D).texture.get_image()
		var r := img.get_used_rect()
		top = minf(top, r.position.y - img.get_height() / 2.0)
		bottom = maxf(bottom, r.end.y - img.get_height() / 2.0)
	return Vector2(top, bottom)
