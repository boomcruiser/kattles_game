extends RefCounted
## EP1 "Community Service" — cold open, rough cut. Beat sheet: docs/ep1-script.md.
## World layout: Vapour's office x < 960, the cell painting x 960..1920 (jail_cell.png
## at 0.9375 scale), bars overlay drawn over the cell (z 5): Rusty stands behind it
## (z 0), visitors in front (z 10).

const CELL := Vector2(960, 0)       ## jail_cell.png top-left in world px
const K := 0.9375                   ## 1024 px painting -> 960 world px
const FLOOR := 1180.0               ## Rusty's floor line inside the cell
const FRONT := 1345.0               ## visitors' floor line, in front of the bars
const NIGHT := Color(0.8, 0.74, 0.64)
const SCRATCH := Color(0.78, 0.72, 0.6, 0.85)  ## tally marks scratched into stone
const TALLY3_TOP := Vector2(1448, 880)
const TALLY3_END := Vector2(1450, 924)
const RUSTY_BACK_X := 1560.0          ## back-view Rusty: raised hand just right of the marks
const WIDE := Vector2(1440, 1080)   ## cell wide shot (zoom 1)
const SCROLL_K := 90.0 / 480.0      ## decree_scroll.png -> 90 world px tall
const ThemeSong := preload("res://episodes/theme.gd")
const EXT := Vector2(-3000, 0)      ## jail_exterior.png top-left (1536 px -> 960 world px)

var _tally3: Line2D
var _rusty_back: Sprite2D
var _teabag: Node2D
var _spider: Node2D

