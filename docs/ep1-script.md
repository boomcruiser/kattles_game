# EP1 — "Community Service" (pilot)

**Status:** DRAFT beat sheet (TL;DR). Timings are targets; beats need fleshing out with
more action, pauses, and lines to actually fill them.

**Setting:** After Kattles Day 2026. Rusty sabotaged the great boiler, the Hybrids redeemed
themselves, Kate's pigeons' stardust saved the day, and Dukie caught Rusty. Rusty is jailed.
(Canon: `../kattles_rust/prompts/_events.txt`, `../kattles_web/docs/kattles-day-plan.md`.)

**Season notes:**
- Escape is NOT ep1 — hook for ep2+.
- Ep1 arc: Rusty sentenced to community service.
- "Visiting hours" — characters visit Rusty in jail for their own reasons; use as cutaway
  segues between scenes, or one visitor per episode.

---

## Cold open (0:00–2:00)

### 0:00–0:20 · Establishing
- Exterior: Kattles Jail at night (`assets/sets/jail_exterior.png`) — half Steamtown stone block
  with a teapot dome, half Cattle Valley barn with a bull head over the door. Slow push-in on
  the glowing barred window; spout steams, pipe drips.
- Interior: Inspector Vapour's empty desk outside the cells. Slow pan across it: teacup,
  magnifying glass, and a newspaper — **"KATTLES DAY SAVED! RUSTY CAUGHT BY ROYAL HOUND"**
  with a photo of Rusty knocked over on his side, Dukie standing on top. (Visual only — establishes backstory for new viewers.)
- Pan continues into the cell: Rusty on the bunk staring at the ceiling, sighing a puff of steam.
- Hold on him. Drip… drip… drip… Rusty: *"Is anyone going to fix that damn thing?!"*

### 0:20–0:50 · Hating his life
- Close on the wall: two tally marks already. SCREEEECH — he scratches a third.
  Pull back. *"Three days?" … "That's a lifetime in Kattle years."*
- Breakfast through the slot: a single sad teabag (`assets/props/teabag_decaf.png`). Close on the tag: **DECAF**.
  *"Decaf?!" … "…Yuck."*
- Brews it himself: drops the teabag in his lid, strains. Sounds only — plop, glug glug,
  CLANK, wheeeeze, a puff of rust dust. Beat. *"…That can't be good."*
- Spider in the corner staring at him. *"Don't look at me like that."*

### 0:50–1:20 · Scheming
- Paces, scheming. Thought bubble: *"…the boiler… the palace… Kattles Day…"* (no wall drawing)
- *"Heh. They think bars can hold me? Next Kattles Day… I'll—"*
- Evil laugh builds: *"Heh… heh heh… HEH HEH HA—"*

### 1:20–1:45 · The interruption
- Keys jangle. Inspector Vapour enters, cheerful, holding a scroll.
- Vapour: *"Bonjour, Rusty! I bring news from ze Princess 'erself."*
- Rusty whistles innocently.
- Plain, small scroll (`assets/props/decree_scroll.png`), no close-up. Vapour: *"By royal decree… you are sentenced to…"* (dramatic pause) *"…community service!"*

### 1:45–2:00 · Shock + smash cut
- Zoom on Rusty's face. Lid pops up with a steam burst.
- Rusty: ***"COMMUNITY SERVICE?!"***
- Freeze-frame → smash cut to **theme song**.

---

## Rough cut
`godot --path . res://Episode.tscn` (R replay, Esc quit) — script: `episodes/ep1_cold_open.gd`.
Record: `godot --path . res://Episode.tscn --write-movie <dir>/ep1.avi --fixed-fps 30`.

## Production needs (cold open)
- Backgrounds: jail exterior (done), jail interior w/ Vapour's desk (`bg-jail.png` exists in kattles_web).
- Props: newspaper (headline + Dukie-on-fallen-Rusty photo), teacup, magnifying glass,
  teabag, spider, tally marks, scroll, keys.
- Animation: camera pan/push/zoom, speech bubbles, talk-bob, idle, Rusty lid-pop + steam
  burst, pacing (existing walk), Vapour walk-in (existing rig), freeze-frame.
- Audio: drip, keys, wheeze-whistle, steam burst, theme song.
