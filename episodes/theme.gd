extends RefCounted
## "The Kattles Show" theme — reusable by every episode: `await preload("res://episodes/theme.gd").new().run(d)`.
## 1) a cappella "Moo moo! Hiss hiss!" sting as silhouette hits, 2) a short silent hold,
## 3) the band over a lyric-matched montage (docs/theme-montage.md). Times come from the
## track (whisper word timestamps); the montage is driven by d.until() on a clock reset
## when the band comes in. Each shot lives in its own patch of world far to the left.

const SONG := "res://assets/audio/theme/hardrock1.mp3"   ## see docs/theme-song.md
const STAGE := Vector2(-6000, 300)                       ## silhouette stage (black void)
const BG := 0.9375                                       ## 1024 px painting -> 960 world px
const NIGHT := Color(0.8, 0.74, 0.64)
const GOLD := Color(1.0, 0.85, 0.55)

## Lyric subtitles, phrase by phrase, at the time each phrase is sung (seconds after the
## band comes in; whisper word timestamps on hardrock1). "" clears.
const LYRICS := [
	[0.0, "They're stompin' in the valley,"],
	[2.0, "they're boilin' in the town,"],
	[3.7, "There's a princess on the throne"],
	[5.35, "tryin' to calm 'em all down —"],
	[7.65, "There's Hybrids in the hollow —"],
	[8.95, "half kettle, half cow!"],
	[10.05, "And Kattlefish splashin' in the lagoon —"],
	[11.75, "Arr, take a bow!"],
	[13.0, "There's a villain in the slammer"],
	[13.85, "and a puppy on the go…"],
	[15.75, "It's the Kattles Show!"],
	[18.6, ""],
]

func region(i: int) -> Vector2:
	return Vector2(-40000 + i * 3000, 0)

func run(d: Director) -> void:
	d.mark("theme")
	d.set_speed(1.0)                                     # visuals sync to real-time audio
	var shots := _build_montage(d)
	var song := await _sting(d)
	d.reset_clock()
	_lyrics(d)                                           # runs alongside the montage
	await _montage(d, shots)
	await song.finished

# ------------------------------------------------------------------ sting

func _sting(d: Director) -> AudioStreamPlayer:
	var o := STAGE
	d.rect(Rect2(o + Vector2(-700, -500), Vector2(1400, 1000)), Color.BLACK, -20)
	d.cam_to(o, 1.0, 0.0)
	var cows := [
		_silhouette(d, "s_cow1", "res://Spotilda.tscn", o + Vector2(-290, 200), 300, 1.0, GOLD),
		_silhouette(d, "s_cow2", "res://Buttercup.tscn", o + Vector2(290, 200), 300, -1.0, GOLD),
	]
	var kettles := [
		_silhouette(d, "s_kettle1", "res://Rusty.tscn", o + Vector2(-85, 300), 230, 1.0, Color(0.45, 0.65, 1.0)),
		_silhouette(d, "s_kettle2", "res://Steamy.tscn", o + Vector2(95, 300), 230, -1.0, Color(0.45, 0.65, 1.0)),
	]
	d.hide_card()
	var song := d.play_music(SONG)
	# Moo (0.00) / moo (0.78): spotlights slam on, cattle pop up
	for i in 2:
		d.sub(["Moo!", "Moo moo!"][i])
		_reveal(d, cows[i], false)
		await d.wait(0.78 if i == 0 else 0.62)
	# Hiss (1.40) / hiss (2.05): lights dim, kettles rise from below trailing steam
	for c in cows:
		c.glow.create_tween().tween_property(c.glow, "modulate:a", 0.25, 0.3)
	for i in 2:
		d.sub(["Hiss…", "Hiss hiss…"][i], Color(0.75, 0.85, 1.0))
		_reveal(d, kettles[i], true)
		await d.wait(0.65 if i == 0 else 0.77)
	# stop just before the band (2.82), hold the tableau in silence, band on the cut
	var band := song.get_playback_position()
	song.stop()
	await d.wait(0.7)
	d.sub("")
	song.play(band)
	d.flash(1.0)
	return song

