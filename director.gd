class_name Director
extends Node2D
## Rough-cut episode runner. An episode is a script with `func run(d: Director)` that
## builds its set, spawns actors, then awaits Director calls in order (walk, say, cam,
## wait, ...). Missing art/audio is stood in for by slug cards, stage-direction
## captions and floating sfx text. Keys: R replay, Esc quit. When recording with
## --write-movie the game quits as soon as the episode ends.

@export_file("*.gd") var episode: String = "res://episodes/ep1.gd"
## Global pacing: scales every walk, tween, wait and particle (Engine.time_scale).
@export var speed: float = 1.25

var actors: Dictionary = {}          ## id -> Actor
@onready var world: Node2D = $World
@onready var cam: Camera2D = $Camera2D
@onready var ui: CanvasLayer = $UI

const SCREEN := Vector2(960, 540)
var _shake: float = 0.0
var _caption: Label
var _card: ColorRect
var _card_label: Label
var _flash: ColorRect
var _puff: Texture2D

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():             # godot ... -- --from=<section>
		if arg.begins_with("--from="):
			_skip_to = arg.trim_prefix("--from=")
	Engine.time_scale = FAST_FORWARD if _skip_to else speed
	_build_ui()
	var ep = load(episode).new()
	await ep.run(self)
	if Engine.get_write_movie_path() != "":
		get_tree().quit()
	else:
		caption("[ END — R to replay, Esc to quit ]")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			get_tree().reload_current_scene()
		elif event.keycode == KEY_ESCAPE:
			get_tree().quit()

func _process(delta: float) -> void:
	clock += delta
	cam.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake
	_shake = move_toward(_shake, 0.0, delta * 30.0)
	for t in _tethers:
		if is_instance_valid(t[0]):
			_hang(t[0], t[1].call(), t[2].call())

# ---------------------------------------------------------------- actors

## Spawn a puppet scene as actor `id`, `h` px tall, feet at `pos`. z: draw order vs set
## pieces (e.g. behind/in front of jail bars). facing: -1/+1, 0 = art's own facing.
func spawn(id: String, path: String, pos: Vector2, h: float, z: int = 0, facing: float = 0.0) -> Actor:
	var a := Actor.new()
	a.name = id
	a.setup(path, h)
	a.position = pos
	a.z_index = z
	if facing != 0.0:
		a.facing = facing
	world.add_child(a)
	actors[id] = a
	return a

## Walk actor to x (awaitable). speed_mul > 1 hurries (feet may skate a little).
func walk(id: String, x: float, speed_mul: float = 1.0) -> void:
	var a: Actor = actors[id]
	a.walk_to(x, speed_mul)
	if a.puppet.get("walking"):
		await a.arrived

## Free every actor (new scene, new cast). Set dressing stays where it was.
func reset_actors() -> void:
	for a in actors.values():
		(a as Node).queue_free()
	actors.clear()
	_tethers.clear()

## A rope between two moving points (a leash). `from` / `to` are Callables returning
## world positions; it sags when slack and pulls straight when taut.
func tether(from: Callable, to: Callable, color: Color = Color("5a3420"), width: float = 4.0, z: int = 3) -> Line2D:
	var l := line(PackedVector2Array(), color, width, z)
	_tethers.append([l, from, to])
	_hang(l, from.call(), to.call())
	return l

var _tethers: Array = []

func _hang(l: Line2D, a: Vector2, b: Vector2) -> void:
	var sag := clampf(140.0 - a.distance_to(b) * 0.45, 4.0, 90.0)
	var mid := (a + b) * 0.5 + Vector2(0, sag)
	var pts := PackedVector2Array()
	for i in 13:
		var t := i / 12.0
		pts.append(a.lerp(mid, t).lerp(mid.lerp(b, t), t))
	l.points = pts

func face(id: String, dir: float) -> void:
	(actors[id] as Actor).facing = dir