func run(d: Director) -> void:
	d.audio_dir = "res://assets/audio/ep1"              # episodes/ep1_audio.json
	_build_set(d)
	var rusty := d.spawn("rusty", "res://Rusty.tscn", Vector2(1270, 1040), 230)
	rusty.modulate = NIGHT
	var vapour := d.spawn("vapour", "res://InspectorVapour.tscn", Vector2(-400, FRONT), 270, 10, 1.0)   # offstage until his entrance
	vapour.modulate = NIGHT

	# ---- 0:00 establishing ------------------------------------------------
	d.mark("exterior")
	# exterior: slow push-in on the glowing barred window
	d.ambience("night_exterior", -8.0, 0.5)
	d.cam_to(EXT + Vector2(480, 320), 1.0, 0.0)
	var spout := d.puff(EXT + Vector2(196, 152), 6, 0.35, Color(0.7, 0.72, 0.8), -9, true)
	d.cam_to(EXT + Vector2(330, 360), 1.7, 7.0)
	await d.wait(1.5)
	d.sfx("drip…", EXT + Vector2(225, 500), 18)
	await d.wait(2.5)
	d.sfx("drip…", EXT + Vector2(225, 500), 18)
	await d.wait(3.0)
	await d.fade_out(0.6)                                 # dip to black, cut inside
	spout.queue_free()
	d.cam_to(Vector2(330, 1110), 2.2, 0.0)
	d.ambience("cell", -10.0, 0.6)
	await d.wait(0.3)
	d.sfx("drip…", Vector2(250, 1010))
	await d.fade_in(0.6)
	await d.cam_to(Vector2(430, 1115), 2.2, 2.4)
	await d.cam_to(Vector2(585, 1105), 2.8, 1.8)
	await d.wait(3.0)                                   # hold on the headline
	d.sfx("drip…", Vector2(650, 1000))
	await d.cam_to(WIDE, 1.0, 3.5)
	d.caption("[Rusty on the bunk, staring at the ceiling]")
	await d.wait(1.0)
	d.steam("rusty", 5, 0.5)
	d.sfx("haaah…", Vector2(1200, 760), 18)
	await d.wait(1.2)
	d.caption("")
	for i in 3:                                          # let the drip get to him
		d.sfx("drip…", Vector2(1720, 1050))
		await d.wait(1.4)
	await d.say("rusty", "Is anyone going to fix that damn thing?!", {"hold": 0.6})
	await d.wait(0.4)

	# ---- 0:20 hating his life ---------------------------------------------
	d.mark("cell")
	var tw := rusty.create_tween()
	tw.tween_property(rusty, "position", Vector2(1340, FLOOR), 0.35)
	d.play_sfx("hop_down")
	await tw.finished
	await d.walk("rusty", RUSTY_BACK_X)
	rusty.visible = false                                # turns to the wall: back view
	_rusty_back.visible = true
	await d.cam_to(Vector2(1490, 930), 2.0, 0.8)          # two marks already
	await d.wait(0.6)
	d.sfx("SCREEEECH", Vector2(1420, 845), 16)
	var jig := _rusty_back.create_tween().set_loops(4)    # scratching jitter
	jig.tween_property(_rusty_back, "position:x", RUSTY_BACK_X - 6.0, 0.08)
	jig.tween_property(_rusty_back, "position:x", RUSTY_BACK_X, 0.08)
	_tally3.visible = true
	var tw3 := _tally3.create_tween()                    # third mark, scratched in
	tw3.tween_method(func(t: float): _tally3.points = PackedVector2Array([TALLY3_TOP, TALLY3_TOP.lerp(TALLY3_END, t)]), 0.0, 1.0, 0.7)
	await tw3.finished
	await d.wait(0.5)
	_rusty_back.visible = false                          # turns back around
	rusty.visible = true
	d.face("rusty", 1)
	await d.cam_to(Vector2(1500, 960), 1.4, 1.6)          # pull back
	await d.say("rusty", "Three days?", {"hold": 0.3})
	await d.say("rusty", "That's a lifetime in Kattle years.")

	d.sfx("thunk", Vector2(1690, 1240), 20)
	tw = _teabag.create_tween()
	tw.tween_property(_teabag, "position:y", 1200.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	d.caption("[breakfast through the slot: one cold teabag]")
	d.say("rusty", "Eh… what do we have for dinner?")
	await d.walk("rusty", 1625)
	d.face("rusty", 1)
	await d.cam_to(Vector2(1660, 1080), 1.6, 0.8)
	d.caption("")
	await d.wait(0.8)
	await d.cam_to(Vector2(1702, 1168), 4.0, 0.6)          # read the tag
	await d.wait(1.4)
	await d.cam_to(Vector2(1640, 1060), 1.8, 0.5)
	await d.say("rusty", "Decaf?!", {"hold": 0.3})
	await d.say("rusty", "…Yuck.", {"hold": 0.6})

	# brews it himself: teabag into the lid, strain, the rusty boiler gives out
	tw = _teabag.create_tween()
	tw.tween_property(_teabag, "position", rusty.head_pos() + Vector2(0, 10), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(_teabag.hide)
	await tw.finished
	d.sfx("plop", rusty.head_pos() + Vector2(-20, -30), 16)
	await d.wait(0.6)
	tw = rusty.create_tween()
	tw.tween_property(rusty, "squash", Vector2(1.08, 1.1), 0.9)
	d.sfx("glug… glug…", rusty.head_pos() + Vector2(40, 20), 18)
	await tw.finished
	d.sfx("CLANK", rusty.head_pos() + Vector2(-70, 40), 22)
	d.shake(4.0)
	await d.wait(0.5)
	d.sfx("wheeeeeeze…", rusty.head_pos() + Vector2(40, 50), 20)
	d.steam("rusty", 6, 0.5, Color(0.55, 0.35, 0.2))      # rust dust, not steam
	tw = rusty.create_tween()
	tw.tween_property(rusty, "squash", Vector2(1.0, 0.93), 1.4)
	await tw.finished
	await d.wait(0.4)
	rusty.squash = Vector2.ONE
	await d.say("rusty", "…That can't be good.", {"hold": 0.5})

	d.cam_to(Vector2(1712, 860), 3.0, 0.6)                # the spider
	await d.wait(0.3)
	_wiggle(_spider)
	d.play_sfx("skitter")
	await d.wait(0.8)
	await d.say("rusty", "What? Like you've never farted in public?", {"hold": 0.6})
	await d.cam_to(Vector2(1610, 1050), 1.8, 0.6)


	# ---- 0:50 scheming ----------------------------------------------------
	d.mark("scheme")
	var tension := d.play_music("res://assets/audio/ep1/music/scheme_tension.mp3", -9.0)
	await d.cam_to(WIDE, 1.0, 0.8)
	d.caption("[pacing, scheming]")
	await d.walk("rusty", 1330, 1.6)
	await d.walk("rusty", 1430, 1.6)
	d.caption("")
	d.face("rusty", 1)
	await d.cam_to(WIDE, 1.1, 0.8)
	await d.say("rusty", "Heh. They think bars can hold me?")
	await d.say("rusty", "Next Kattles Day… I'll—", {"hold": 0.6})
	d.cam_to(rusty.head_pos() + Vector2(0, 50), 2.2, 4.0)  # slow push-in on the laugh
	await d.say("rusty", "Heh…", {"hold": 0.4})
	await d.say("rusty", "heh heh…", {"hold": 0.3})
	d.shake(5.0)
	d.say("rusty", "HEH HEH HA—", {"shout": true, "keep": true})
	await d.wait(1.0)

	# ---- 1:20 the interruption --------------------------------------------
	d.mark("vapour")
	d.clear("rusty")
	if is_instance_valid(tension):
		tension.stop()
	d.sfx("*JANGLE JANGLE*", Vector2(1000, 1050), 30)
	d.pop("rusty", 0.5)
	await d.cam_to(Vector2(1160, 1090), 1.0, 0.25, Tween.TRANS_EXPO)
	vapour.position.x = 720
	var steps := d.play_sfx("vapour_steps", -4.0)        # clinky kettle footsteps
	d.walk("vapour", 1030, 1.8)
	await d.wait(1.3)
	await d.say("rusty", "What the heck?", {"hold": 0.5})
	await d.walk("vapour", 1030, 1.8)
	if is_instance_valid(steps):
		steps.stop()
	d.face("rusty", -1)
	await d.say("vapour", "Bonjour, Rusty! I bring news from ze Princess 'erself.")
	d.caption("[whistling innocently]")
	await d.say("rusty", "♪ fweet fwee-fweet ♪")
	d.caption("[unrolls a royal scroll]")
	d.play_sfx("scroll")
	var scroll := d.sprite("res://assets/props/decree_scroll.png", Vector2(1068, 1140), 0.0, 11)
	scroll.modulate = NIGHT
	scroll.scale = Vector2(SCROLL_K, 0.0)                 # unrolls downward from the top roller
	tw = scroll.create_tween()
	tw.tween_property(scroll, "scale:y", SCROLL_K, 0.5)
	await tw.finished
	d.caption("")
	await d.say("vapour", "By royal decree…", {"keep": true})
	await d.say("vapour", "…you are sentenced to…", {"keep": true, "hold": 0.3})
	d.caption("[dramatic pause]")
	await d.wait(1.8)
	d.caption("")
	await d.say("vapour", "…community service!", {"hold": 0.8})

	# ---- 1:45 shock + smash cut -------------------------------------------
	d.mark("shock")
	await d.cam_to(rusty.head_pos() + Vector2(0, 60), 2.6, 0.2, Tween.TRANS_EXPO)
	await d.wait(0.5)
	d.caption("[lid pops — steam burst]")
	d.play_sfx("lid_pop")
	d.steam("rusty", 34, 1.7)
	d.shake(14.0)
	d.pop("rusty", 1.4)
	await d.say("rusty", "COMMUNITY SERVICE?!", {"shout": true, "keep": true, "hold": 0.1})
	d.caption("")
	d.freeze()
	d.play_sfx("freeze_whoosh")
	d.ambience("", 0.0, 0.2)
	await d.wait(0.3)
	d.hold_card("")
	d.clear("rusty")
	await ThemeSong.new().run(d)

func _wiggle(n: Node2D) -> void:
	var tw := n.create_tween().set_loops(3)
	tw.tween_property(n, "rotation", 0.25, 0.12)
	tw.tween_property(n, "rotation", -0.25, 0.12)
	tw.chain().tween_property(n, "rotation", 0.0, 0.1)

func _build_set(d: Director) -> void:
	# exterior (its own patch of world, far left)
	d.sprite("res://assets/sets/jail_exterior.png", EXT, 0.625, -10)

	# Vapour's office (left of the cell)
	d.rect(Rect2(-600, 0, 1560, 1440), Color("1c211e"), -20)
	for y in range(840, 1250, 58):
		d.rect(Rect2(-600, y, 1560, 3), Color(0, 0, 0, 0.25), -19)
	d.rect(Rect2(-600, 1250, 1560, 190), Color("2a241c"), -19)
	d.glow(Vector2(500, 990), 300, Color(1.0, 0.72, 0.38, 0.35))
	d.rect(Rect2(250, 1168, 500, 16), Color("6b4a2b"), -12)        # desk top
	d.rect(Rect2(265, 1184, 470, 160), Color("4a321d"), -13)       # desk front
	# teacup + saucer
	d.rect(Rect2(305, 1165, 62, 5), Color("d9ccb0"), -11)
	d.rect(Rect2(315, 1135, 42, 31), Color("e8dcc0"), -11)
	d.line(PackedVector2Array([Vector2(356, 1141), Vector2(368, 1145), Vector2(366, 1157), Vector2(356, 1159)]), Color("e8dcc0"), 4, -11)
	# magnifying glass
	d.line(PackedVector2Array([Vector2(415, 1166), Vector2(447, 1139)]), Color("5a3a1e"), 6, -11)
	var ring := PackedVector2Array()
	for i in 21:
		ring.append(Vector2(462, 1124) + Vector2.from_angle(TAU * i / 20.0) * 17.0)
	d.dot(Vector2(462, 1124), 15, Color(0.7, 0.85, 0.9, 0.25), -11)
	d.line(ring, Color("b08d57"), 4, -11)
	_build_paper(d)

	# the cell painting + bars overlay; a pillar hides the office/painting seam
	d.sprite("res://assets/sets/jail_cell.png", CELL, K, -10)
	d.rect(Rect2(925, 0, 70, 1440), Color("141817"), -9)
	d.sprite("res://assets/sets/jail_bars.png", CELL, K, 5)
	d.rect(Rect2(1920, 0, 600, 1440), Color("141817"), 6)          # beyond the painting

	# tally marks (third appears on cue)
	for x in [1424.0, 1436.0]:
		d.line(PackedVector2Array([Vector2(x, 880), Vector2(x + 2, 924)]), SCRATCH, 3)
	# Rusty from behind (assets/props/rusty_back.png), swapped in while he scratches
	_rusty_back = d.sprite("res://assets/props/rusty_back.png", Vector2(RUSTY_BACK_X, FLOOR - 135.0), 230.0 / 920.0, 0, true)   # on tiptoe
	_rusty_back.modulate = NIGHT
	_rusty_back.visible = false
	_tally3 = d.line(PackedVector2Array([TALLY3_TOP, TALLY3_TOP]), SCRATCH, 3)
	_tally3.visible = false

	# teabag, waiting below the slot
	_teabag = d.group(Vector2(1705, 1440), 1.0, 0.0, 6)
	d.sprite("res://assets/props/teabag_decaf.png", Vector2(-24, -60), 60.0 / 360.0, 0, false, _teabag)

	# spider + web in the top-right corner
	for a in [0.55, 1.0, 1.45, 1.9]:
		d.line(PackedVector2Array([Vector2(1760, 812), Vector2(1760, 812) + Vector2.from_angle(PI - a) * 70.0]), Color(0.8, 0.8, 0.75, 0.25), 1.0, -8)
	_spider = d.group(Vector2(1712, 848), 1.0, 0.0, -7)
	for i in 4:
		for side in [-1.0, 1.0]:
			var y := -4.0 + i * 3.0
			d.line(PackedVector2Array([Vector2(0, y), Vector2(side * 7, y - 4), Vector2(side * 11, y + 4)]), Color.BLACK, 1.2, 0, _spider)
	d.dot(Vector2.ZERO, 5, Color("111"), 1, _spider)
	d.dot(Vector2(-1.8, -2), 1.1, Color.WHITE, 2, _spider)
	d.dot(Vector2(1.8, -2), 1.1, Color.WHITE, 2, _spider)
	d.line(PackedVector2Array([Vector2(0, -5), Vector2(0, -36)]), Color(0.8, 0.8, 0.75, 0.4), 0.8, 0, _spider)

## Newspaper propped behind the desk. Built at 3x and scaled down so the text stays
## crisp in the close-up.
func _build_paper(d: Director) -> void:
	var p := d.group(Vector2(480, 1050), 1.0 / 3.0, -0.04, -11)
	var ink := Color("2a2622")
	d.rect(Rect2(0, 0, 630, 354), Color("ece4cf"), 0, p)
	d.text("THE KATTLES TIMES", Vector2(20, 6), 30, ink, 1, p)
	d.rect(Rect2(20, 48, 590, 3), ink, 1, p)
	d.text("KATTLES DAY SAVED!", Vector2(18, 54), 60, ink, 1, p)
	d.text("RUSTY CAUGHT BY ROYAL HOUND", Vector2(20, 130), 28, ink, 1, p)
	var photo := d.rect(Rect2(20, 174, 280, 164), Color("8f897d"), 1, p)
	photo.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	# Rusty knocked flat on his side, feet sticking out, Dukie standing on him
	var fallen := Node2D.new()
	fallen.position = Vector2(150, 96)
	fallen.rotation = -1.62
	fallen.scale = Vector2(0.25, 0.25)
	fallen.modulate = Color(0.75, 0.72, 0.68)
	photo.add_child(fallen)
	for part in ["foot_l", "foot_r", "body"]:
		d.sprite("res://assets/rusty/%s.png" % part, Vector2.ZERO, 1.0, 0, true, fallen)
	d.sprite("res://assets/props/dukie.png", Vector2(150, 46), 0.19, 1, true, photo).modulate = Color(0.85, 0.82, 0.78)
	for i in 9:
		d.rect(Rect2(320, 180 + i * 17, 290 if i < 8 else 170, 6), Color("8a8478"), 1, p)
