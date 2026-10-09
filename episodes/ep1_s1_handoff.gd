extends RefCounted
## EP1 scene 1 — "The Handoff". Morning outside Kattles Jail: Vapour lets Rusty out,
## introduces his supervisor (Dukie), clips on a leash and shows the chore map.
## Beat sheet: docs/ep1-script.md. World: exterior at H, map insert at M.

const H := Vector2(8000, 0)          ## jail_exterior_day.png top-left (1536 px -> 1920 world px)
const HK := 1.25
const FLOOR := 1190.0                ## the dirt path in front of the door
const DOOR := Rect2(1069, 681, 175, 381)   ## doorway opening (world px, relative to H)
const HAY_TOP := 985.0               ## standing height on the hay bales
const M := Vector2(16000, 0)         ## chore_map.png top-left (1536 px -> 960 world px)
const MK := 0.625
## Map stops (world px, relative to M)
const TOWN := Vector2(215, 181)
const VALLEY := Vector2(478, 413)
const HOLLOW := Vector2(728, 175)
const JAIL := Vector2(184, 500)
const INK := Color("5a3420")

const RUSTY_H := 175.0
const VAPOUR_H := 205.0
const DUKIE_H := 135.0

var _doorway: ColorRect
var _circles: Array = []

func run(d: Director) -> void:
	d.mark("handoff")
	d.set_speed(1.25)
	await d.fade_out(0.5)
	d.sub("")
	d.reset_actors()
	d.vo_hold = 0.15                                       # snappier back-and-forth than the cold open
	d.vo_hold_per_char = 0.004
	_build_set(d)
	var vapour := d.spawn("vapour", "res://InspectorVapour.tscn", H + Vector2(DOOR.get_center().x, DOOR.end.y), VAPOUR_H, 1)
	var rusty := d.spawn("rusty", "res://Rusty.tscn", H + Vector2(DOOR.get_center().x, DOOR.end.y), RUSTY_H, 1)
	var dukie := d.spawn("dukie", "res://Dukie.tscn", H + Vector2(1500, HAY_TOP), DUKIE_H, 2, -1.0)
	vapour.visible = false
	rusty.visible = false
	dukie.visible = false                                 # "was there all along" — shown on the reveal

	# ---- morning, the door opens ------------------------------------------
	d.cam_to(H + Vector2(960, 640), 0.55, 0.0)
	d.ambience("morning_exterior", -10.0, 0.8)
	await d.fade_in(0.8)
	d.caption("[morning]")
	d.cam_to(H + Vector2(1156, 960), 1.25, 4.0)
	await d.wait(1.6)
	d.sfx("Moo-a-doodle-doo!", H + Vector2(1500, 760), 22)   # a Cattle doing the rooster's job
	await d.wait(2.4)
	d.caption("")
	d.sfx("*creak*", H + Vector2(1100, 860), 18)
	_doorway.visible = true
	await d.wait(0.3)
	vapour.visible = true
	var steps := d.play_sfx("vapour_steps", -6.0)
	await _step_out(vapour, H + Vector2(960, FLOOR))
	if is_instance_valid(steps):
		steps.stop()
	d.face("vapour", 1)
	await d.say("vapour", "Allez, allez! Ze sun is up, and so are you!")
	rusty.visible = true
	rusty.modulate = Color(0.6, 0.6, 0.6)
	var tw := rusty.create_tween()
	tw.tween_property(rusty, "modulate", Color.WHITE, 0.8)
	await _step_out(rusty, H + Vector2(1190, FLOOR), 0.8)
	_doorway.visible = false
	d.face("rusty", -1)
	d.cam_to(H + Vector2(1080, 1010), 1.25, 1.0)
	tw = rusty.create_tween()                             # squints at the daylight
	tw.tween_property(rusty, "squash", Vector2(1.04, 0.94), 0.3)
	await d.say("rusty", "Ugh. Is that… the sun?", {"hold": 0.3})
	await d.say("rusty", "Great. Now I'm gonna get a tan.")
	rusty.squash = Vector2.ONE
	await d.say("vapour", "Monsieur… zat is not a tan. Zat is rust.", {"hold": 0.3})
	d.pop("rusty", 0.2)
	await d.say("rusty", "It's a VINTAGE FINISH.", {"hold": 0.2})
	await d.say("rusty", "Do you know what UV does to a vintage finish?", {"hold": 0.4})

	# ---- the supervisor ---------------------------------------------------
	d.mark("supervisor")
	await d.say("vapour", "Of course, you will not be working alone.")
	await d.say("vapour", "Ze Princess 'as assigned you… a supervisor.", {"hold": 0.4})
	await d.say("rusty", "A supervisor? Let me guess — Boilbert? Lieutenant Leather?")
	dukie.visible = true
	d.say("vapour", "Non.", {"hold": 0.0})
	await d.wait(0.6)
	d.caption("[points at the hay bales]")
	await d.cam_to(H + Vector2(1500, 900), 1.7, 0.7)
	d.caption("")
	d.sfx("*squeak squeak*", H + Vector2(1530, 840), 18)      # chewing the bunny
	d.pop("dukie", 0.3)
	await d.wait(0.4)
	await d.say("dukie", "Woof!", {"hold": 0.1})
	await d.cam_to(rusty.head_pos() + Vector2(0, 90), 2.2, 0.2, Tween.TRANS_EXPO)
	d.pop("rusty", 0.9)
	d.steam("rusty", 14, 0.8)
	d.shake(6.0)
	await d.say("rusty", "The PUPPY?!", {"shout": true, "hold": 0.4})

	# Dukie hops down, trots over, sniffs
	d.cam_to(H + Vector2(1200, 1010), 1.25, 0.8)
	tw = dukie.create_tween()
	tw.tween_property(dukie, "position", H + Vector2(1430, FLOOR), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished
	d.play_sfx("dog_land")
	await d.walk("dukie", H.x + 1370)
	d.caption("[sniff sniff]")
	d.play_sfx("sniff")
	for i in 2:
		d.pop("dukie", 0.12)
		await d.wait(0.3)
	d.caption("")
	await d.say("dukie", "Woof! Bad kettle. Dukie watch.")
	d.face("rusty", -1)
	await d.say("rusty", "That mutt is the reason I'm in here!")
	await d.say("vapour", "Exactement. 'E caught you once…", {"hold": 0.3})
	await d.say("vapour", "…'e can catch you again.")

	# the leash: Vapour clips it to Rusty's handle, Dukie takes the end
	d.caption("[clips a leash onto Rusty's handle]")
	d.sfx("*click*", rusty.head_pos() + Vector2(10, -20), 16)
	d.tether(func(): return _mouth(dukie), func(): return rusty.to_global(Vector2(0, -0.95 * RUSTY_H)), Color("b8322a"), 3.5)
	await d.wait(0.5)
	d.caption("")
	tw = rusty.create_tween()
	tw.tween_property(rusty, "squash", Vector2(1.0, 0.92), 0.4)
	await d.say("rusty", "Oh, come ON.", {"hold": 0.4})
	rusty.squash = Vector2.ONE

	# ---- the chore map ----------------------------------------------------
	d.mark("map")
	await d.say("vapour", "Now. Your tasks.", {"hold": 0.2})
	d.caption("[unrolls a map]")
	d.play_sfx("scroll")
	await d.wait(0.5)
	d.caption("")
	d.cam_to(M + Vector2(480, 320), 1.0, 0.0)
	await d.wait(0.6)
	_circle(d, TOWN, 95.0)                                # each stop inked while it's read out
	await d.say("vapour", "One: scrub ze soot in Steamtown.", {"keep": true, "hold": 0.2})
	_circle(d, VALLEY, 110.0)
	await d.say("vapour", "Two: fix ze fence in ze Cattle Valley.", {"keep": true, "hold": 0.2})
	_circle(d, HOLLOW, 100.0)
	await d.say("vapour", "Three: light ze lanterns in ze Hybrid 'Ollow.", {"keep": true, "hold": 0.3})
	await d.say("rusty", "…The Hybrids?", {"hold": 0.4})
	await d.say("vapour", "All before sundown.", {"hold": 0.4})

	# ---- the threat, the bolt ---------------------------------------------
	d.mark("bolt")
	for c in _circles:
		c.queue_free()
	_circles.clear()
	d.cam_to(H + Vector2(1180, 1010), 1.25, 0.0)
	await d.wait(0.3)
	await d.say("rusty", "And if I don't?")
	var cup := _teacup(d, vapour.position + Vector2(34, -90))
	d.caption("[sips tea]")
	d.play_sfx("sip")
	await d.wait(0.7)
	d.caption("")
	await d.say("vapour", "Zen… more decaf.", {"hold": 0.5})
	var shiver := rusty.create_tween().set_loops(5)       # shudders
	shiver.tween_property(rusty, "position:x", rusty.position.x - 4.0, 0.04)
	shiver.tween_property(rusty, "position:x", rusty.position.x, 0.04)
	await shiver.finished
	await d.say("rusty", "…Fine.", {"hold": 0.5})

	# a butterfly drifts past; Dukie's eyes follow it
	var fly := _butterfly(d, H + Vector2(820, 900))
	tw = fly.create_tween()
	tw.tween_method(func(t: float):
		fly.position = H + Vector2(820, 900).lerp(Vector2(1700, 980), t) + Vector2(0, sin(t * 18.0) * 25.0), 0.0, 1.0, 3.2)
	await d.wait(0.9)
	d.face("dukie", 1)
	d.pop("dukie", 0.2)
	await d.wait(0.4)
	await d.say("rusty", "No…", {"hold": 0.5})
	d.pop("dukie", 0.1)                                   # crouches, wiggling
	await d.say("rusty", "Don't you dare…", {"hold": 0.7})
	d.say("dukie", "WOOF! WOOF!", {"shout": true})
	await _drag_off(d, dukie, rusty)
	d.cam_to(H + Vector2(1000, 1010), 1.4, 0.6)
	await d.wait(0.2)
	d.face("vapour", 1)
	await d.say("vapour", "Bon courage, mon ami.", {"hold": 0.6})
	cup.queue_free()

	# ---- to Steamtown -----------------------------------------------------
	d.cam_to(M + Vector2(480, 320), 1.0, 0.0)
	await _route(d, JAIL, TOWN)
	await d.wait(0.8)
	d.ambience("", 0.0, 0.6)
	await d.fade_out(0.6)

# ------------------------------------------------------------------ beats

## Walk out of the doorway towards the camera (down + sideways) to `to`.
func _step_out(a: Actor, to: Vector2, secs: float = 1.0) -> void:
	a.facing = signf(to.x - a.position.x)
	a._set_walking(true)
	var tw := a.create_tween()
	tw.tween_property(a, "position", to, secs)
	await tw.finished
	a._set_walking(false)

## Dukie bolts after the butterfly; the leash yanks Rusty flat and drags him off.
func _drag_off(d: Director, dukie: Actor, rusty: Actor) -> void:
	dukie.walk_to(H.x + 2300, 9.0)
	d.play_sfx("dukie_bolt")
	await d.wait(0.35)
	d.sfx("YANK", rusty.head_pos() + Vector2(30, -10), 22)
	var tw := rusty.create_tween()
	tw.tween_property(rusty, "rotation", PI / 2, 0.15)    # knocked flat (like the newspaper)
	await tw.finished
	d.say("rusty", "OWWWW—!", {"shout": true})
	d.play_sfx("drag_scrape")
	var dust := d.puff(rusty.position, 10, 0.5, Color(0.8, 0.7, 0.5), 2, true)
	tw = rusty.create_tween()
	tw.tween_method(func(x: float):
		rusty.position.x = x
		dust.position = rusty.position, rusty.position.x, H.x + 2200, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished
	dust.emitting = false

## Hand-inked circle drawn around a map stop.
func _circle(d: Director, at: Vector2, r: float) -> void:
	var l := d.line(PackedVector2Array(), Color("a8321e"), 4.0, 2)
	_circles.append(l)
	d.play_sfx("ink_circle", -4.0)
	var pts := PackedVector2Array()
	for i in 41:                                          # a little over one loop, wobbly
		var a := -PI / 2 + TAU * 1.08 * i / 40.0
		pts.append(M + at + Vector2(cos(a) * r, sin(a) * r * 0.72) * (1.0 + 0.04 * sin(i * 1.7)))
	var tw := l.create_tween()
	tw.tween_method(func(t: float): l.points = pts.slice(0, maxi(2, int(t * pts.size()))), 0.0, 1.0, 0.6)
	await tw.finished

## Dotted trail inked from one stop to the next.
func _route(d: Director, from: Vector2, to: Vector2) -> void:
	var ctrl := (from + to) * 0.5 + Vector2(-90, 0)
	d.play_sfx("ink_circle", -6.0)
	for i in range(1, 15):
		var t := i / 15.0
		d.dot(M + from.lerp(ctrl, t).lerp(ctrl.lerp(to, t), t), 4.0, Color("a8321e"), 2)
		await d.wait(0.08)

## Dukie's mouth in world px (end of the leash), from the sprite: mouth at (440, 165)
## of 600x600 art whose opaque rect bottom is y 592.
func _mouth(dukie: Actor) -> Vector2:
	var k := DUKIE_H / 590.0
	return dukie.to_global(Vector2((440 - 300) * k, -(592 - 165) * k + dukie.puppet.get_node("Body").position.y * dukie.puppet.scale.y))

func _teacup(d: Director, at: Vector2) -> Node2D:
	var g := d.group(at, 1.0, 0.0, 3)
	d.rect(Rect2(-14, 10, 28, 3), Color("d9ccb0"), 0, g)
	d.rect(Rect2(-9, -6, 18, 16), Color("f0e6cc"), 0, g)
	d.line(PackedVector2Array([Vector2(9, -3), Vector2(14, 0), Vector2(9, 6)]), Color("f0e6cc"), 2.5, 0, g)
	return g

func _butterfly(d: Director, at: Vector2) -> Node2D:
	var g := d.group(at, 1.0, 0.0, 4)
	for side in [-1.0, 1.0]:
		var w := d.dot(Vector2(side * 6, -2), 6.0, Color("f2b640"), 0, g)
		w.scale = Vector2(1.0, 1.3)
		var flap := w.create_tween().set_loops()
		flap.tween_property(w, "scale:x", 0.25, 0.1)
		flap.tween_property(w, "scale:x", 1.0, 0.1)
	d.rect(Rect2(-1, -6, 2, 10), Color("3a2a1a"), 1, g)
	return g

# ------------------------------------------------------------------ set

func _build_set(d: Director) -> void:
	d.sprite("res://assets/sets/jail_exterior_day.png", H, HK, -10)
	_doorway = d.rect(Rect2(H + DOOR.position, DOOR.size), Color("16110c"), -9)
	_doorway.visible = false

	d.sprite("res://assets/props/chore_map.png", M, MK, -10)
	d.rect(Rect2(M + Vector2(-400, -200), Vector2(1760, 1040)), Color("2a1d12"), -11)
	for l in [["STEAMTOWN", Vector2(140, 262)], ["CATTLE VALLEY", Vector2(392, 488)],
			["HYBRID HOLLOW", Vector2(632, 284)], ["JAIL", Vector2(160, 548)]]:
		var t := d.text(l[0], M + l[1], 24, INK, 1)
		t.label_settings.outline_size = 6
		t.label_settings.outline_color = Color("efe0b8")