## A line of dialogue as a subtitle while the actor talk-bobs for the time it takes to
## say it, holds, then clears. opts: shout (bigger), think (grey, in parentheses, no
## talk-bob), hold (secs after speaking), keep (leave it up until the next line / clear()).
## If `<audio_dir>/vo/<id>_<slug(text)>.mp3` exists (tools/gen_audio.py) it plays and
## the talk-bob lasts exactly as long as the recording.
func say(id: String, text: String, opts: Dictionary = {}) -> void:
	var a: Actor = actors[id]
	var shout: bool = opts.get("shout", false)
	var think: bool = opts.get("think", false)
	_show_sub("(%s)" % text if think else text, 34 if shout else 24,
		Color(0.8, 0.8, 0.85) if think else Color.WHITE)
	_sub_owner = id
	var line := _sub_serial
	var vo := _play("vo/%s_%s" % [id, _slug(text)])
	a.talking = not think
	if vo:
		await wait(vo.stream.get_length() * speed)        # real seconds -> game seconds
	else:
		await wait(text.length() * (0.025 if shout else 0.045))
	a.talking = false
	await wait(opts.get("hold", (vo_hold + text.length() * vo_hold_per_char) if vo else (0.9 + text.length() * 0.035)))
	if not opts.get("keep", false) and _sub_serial == line:
		sub("")

## Clear the subtitle if it is still this actor's line.
func clear(id: String) -> void:
	if _sub_owner == id:
		sub("")

## Raw subtitle (song lyrics, sound cues); "" clears.
func sub(text: String, color: Color = Color.WHITE, size: int = 24) -> void:
	_show_sub(text, size, color)
	_sub_owner = ""

func _show_sub(text: String, size: int, color: Color) -> void:
	_sub_serial += 1
	_subs.text = text
	_subs.label_settings.font_size = size
	_subs.label_settings.font_color = color
	_subs.visible = text != ""

## Default pause after a voiced line (secs + per character); a scene can tighten it.
var vo_hold: float = 0.5
var vo_hold_per_char: float = 0.015

var _subs: Label
var _sub_owner: String = ""
var _sub_serial: int = 0

