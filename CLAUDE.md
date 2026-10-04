# Kattles Game (2026)

A 2D open-world game (Stardew-esque) for Kate — successor to the 2025 `/kattlesday`
cutscene + character chat. You walk a top-down/side village, talk to the Kattles &
Hybrids, do quests, and hit date-gated events. Built in **Godot 4.7**.

Characters are **cutout puppets** built from the existing flat character art (the same
PNGs used by `kattles_web`). We cut each character into parts, rig hip/joint pivots, and
animate procedurally in GDScript. No 3D, no hand-drawn frames.

---

## Tooling

- **Godot 4.7** — `godot` on PATH (standalone binary in `~/.local/opt/godot`).
- **Aseprite 1.3.17.2** — `aseprite` on PATH, headless scripting via `aseprite -b -script x.lua`.
  (Not needed for the current pipeline; kept for future touch-ups / batch export.)
- **Python sprite venv** — `../.venv-sprite/` (repo root), has Pillow + numpy + scipy.
  All cutting/cleanup scripts run with `../.venv-sprite/bin/python`.
- **OpenAI image gen** — key in `../kattles_rust/.env` (`OPENAI_API_KEY`). Used to generate
  side-profile / alternate-facing views of a character while keeping the design.
  **Never print or commit the key.** Load it into a shell var, use it, don't echo it.

Run the game: `godot --path /home/boomcruiser/Projects/kattles/kattles_game`
Headless import (regenerate texture cache after adding assets): `godot --headless --import`
Smoke-test scenes without a GPU: `godot --headless --quit-after 120` (runs scripts, catches errors).

---

## The animation pipeline (current: Spotilda = reference rig)

### 1. Pick the facing the motion needs
- **Blob / roughly-symmetric bipeds** (e.g. Rusty, most Kettles): the existing **front-3/4**
  portrait walks fine — feet are centered, so a front-view shuffle reads OK.
- **Long-bodied / quadrupeds** (e.g. Cattles): a front view makes lateral walking look like
  sliding. They need a **side profile**. Generate one (see below). Decide **per character** —
  not everyone needs a new asset.

### 2. (If needed) generate a side-profile asset
gpt-image-1 `images/edits`, 1024×1024 RGBA, `background=transparent`. Face **left** (flip
in-engine). Store as `assets/<name>_side/source.png`. What actually works:
- **Read the character first** (`../kattles_rust/prompts/<name>.txt`) — personality + pronouns.
- Pass **two refs** via `image[]`: the original portrait (design, proportions, face) and an
  existing painterly side view (e.g. `assets/daisybell_side/source.png`) for rendering style.
- Ask for a **neutral stance**: all four legs straight down, separated, none hidden, hooves on
  one line. Mid-stride art can't be animated convincingly.
- Say explicitly: painterly semi-realistic, **NOT flat/cartoon, no thick outlines**; short sturdy
  legs like the portrait; face/expression **from the portrait** (closed-mouth smile).
- Masked edits don't work as patches — the API repaints the whole image. Regenerate instead.
- Check alpha for a faint generated ground shadow; drop it with a per-character `alpha`.

### 3. Cut + rig: `tools/cut_side_quad.py <name>`
One config block per character (polygon per leg, `top`/`cut` rows, `hip`, optional `knee`,
`near`, `order`, `alpha`, `scene`). It does the cut, keep-largest-CC, near-leg feathering,
leg-width trimming of the overlap band, knee split (upper extends 24px past the knee, fading, to
fill the wedge a bent knee opens), a `_cut.png` magenta check, a `_sidewalk.png` filmstrip using
the same math as `side_quad.gd`, and — if `scene` is set — writes `<Name>.tscn`.
Profile the leg rows (opaque runs per row) to place polygons, hips (just under the belly line)
and knees (front ~1/3 down the leg, hock ~halfway on back legs).

### 4. Walk: `side_quad.gd` (shared by all Cattles)
4-beat cow walk (near back → near front → far back → far front). Each hoof is planted for
`duty` of the cycle and sweeps back linearly; the cycle rate is derived from `move_speed` and
leg length so planted hooves never slide. During swing a knee rig folds its `Lower` child back
(`knee_bend`); rigid legs get a vertical `lift` instead. Pivots use the full-canvas trick:
`position = P - C`, `offset = -(P - C)`; a knee child uses `position = K - P`, `offset = -(K - C)`.