## A black puppet with a coloured light pool behind it, hidden until revealed.
func _silhouette(d: Director, id: String, path: String, pos: Vector2, h: float, facing: float, light: Color) -> Dictionary:
	var a := d.spawn(id, path, pos, h, 5, facing)
	a.modulate = Color(0, 0, 0, 0)
	var g := d.glow(pos + Vector2(0, -h * 0.5), h * 1.1, Color(light, 0.0), 4)
	return {"actor": a, "glow": g, "light": light}

func _reveal(d: Director, s: Dictionary, rise: bool) -> void:
	var a: Actor = s.actor
	a.modulate = Color(0, 0, 0, 1)
	s.glow.modulate = Color(s.light, 0.9)
	if rise:                                             # up from below the frame
		var y: float = a.position.y
		var top := a.head_pos()                          # where the lid ends up
		a.position.y += 260.0
		var tw := a.create_tween()
		tw.tween_property(a, "position:y", y, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_callback(func(): d.puff(top + Vector2(0, 10), 10, 0.8, Color(0.85, 0.9, 1.0), 6))
	else:
		d.pop(a.name, 0.6)

# ------------------------------------------------------------------ montage

## Build every shot's set and cast up front (hidden in their own regions).
func _build_montage(d: Director) -> Dictionary:
	var s := {}
	# valley — garden party hills
	var o := region(0)
	d.sprite("res://assets/sets/theme/garden_party.png", o, BG, -10)
	s.valley = o
	d.spawn("t_spotilda", "res://Spotilda.tscn", o + Vector2(300, 725), 170, 0, 1.0)
	d.spawn("t_wanderella", "res://Wanderella.tscn", o + Vector2(520, 735), 175, 1, -1.0)
	d.spawn("t_buttercup", "res://Buttercup.tscn", o + Vector2(760, 730), 175, 0, -1.0)
	# Brewster vibing with his boombox while Rusty + Grimey sneak behind him
	o = region(9)
	d.sprite("res://assets/sets/theme/steamtown_night.png", o, BG, -10)
	s.groove = o
	for a in [d.spawn("t_brewster", "res://Brewster.tscn", o + Vector2(560, 1340), 250, 2, -1.0),
			d.spawn("t_srusty", "res://Rusty.tscn", o + Vector2(190, 1290), 190, 0, 1.0),
			d.spawn("t_sgrimey", "res://Grimey.tscn", o + Vector2(70, 1290), 200, 0, 1.0)]:
		a.modulate = NIGHT
	d.sprite("res://assets/props/theme/boombox.png", o + Vector2(700, 1290), 0.22, 3, true).modulate = NIGHT
	o = region(0)
	# town — Steamtown at night
	o = region(1)
	d.sprite("res://assets/sets/theme/steamtown_night.png", o, BG, -10)
	s.town = o
	for a in [d.spawn("t_rusty", "res://Rusty.tscn", o + Vector2(220, 1330), 200, 1, 1.0),
			d.spawn("t_grimey", "res://Grimey.tscn", o + Vector2(90, 1330), 210, 1, 1.0),
			d.spawn("t_boilbert", "res://Boilbert.tscn", o + Vector2(700, 1330), 260, 0, -1.0)]:
		a.modulate = NIGHT
	# leather vs vapour — garden lawn
	o = region(2)
	d.sprite("res://assets/sets/theme/garden_party.png", o, BG, -10)
	s.lawn = o
	d.spawn("t_leather", "res://LieutenantLeather.tscn", o + Vector2(300, 1010), 270, 0, 1.0)
	d.spawn("t_vapour", "res://InspectorVapour.tscn", o + Vector2(660, 1010), 260, 0, -1.0)
	# palace — royal K crest
	o = region(3)
	d.sprite("res://assets/sets/theme/royal_palace.png", o, 960.0 / 1072.0, -10)
	s.palace = o
	s.crest = d.glow(o + Vector2(493, 616), 70, Color(1.0, 0.9, 0.5, 0.0), -5)
	# hollow — Hybrids light up
	o = region(4)
	d.sprite("res://assets/sets/theme/hybrid_hollow.png", o, BG, -10)
	s.hollow = o
	s.hybrids = []
	var xs := [130, 360, 600, 830]
	var names := ["Whispy", "Bubblehorn", "Snortle", "Moosteam"]
	for i in 4:
		var a := d.spawn("t_h%d" % i, "res://%s.tscn" % names[i], o + Vector2(xs[i], 1330), 165, 0, 1.0 if i < 2 else -1.0)
		a.modulate = Color(0.22, 0.22, 0.27)
		s.hybrids.append(a)
	for id in ["t_puffalo", "t_clatterhoof"]:
		var a := d.spawn(id, "res://%s.tscn" % ("Puffalo" if id == "t_puffalo" else "Clatterhoof"), o + Vector2(480, 1420), 250, 5, 1.0)
		a.modulate.a = 0.0
	# river — Kattlefish leaping
	o = region(5)
	d.sprite("res://assets/sets/theme/kattles_river.png", o, BG, -10)
	s.river = o
	# dock — Captain Gill
	o = region(6)
	d.sprite("res://assets/sets/theme/garden_party.png", o, BG, -10)
	s.dock = o
	s.gill = d.sprite("res://assets/props/theme/captain_gill.png", o + Vector2(330, 1420), 210.0 / 938.0, 3, true)
	d.rect(Rect2(o + Vector2(0, 1290), Vector2(960, 160)), Color(0.18, 0.4, 0.55, 0.0), 4)   # (spare water plane)
	# jail — Rusty rattles the bars, Dukie zooms past
	o = region(7)
	d.sprite("res://assets/sets/jail_cell.png", o, BG, -10)
	d.sprite("res://assets/sets/jail_bars.png", o, BG, 5)
	s.jail = o
	d.spawn("t_jrusty", "res://Rusty.tscn", o + Vector2(545, 1180), 230, 0, -1.0).modulate = NIGHT
	d.spawn("t_jgrimey", "res://Grimey.tscn", o + Vector2(250, 1345), 260, 10, 1.0).modulate = NIGHT
	s.dukie = d.sprite("res://assets/props/dukie.png", o + Vector2(-200, 1290), 0.3, 12, true)
	# finale — everyone in front of the party stage
	o = region(8)
	d.sprite("res://assets/sets/theme/garden_party.png", o, BG, -10)
	s.finale = o
	var cast := [["Spotilda", 150, 1.0], ["LieutenantLeather", 200, 1.0], ["InspectorVapour", 190, 1.0],
		["Rusty", 165, 1.0], ["Whispy", 150, -1.0], ["Grimey", 175, -1.0], ["Puffalo", 160, -1.0]]
	for i in cast.size():
		d.spawn("t_f%d" % i, "res://%s.tscn" % cast[i][0], o + Vector2(90 + i * 130, 880), cast[i][1], 0, cast[i][2])
	d.sprite("res://assets/props/dukie.png", o + Vector2(480, 860), 0.2, 2, true)
	s.logo = d.text("THE KATTLES SHOW", o + Vector2(140, 380), 74, Color(1.0, 0.85, 0.35), 20)
	s.logo.label_settings.outline_size = 14
	s.logo.label_settings.outline_color = Color(0.25, 0.12, 0.05)
	s.logo.pivot_offset = Vector2(340, 50)
	s.logo.scale = Vector2.ZERO
	return s

func _montage(d: Director, s: Dictionary) -> void:
	# 0.0 "stompin' in the valley" — Spotilda flips for joy, Wanderella hops along
	d.cam_to(s.valley + Vector2(420, 640), 1.6, 0.0)
	d.pop("t_wanderella", 0.5)
	await d.wait(0.15)
	d.spin("t_spotilda", 1.0, 0.7, 80.0)
	await d.wait(0.45)
	d.pop("t_wanderella", 0.5)
	await d.until(1.25)
	# Buttercup cracks up — her infectious laugh bounces her off the ground
	d.cam_to(s.valley + Vector2(740, 650), 2.3, 0.0)
	for i in 3:
		d.pop("t_buttercup", 0.35)
		d.sfx("hee!", d.actors.t_buttercup.head_pos() + Vector2(10 + 25 * i, -20), 16)
		await d.wait(0.24)
	await d.until(2.0)

	# 2.0 "boilin' in the town" — Brewster grooves to his boombox, Rusty + Grimey sneak past
	d.cam_to(s.groove + Vector2(470, 1170), 1.3, 0.0)
	d.groove("t_brewster", 0.46, 4)
	d.walk("t_srusty", s.groove.x + 400, 1.8)
	d.walk("t_sgrimey", s.groove.x + 280, 1.8)
	d.sfx("♪", s.groove + Vector2(720, 1180), 26)
	await d.until(2.9)
	# Grimey bonks into Boilbert
	d.cam_to(s.town + Vector2(560, 1180), 1.45, 0.0)
	d.actors.t_grimey.position.x = s.town.x + 470
	await d.walk("t_grimey", s.town.x + 600, 2.5)
	d.sfx("BONK", s.town + Vector2(600, 1060), 26)
	d.shake(6.0)
	d.pop("t_boilbert", 0.25)
	var g: Actor = d.actors.t_grimey
	g.create_tween().tween_property(g, "position:x", g.position.x - 70.0, 0.2)
	await d.until(3.7)

	# 3.7 "princess on the throne…" — Leather and Vapour charge in and go at it
	d.cam_to(s.lawn + Vector2(480, 900), 1.3, 0.0)
	var le: Actor = d.actors.t_leather
	var va: Actor = d.actors.t_vapour
	le.create_tween().tween_property(le, "position:x", s.lawn.x + 410, 0.25).set_trans(Tween.TRANS_BACK)
	va.create_tween().tween_property(va, "position:x", s.lawn.x + 550, 0.25).set_trans(Tween.TRANS_BACK)
	await d.until(4.15)
	for beat in 3:                                       # stomp / lid-pop, trading blows
		if beat % 2 == 0:
			d.pop("t_vapour", 0.6)
			d.steam("t_vapour", 16, 1.0)
			d.sfx("PSSHH!", va.head_pos() + Vector2(10, -10), 20)
		else:
			d.pop("t_leather", 0.6)
			d.shake(6.0)
			d.puff(le.position, 6, 0.4, Color(0.8, 0.7, 0.5), 2)
			d.sfx("HMPH!", le.head_pos() + Vector2(-90, -10), 20)
		await d.wait(0.42)
	await d.until(5.2)
	# the palace and its royal K crest; it glows on "calm 'em all down"
	d.cam_to(s.palace + Vector2(480, 470), 1.0, 0.0)
	d.cam_to(s.palace + Vector2(493, 600), 2.2, 1.6)
	await d.until(6.2)
	s.crest.modulate.a = 0.95
	d.flash(0.35)
	s.crest.create_tween().tween_property(s.crest, "modulate:a", 0.4, 0.5)
	await d.until(6.8)
	# …and they shuffle apart, sheepish (backing away, still facing each other)
	d.cam_to(s.lawn + Vector2(480, 900), 1.3, 0.0)
	d.walk("t_leather", s.lawn.x + 250, 0.8)
	d.walk("t_vapour", s.lawn.x + 710, 0.8)
	d.face("t_leather", 1.0)
	d.face("t_vapour", -1.0)
	await d.until(7.7)

	# 7.7 "Hybrids in the hollow" — stardust falls and they light up
	d.cam_to(s.hollow + Vector2(480, 1160), 1.0, 0.0)
	_stardust(d, s.hollow + Vector2(480, 780))
	await d.until(8.35)
	d.flash(0.5)
	for a in s.hybrids:
		a.create_tween().tween_property(a, "modulate", Color(1.12, 1.08, 1.0), 0.35)
		d.glow(a.position + Vector2(0, -80), 150, Color(1.0, 0.85, 0.5, 0.45), -1)
	await d.until(9.0)
	# "half kettle" — Puffalo pops in; "half cow" — Clatterhoof stomps in
	d.actors.t_puffalo.modulate.a = 1.0
	d.pop("t_puffalo", 0.5)
	await d.until(9.4)
	d.actors.t_puffalo.modulate.a = 0.0
	d.actors.t_clatterhoof.modulate.a = 1.0
	d.pop("t_clatterhoof", 0.4)
	d.shake(8.0)
	await d.until(10.1)

	# 10.1 "Kattlefish splashin' in the lagoon" — fish leap along the river
	d.cam_to(s.river + Vector2(330, 560), 1.7, 0.0)
	d.cam_to(s.river + Vector2(600, 470), 1.7, 1.6, Tween.TRANS_LINEAR)
	for i in 3:
		_leap(d, s.river + Vector2(260 + i * 150, 600 - i * 50), i + 1 if i < 2 else 4)
		await d.wait(0.42)
	await d.until(11.75)
	# "Arr, take a bow!" — Captain Gill pops up by the dock and bows
	d.cam_to(s.dock + Vector2(400, 1220), 1.35, 0.0)
	var gill: Sprite2D = s.gill
	gill.create_tween().tween_property(gill, "position:y", s.dock.y + 1230, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	d.puff(s.dock + Vector2(330, 1320), 12, 0.7, Color(0.75, 0.9, 1.0), 4)
	await d.until(12.4)
	var bow := gill.create_tween()
	bow.tween_property(gill, "rotation", 0.4, 0.2)
	bow.tween_property(gill, "rotation", 0.0, 0.25).set_delay(0.15)
	await d.until(13.0)

	# 13.0 "villain in the slammer" — Rusty rattles the bars, Grimey jumps back
	d.cam_to(s.jail + Vector2(430, 1090), 1.1, 0.0)
	await d.wait(0.2)
	for i in 2:                                          # Rusty rattles the bars
		d.pop("t_jrusty", 0.25)
		d.shake(5.0)
		await d.wait(0.18)
	d.sfx("RATTLE RATTLE", s.jail + Vector2(470, 950), 20)
	d.pop("t_jgrimey", 0.5)                             # Grimey jumps back
	var jg: Actor = d.actors.t_jgrimey
	jg.create_tween().tween_property(jg, "position:x", jg.position.x - 50.0, 0.2)
	await d.until(14.2)
	# "…and a puppy on the go" — Dukie zooms past, Rusty double-takes
	var dk: Sprite2D = s.dukie
	dk.create_tween().tween_property(dk, "position:x", s.jail.x + 1200, 0.9)
	await d.until(14.65)
	d.face("t_jrusty", 1.0)
	await d.wait(0.15)
	d.face("t_jrusty", -1.0)
	await d.wait(0.15)
	d.face("t_jrusty", 1.0)
	d.pop("t_jrusty", 0.4)
	await d.until(15.7)

	# 15.7 "It's the Kattles Show!" — everyone, logo slams in on "Show!"
	d.cam_to(s.finale + Vector2(480, 660), 1.0, 0.0)
	for i in 7:
		d.pop("t_f%d" % i, 0.3)
	await d.until(16.6)
	var logo: Label = s.logo
	var lt := logo.create_tween()
	lt.tween_property(logo, "scale", Vector2(1.25, 1.25), 0.12)
	lt.tween_property(logo, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	d.flash(0.6)
	d.shake(10.0)

func _lyrics(d: Director) -> void:
	for l in LYRICS:
		await d.until(l[0])
		if l[1] == "It's the Kattles Show!":
			d.sub(l[1], Color(1.0, 0.85, 0.35), 32)
		else:
			d.sub(l[1])

## Golden sparkles drifting down over the hollow.
func _stardust(d: Director, pos: Vector2) -> void:
	var p := d.puff(pos, 60, 0.25, Color(1.0, 0.9, 0.55), 6, true)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(480, 20)
	p.direction = Vector2(0, 1)
	p.spread = 15.0
	p.gravity = Vector2(0, 60)
	p.initial_velocity_min = 80.0
	p.initial_velocity_max = 160.0
	p.lifetime = 2.5
	d.get_tree().create_timer(2.5).timeout.connect(func(): p.emitting = false)

## One Kattlefish arcing out of the water and back in, with splashes.
func _leap(d: Director, from: Vector2, kind: int) -> void:
	var f := d.sprite("res://assets/props/theme/kattlefish_%d.png" % kind, from, 0.11, 3, true)
	d.puff(from, 6, 0.4, Color(0.75, 0.9, 1.0), 4)
	var to := from + Vector2(170, 0)
	var tw := f.create_tween()
	tw.tween_method(func(t: float):
		f.position = from.lerp(to, t) + Vector2(0, -160.0 * sin(PI * t))
		f.rotation = lerpf(-0.6, 0.6, t), 0.0, 1.0, 0.8)
	tw.tween_callback(func(): d.puff(to, 6, 0.4, Color(0.75, 0.9, 1.0), 4))
	tw.tween_callback(f.queue_free)