## Squash-and-hop (surprise, lid pop).
func pop(id: String, big: float = 1.0) -> void:
	var a: Actor = actors[id]
	var y0 := a.position.y
	var tw := create_tween()
	tw.tween_property(a, "squash", Vector2(1.2, 0.75), 0.07)
	tw.tween_property(a, "squash", Vector2(0.85, 1.25), 0.1)
	tw.parallel().tween_property(a, "position:y", y0 - 45.0 * big, 0.14).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(a, "position:y", y0, 0.16).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.parallel().tween_property(a, "squash", Vector2.ONE, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	await tw.finished

## Hop and flip head-over-heels around the body's middle (playful spin).
func spin(id: String, turns: float = 1.0, dur: float = 0.7, hop: float = 70.0) -> void:
	var a: Actor = actors[id]
	var feet := a.position
	var tw := create_tween()
	tw.tween_method(func(t: float):
		var th := -a.facing * TAU * turns * t
		var mid := feet + Vector2(0, -a.height * 0.5 - hop * sin(PI * t))
		a.rotation = th
		a.position = mid + Vector2(0, a.height * 0.5).rotated(th), 0.0, 1.0, dur).set_trans(Tween.TRANS_SINE)
	await tw.finished
	a.rotation = 0.0
	a.position = feet

## Bob to a beat (loops `beats` times, `period` secs per beat): nodding along to music.
func groove(id: String, period: float = 0.46, beats: int = 8) -> void:
	var a: Actor = actors[id]
	var tw := create_tween().set_loops(beats)
	tw.tween_property(a, "squash", Vector2(1.06, 0.92), period * 0.35).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(a, "squash", Vector2.ONE, period * 0.65).set_trans(Tween.TRANS_QUAD)

## Steam puffs from the actor's lid/head (tint for smoke / rust dust).
func steam(id: String, amount: int = 10, big: float = 1.0, tint: Color = Color.WHITE) -> void:
	var a: Actor = actors[id]
	puff(a.head_pos() + Vector2(0, 0.12 * a.height), amount, big, tint, a.z_index + 1)

## Steam/smoke puffs at a world position. `loop` keeps emitting (chimneys, spouts) and
## returns the emitter so the caller can stop it.
func puff(pos: Vector2, amount: int = 10, big: float = 1.0, tint: Color = Color.WHITE, z: int = 1, loop: bool = false) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.texture = _puff_tex()
	p.one_shot = not loop
	p.amount = amount
	p.lifetime = 1.6 if not loop else 3.0
	p.explosiveness = 0.85 if not loop else 0.0
	p.direction = Vector2(0, -1)
	p.spread = 30.0 + 25.0 * big
	p.initial_velocity_min = 50.0 * big
	p.initial_velocity_max = 130.0 * big
	p.gravity = Vector2(0, -15)
	p.damping_min = 20.0
	p.damping_max = 40.0
	p.scale_amount_min = 0.5 * big
	p.scale_amount_max = 1.1 * big
	var g := Gradient.new()
	g.set_color(0, Color(tint, 0.85))
	g.set_color(1, Color(tint, 0.0))
	p.color_ramp = g
	p.position = pos
	p.z_index = z
	world.add_child(p)
	p.emitting = true
	if not loop:
		get_tree().create_timer(3.0).timeout.connect(p.queue_free)
	return p

## Stop every actor mid-pose (freeze-frame), with a white flash.
func freeze() -> void:
	for a in actors.values():
		(a as Node).process_mode = Node.PROCESS_MODE_DISABLED
	_shake = 0.0
	flash()

# ---------------------------------------------------------------- camera / timing

## Episode clock (game time) for syncing to music: reset_clock() at a downbeat, then
## `await until(t)` lands each beat at an absolute time, so waits never drift.
var clock: float = 0.0

func reset_clock() -> void:
	clock = 0.0

func until(t: float) -> void:
	while clock < t:
		await get_tree().process_frame

func wait(secs: float) -> void:
	await get_tree().create_timer(secs).timeout

## Move/zoom the camera (awaitable). dur 0 = hard cut.
## A new move cancels one still in flight (e.g. an un-awaited slow push-in).
func cam_to(pos: Vector2, zoom: float = 1.0, dur: float = 1.0, trans: Tween.TransitionType = Tween.TRANS_SINE) -> void:
	if _cam_tween and _cam_tween.is_valid():
		_cam_tween.kill()
	if dur <= 0.0:
		cam.position = pos
		cam.zoom = Vector2(zoom, zoom)
		return
	var tw := create_tween().set_parallel().set_trans(trans).set_ease(Tween.EASE_IN_OUT)
	_cam_tween = tw
	tw.tween_property(cam, "position", pos, dur)
	tw.tween_property(cam, "zoom", Vector2(zoom, zoom), dur)
	await wait(dur)   # not tw.finished: a killed tween never emits it

var _cam_tween: Tween

func shake(amount: float = 8.0) -> void:
	_shake = amount

# ---------------------------------------------------------------- overlays

## Full-screen slug card (black, centered text) — stands in for missing shots/music.
func card(text: String, secs: float = 2.0) -> void:
	_card_label.text = text
	var tw := create_tween()
	tw.tween_property(_card, "modulate:a", 1.0, 0.3)
	await tw.finished
	await wait(secs)
	tw = create_tween()
	tw.tween_property(_card, "modulate:a", 0.0, 0.3)
	await tw.finished

## Sound effect with no on-screen text (`<audio_dir>/sfx/<name>.mp3`).
## Returns the player (null if missing) so loops like footsteps can be stopped.
func play_sfx(name: String, volume_db: float = 0.0) -> AudioStreamPlayer:
	return _play("sfx/" + name, volume_db)

## Loop a background ambience (`<audio_dir>/amb/<name>.mp3`), crossfading from the
## current one; "" fades it out.
func ambience(name: String, volume_db: float = -10.0, fade: float = 1.0) -> void:
	if _amb:
		var old := _amb
		var tw := create_tween()
		tw.tween_property(old, "volume_db", -60.0, fade)
		tw.tween_callback(old.queue_free)
		_amb = null
	var path := "%s/amb/%s.mp3" % [audio_dir, name]
	if name == "" or not ResourceLoader.exists(path) or _skip_to:
		return
	var stream: AudioStreamMP3 = load(path)
	stream.loop = true
	_amb = AudioStreamPlayer.new()
	_amb.stream = stream
	_amb.volume_db = -60.0
	add_child(_amb)
	_amb.play()
	create_tween().tween_property(_amb, "volume_db", volume_db, fade)

## Episode audio folder: vo/, sfx/, amb/ (generated by tools/gen_audio.py).
var audio_dir: String = ""
var _amb: AudioStreamPlayer

## One-shot player for `<audio_dir>/<rel>.mp3`; null if missing (or fast-forwarding).
func _play(rel: String, volume_db: float = 0.0) -> AudioStreamPlayer:
	var path := "%s/%s.mp3" % [audio_dir, rel]
	if audio_dir == "" or _skip_to or not ResourceLoader.exists(path):
		return null
	var p := AudioStreamPlayer.new()
	p.stream = load(path)
	p.volume_db = volume_db
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)
	return p