### 5. Verify
Filmstrip first, then `--headless --import` + `--quit-after`, then **record the real game**:
`godot --path . --write-movie <dir>/f.png --fixed-fps 30 --quit-after 45` and `Read` a contact
sheet of frames. Judge motion from real frames, not the filmstrip alone.

---

## Hard-won gotchas

- **Flat-cut appendages can't rotate independently against a shared silhouette edge.** A tail
  rotated at the body seam always opens a gap (the true root, hidden behind the body, isn't in
  the flat art). Fixes that work: (a) whole-rig motion, or (b) split the appendage so the moving
  part hangs in **open space** (e.g. tail = static stalk glued to body + a **tuft** that flicks
  at the stalk tip). Limbs are fine to swing because they lift/arc into the body, which covers
  the joint — they don't share a silhouette edge the way a side-attached tail does.
- **Front view ≠ walkable for long bodies.** Match the asset facing to the motion.
- **Keep the source portraits untouched** in `kattles_web`. Generated game views live here in
  `assets/<name>_side/`.

---

## Layout

```
kattles_game/
  project.godot        # main_scene = Viewer.tscn (review mode), 960x540
  Viewer.tscn / viewer.gd  # one puppet at a time, big; ←/→ to switch
  Main.tscn / main.gd  # old crowded demo stage (all puppets + Rusty)
  side_quad.gd         # shared Cattle walk (4-beat, no-slide, optional knees)
  <Name>.tscn          # per-Cattle rig (Spotilda's is generated by the cut tool)
  Rusty.tscn / rusty.gd            # front-view biped puppet (feet translate-swing)
  front_biped.gd                   # shared upright march (Lieutenant, Nocturna, Boilbert)
  tools/cut_front_biped.py         # front/upright cut + filmstrip + scene generation
  tools/cut_side_quad.py           # cut + filmstrip + scene generation
  assets/<name>_side/  # source.png + body + legN (+ legN_lo knee parts)
```

## Status — all 22 characters rigged
- Cattles (8): Spotilda + Wanderella on the side-view knee rig; Buttercup, Daisybell, Fluffhorn,
  Moozie on the older rigid-leg side rig (user is fine with them — don't redo unprompted);
  Lieutenant Leather + Nocturna upright on the front biped rig.
- Kettles (8): Rusty (old rusty.gd); Boilbert, Brewster, Bubbly, Grimey, Hissy, Steamy,
  Inspector Vapour on the front biped rig (portrait as-is, except Grimey = faithful regen).
- Hybrids (6): side_quad rig. Bubblehorn = faithful regen of the original; Clatterhoof,
  Snortle, Puffalo = original art, stomp in place (`swing: 0`, `step_rate`); Moosteam, Whispy =
  original art, sweep walk.

## Hybrid art notes
- The kattles_web Hybrid cutouts have baked checkerboard (fake transparency) in handle loops /
  between legs; some lost fur to bad background removal. Clear checker by seeded flood-fill of
  low-saturation light pixels, or clip below the belly outside the leg columns.
- The user strongly prefers ORIGINAL art. Re-angled regens and pixel flips were rejected as
  off-style. For front-ish portraits use stomp-in-place instead of new art.
- Undamaged originals (opaque bg) live in kattles_web's first commit (`1bc655a`).
- `tools/strip_border.py` removes an orange sticker border gpt-image-1 sometimes adds.

## Upright / front-view characters: `tools/cut_front_biped.py <name>` + `front_biped.gd`
Body + LegL/LegR (behind body) + optional ArmL/ArmR (in front). March: legs lift in turn,
arms swing inward only, body dips + rocks. Per-character `scene` overrides (speed, lift, bob,
tilt, `arm_l_amount`/`arm_r_amount`, `faces_left`). Use the portrait as-is when it is already
slightly turned with feet planted apart (Rusty, Lieutenant, Boilbert). If it faces dead-on, it
slides when walking sideways — generate a 3/4 NEUTRAL-stance view where head, eyes, body and
feet all turn the same way (Nocturna). Check facing by snout/eyes, not the tail.

## Constraints (carry over from 2025)
- Never expose API keys (`../kattles_rust/.env`).
- Never generate Princess Kate's voice.
