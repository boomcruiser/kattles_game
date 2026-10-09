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
- Breakfast through the slot. Rusty: *"Eh… what do we have for dinner?"* A single sad teabag (`assets/props/teabag_decaf.png`). Close on the tag: **DECAF**.
  *"Decaf?!" … "…Yuck."*
- Brews it himself: drops the teabag in his lid, strains. Sounds only — plop, glug glug,
  CLANK, wheeeeze, a puff of rust dust. Beat. *"…That can't be good."*
- Spider in the corner staring at him. *"What? Like you've never farted in public?"*

### 0:50–1:20 · Scheming
- One short pace under a sneaky tension music bed (no thought line).
- *"Heh. They think bars can hold me? Next Kattles Day… I'll—"*
- Evil laugh builds: *"Heh… heh heh… HEH HEH HA—"*

### 1:20–1:45 · The interruption
- Keys jangle (tension cuts dead). Rusty: *"What the heck?"* as Inspector Vapour walks in, cheerful, holding a scroll.
- Vapour: *"Bonjour, Rusty! I bring news from ze Princess 'erself."*
- Rusty whistles innocently.
- Plain, small scroll (`assets/props/decree_scroll.png`), no close-up. Vapour: *"By royal decree… you are sentenced to…"* (dramatic pause) *"…community service!"*

### 1:45–2:00 · Shock + smash cut
- Zoom on Rusty's face. Lid pops up with a steam burst.
- Rusty: ***"COMMUNITY SERVICE?!"***
- Freeze-frame → smash cut to **theme song**.

---

## Episode outline (~13 min)

**Device:** Vapour hands Rusty a chore map with three stops; between areas a map card ticks
off the last task and inks the trail to the next. Dukie supervises all day on a leash
("Woof! Bad kettle. Dukie watch."). Each area follows one rhythm: arrive → meet the locals →
get the task → Rusty's shortcut backfires → Dukie moment → tick.

| # | Scene | ~Time | Beats | Status |
|---|---|---|---|---|
| 0 | Cold open + theme | 2:00 | Jail, decaf, scheming, "COMMUNITY SERVICE?!", theme | ✅ done |
| 1 | **The handoff** | 1:10 | Morning at the jail; Vapour introduces Dukie as supervisor — "The *puppy*?!"; leash; chore map; Dukie bolts after a butterfly and drags Rusty off | 🎬 rough cut |
| 2 | **Steamtown — scrub the soot** | 2:30 | Boilbert at the gate won't let him in ("Banned."); Hissy complains nonstop; Brewster chills with the boombox; Bubbly too cheerful. Shortcut: blasts steam to clean → soaks Hissy. Tick ✔ | |
| 3 | **Cattle Valley — fix the fence** | 2:30 | Stampede damage from Kattles Day. Lt. Leather supervises; Wanderella's tour ("And here, folks, a real villain"); Spotilda spins around him; Moozie critiques his paint job. Dukie chases a bunny-shaped hedge, drags Rusty. Tick ✔ | |
| 4 | **Hybrid Hollow — relight the lanterns** | 3:00 | The heart. Awkward reunion with the Hybrids he tricked; Clatterhoof bumps him, Snortle snorts, Whispy softly: "We forgave you." Last lantern won't light → he grudgingly uses his own steam → the hollow glows (Kattles Day callback). "My steam… slipped." Tick ✔ | |
| 5 | **Walk back at sunset** | 0:45 | Dukie falls asleep on the leash; Rusty eyes the open road… Dukie wakes: "Woof." (quiet tease, no escape) | |
| 6 | **The cell, night** | 1:00 | Tally #4. "I didn't enjoy that. Not one bit." Teabag thunks through the slot — NOT decaf, with a thank-you note from the Hybrids. Tiny smile, quick scowl | |
| 7 | **Visiting hours (tag)** | 0:30 | "VISITING HOURS" card; Grimey at the bars: "Boss! I brought cake!" Rusty eyes the cake → black (EP2 hook) | |

Escape plots wait for later episodes. Voices for scenes 1+ are generated at the very end
(voice IDs already on the ElevenLabs account: Dukie `8DPBVVnfn0Cti23BGSz9`, Leather,
Grimey, Snortle, Whispy).

---

## Scene 1 — The handoff (`episodes/ep1_s1_handoff.gd`)
- Morning, wide on Kattles Jail (`assets/sets/jail_exterior_day.png`), push in.
  Offscreen Cattle: *"Moo-a-doodle-doo!"*
- Door creaks open. Vapour steps out: *"Allez, allez! Ze sun is up, and so are you!"*
  Rusty shuffles out of the dark, squints: *"Ugh. Is that… the sun? Great. Now I'm gonna get a tan."*
  Vapour: *"Monsieur… zat is not a tan. Zat is rust."* Rusty: *"It's a VINTAGE FINISH. Do you know
  what UV does to a vintage finish?"*
- Vapour: *"Of course, you will not be working alone. Ze Princess 'as assigned you… a supervisor."*
  Rusty: *"A supervisor? Let me guess — Boilbert? Lieutenant Leather?"* Vapour: *"Non."* (points)
- Pan to the hay bales: Dukie, squeaking his bunny. *"Woof!"* Snap zoom: ***"The PUPPY?!"***
- Dukie hops down, trots over, sniffs. *"Woof! Bad kettle. Dukie watch."*
  Rusty: *"That mutt is the reason I'm in here!"* Vapour: *"Exactement. 'E caught you once… 'e can catch you again."*
- *click* — leash onto Rusty's handle, Dukie holds the end. *"Oh, come ON."*
- Vapour: *"Now. Your tasks."* Map insert (`assets/props/chore_map.png`), each stop circled in red ink:
  *"One: scrub ze soot in Steamtown. Two: fix ze fence in ze Cattle Valley. Three: light ze
  lanterns in ze Hybrid 'Ollow."* Rusty: *"…The Hybrids?"* Vapour: *"All before sundown."*
- Rusty: *"And if I don't?"* Vapour sips tea: *"Zen… more decaf."* Rusty shudders. *"…Fine."*
- A butterfly drifts past; Dukie's eyes follow it. *"Don't. Don't you dare—"* *"WOOF!"* — Dukie
  bolts, the leash yanks Rusty flat and drags him off (*"WHOA—!"*). Vapour: *"Bon courage, mon ami."*
- Map card: dotted trail inks from the jail to Steamtown. Fade.

---

## Rough cut
`godot --path . res://Episode.tscn [-- --from=<section>]` (R replay, Esc quit) — `episodes/ep1.gd` runs the
scenes in order (`ep1_cold_open.gd`, `ep1_s1_handoff.gd`). Sections: exterior, cell, scheme, vapour,
shock, theme, handoff, supervisor, map, bolt.
Record: `godot --path . res://Episode.tscn --write-movie <dir>/ep1.avi --fixed-fps 30`.

## Production needs (cold open)
- Backgrounds: jail exterior (done), jail interior w/ Vapour's desk (`bg-jail.png` exists in kattles_web).
- Props: newspaper (headline + Dukie-on-fallen-Rusty photo), teacup, magnifying glass,
  teabag, spider, tally marks, scroll, keys.
- Animation: camera pan/push/zoom, speech bubbles, talk-bob, idle, Rusty lid-pop + steam
  burst, pacing (existing walk), Vapour walk-in (existing rig), freeze-frame.
- Audio: drip, keys, wheeze-whistle, steam burst, theme song.