## Must match tools/gen_audio.py slug().
func _slug(text: String) -> String:
	var re := RegEx.create_from_string("[^a-z0-9]+")
	return re.sub(text.to_lower(), "_", true).strip_edges().trim_prefix("_").trim_suffix("_").left(48)

## Dip to black and back: cut the camera/set between the two (awaitable).
func fade_out(secs: float = 0.4) -> void:
	_card_label.text = ""
	var tw := create_tween()
	tw.tween_property(_card, "modulate:a", 1.0, secs)
	await tw.finished

func fade_in(secs: float = 0.4) -> void:
	var tw := create_tween()
	tw.tween_property(_card, "modulate:a", 0.0, secs)
	await tw.finished

## Start a music track and return its player (await `.finished` to wait for the end).
## Audio runs in real time, unaffected by `speed`.
func play_music(path: String, volume_db: float = 0.0) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	if _skip_to:
		volume_db = -80.0                                # fast-forwarding: keep it quiet
	p.stream = load(path)
	p.volume_db = volume_db
	add_child(p)
	p.finished.connect(p.queue_free)
	# fast-forwarding: start at the very end so anything awaiting .finished moves on
	p.play(maxf(0.0, p.stream.get_length() - 0.05) if _skip_to else 0.0)
	return p

## Play a music track to the end (awaitable).
func music(path: String, volume_db: float = 0.0) -> void:
	await play_music(path, volume_db).finished

## Change pacing mid-episode (e.g. 1.0 while visuals sync to music).
func set_speed(s: float) -> void:
	speed = s
	if not _skip_to:
		Engine.time_scale = s

## Section marker. With `-- --from=<name>` everything before the matching mark plays
## at FAST_FORWARD (silent: music is skipped), so you can iterate on one section.
func mark(section: String) -> void:
	if _skip_to and section == _skip_to:
		_skip_to = ""
		Engine.time_scale = speed

const FAST_FORWARD := 30.0
var _skip_to: String = ""

## White flash (cuts, hits).
func flash(alpha: float = 0.9) -> void:
	_flash.color.a = alpha
	create_tween().tween_property(_flash, "color:a", 0.0, 0.35)

## Show a card and leave it up (end of a cold open).
func hold_card(text: String) -> void:
	_card_label.text = text
	_card.modulate.a = 1.0

func hide_card() -> void:
	_card.modulate.a = 0.0

## Stage-direction caption at the bottom ("" clears) — stands in for missing animation.
func caption(text: String) -> void:
	_caption.text = text
	_caption.visible = text != ""

## Floating sound-effect text in the world (drip, jangle...), fades upward.
func sfx(text: String, pos: Vector2, size: int = 22, color: Color = Color(0.9, 0.9, 0.8)) -> void:
	_play("sfx/" + _slug(text))                          # matching sound, if generated
	var l := Label.new()
	l.text = text
	var ls := LabelSettings.new()
	ls.font_size = size
	ls.font_color = color
	ls.outline_size = 5
	ls.outline_color = Color(0, 0, 0, 0.8)
	l.label_settings = ls
	l.position = pos
	l.z_index = 50
	world.add_child(l)
	var tw := create_tween().set_parallel()
	tw.tween_property(l, "position:y", pos.y - 30.0, 1.6)
	tw.tween_property(l, "modulate:a", 0.0, 1.6).set_delay(0.6)
	tw.chain().tween_callback(l.queue_free)

# ---------------------------------------------------------------- set dressing

func rect(r: Rect2, color: Color, z: int = -10, parent: Node = null) -> ColorRect:
	var c := ColorRect.new()
	c.position = r.position
	c.size = r.size
	c.color = color
	c.z_index = z
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(parent if parent else world).add_child(c)
	return c

func sprite(path: String, pos: Vector2, scl: float = 1.0, z: int = -10, centered: bool = false, parent: Node = null) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = load(path)
	s.position = pos
	s.scale = Vector2(scl, scl)
	s.centered = centered
	s.z_index = z
	(parent if parent else world).add_child(s)
	return s

func line(points: PackedVector2Array, color: Color, width: float = 3.0, z: int = -5, parent: Node = null) -> Line2D:
	var l := Line2D.new()
	l.points = points
	l.default_color = color
	l.width = width
	l.joint_mode = Line2D.LINE_JOINT_ROUND
	l.begin_cap_mode = Line2D.LINE_CAP_ROUND
	l.end_cap_mode = Line2D.LINE_CAP_ROUND
	l.z_index = z
	(parent if parent else world).add_child(l)
	return l

func text(t: String, pos: Vector2, size: int, color: Color, z: int = -5, parent: Node = null) -> Label:
	var l := Label.new()
	l.text = t
	var ls := LabelSettings.new()
	ls.font_size = size
	ls.font_color = color
	l.label_settings = ls
	l.position = pos
	l.z_index = z
	(parent if parent else world).add_child(l)
	return l

func dot(pos: Vector2, r: float, color: Color, z: int = -5, parent: Node = null) -> Polygon2D:
	var p := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 16:
		pts.append(Vector2.from_angle(TAU * i / 16.0) * r)
	p.polygon = pts
	p.color = color
	p.position = pos
	p.z_index = z
	(parent if parent else world).add_child(p)
	return p

## Soft additive light pool.
func glow(pos: Vector2, radius: float, color: Color, z: int = -8) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = _puff_tex()
	s.position = pos
	s.scale = Vector2.ONE * radius / 32.0
	s.modulate = color
	s.z_index = z
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	s.material = m
	world.add_child(s)
	return s

func group(pos: Vector2, scl: float = 1.0, rot: float = 0.0, z: int = -5) -> Node2D:
	var n := Node2D.new()
	n.position = pos
	n.scale = Vector2(scl, scl)
	n.rotation = rot
	n.z_index = z
	world.add_child(n)
	return n

# ---------------------------------------------------------------- internals

func _build_ui() -> void:
	_subs = Label.new()
	_subs.position = Vector2(60, 455)
	_subs.size = Vector2(840, 70)
	_subs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subs.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_subs.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var ss := LabelSettings.new()
	ss.font_size = 24
	ss.outline_size = 7
	ss.outline_color = Color(0, 0, 0, 0.95)
	_subs.label_settings = ss
	_subs.visible = false
	ui.add_child(_subs)
	_caption = Label.new()                # stage directions: top of frame
	_caption.position = Vector2(80, 14)
	_caption.size = Vector2(800, 0)
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var ls := LabelSettings.new()
	ls.font_size = 17
	ls.font_color = Color(1.0, 0.92, 0.6)
	ls.outline_size = 5
	ls.outline_color = Color(0, 0, 0, 0.9)
	_caption.label_settings = ls
	_caption.visible = false
	ui.add_child(_caption)

	_card = ColorRect.new()
	_card.size = SCREEN
	_card.color = Color.BLACK
	_card.modulate.a = 0.0
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(_card)
	_card_label = Label.new()
	_card_label.size = SCREEN
	_card_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_card_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var cs := LabelSettings.new()
	cs.font_size = 34
	cs.font_color = Color(0.95, 0.9, 0.8)
	_card_label.label_settings = cs
	_card.add_child(_card_label)

	_flash = ColorRect.new()
	_flash.size = SCREEN
	_flash.color = Color(1, 1, 1, 0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(_flash)

func _puff_tex() -> Texture2D:
	if _puff == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		t.width = 64
		t.height = 64
		_puff = t
	return _puff
