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

## The animation pipeline (validated on Rusty + Buttercup)

### 1. Pick the facing the motion needs
- **Blob / roughly-symmetric bipeds** (e.g. Rusty, most Kettles): the existing **front-3/4**
  portrait walks fine — feet are centered, so a front-view shuffle reads OK.
- **Long-bodied / quadrupeds** (e.g. Cattles): a front view makes lateral walking look like
  sliding. They need a **side profile**. Generate one (see below). Decide **per character** —
  not everyone needs a new asset.

### 2. (If needed) generate a side-profile asset
Use gpt-image-1 `images/edits` with the original portrait as the input image. Prompt for a
full-body **side profile facing LEFT**, same design/colors/markings/accessories, walking
stance, all limbs visible, **transparent background**, centered, no text. Output is 1024×1024
RGBA. gpt-image-1 keeps the character identity well. Convention: face **left**; flip in-engine
for rightward travel. Store under `assets/<name>_side/source.png`.

### 3. Cut into parts (Python, `../.venv-sprite/bin/python`)
- Source PNGs already have a transparent background — mask with `alpha > 60`.
- Profile the bottom rows to find limbs: count opaque horizontal runs per row. Distinct runs =
  distinct legs; a merged run = occlusion (far legs behind near legs — happens in front views,
  not clean side views).
- Split limbs by x-ranges at the gaps. Cut each limb with its **top overlapping up into the
  torso** (e.g. `LEG_TOP` a bit above the belly line) so the body can cover the joint.
- Body = everything minus the **lower** (swinging) part of each limb. Keep the belly band so the
  body silhouette covers the hip tops.
- **Always keep-largest-connected-component per part** (`scipy.ndimage.label`) to drop stray
  slivers from straight-line splits and isolated coat-spot fragments. This is mandatory — both
  Buttercup's leg sliver and a floating body blob came from skipping it.

### 4. Rig in Godot
- Each part is a `Sprite2D` on the **same full-canvas texture**, so parts reassemble perfectly
  when all node positions are `(0,0)`.
- To pivot a part at a joint P (image coords, canvas center = C): set the node
  `position = P - C` and `offset = -(P - C)`. Then the texture still lands in its original spot,
  but rotation/scale pivot at P. (Used for hips and tails.)
- **Draw order** = back-to-front child order. Body must be drawn **over** limb tops so the joint
  is hidden. Far-side limbs behind body, near-side limbs in front. Example side-walk order:
  `Leg2, Leg3, Body, Leg1, Leg4`.
- Animate procedurally in `_process`: swing limbs by `rotation = swing * sin(_t + phase)`,
  diagonal gait (outer front + outer back same phase, inner pair opposite), plus a body bob
  `position.y = -bob * abs(sin(_t))`. Self-propel with `position.x += dir * speed * delta` and
  flip facing with `scale.x` (asset faces left → `scale.x = base * -dir`).

### 5. Verify before running
Render the cut on a magenta bg (spot halos/slivers) and render a few animation phases as a
filmstrip PNG using the **same math** as the GDScript, then `Read` it. Catches gaps/floaters
without a GPU. Then `--headless --import` + `--quit-after` to catch script/scene errors.

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
  project.godot        # main_scene = Main.tscn, 960x540
  Main.tscn / main.gd  # demo stage: Rusty (front biped walk) + Buttercup (side quad walk)
  Rusty.tscn / rusty.gd            # front-view biped puppet (feet translate-swing)
  Buttercup.tscn / buttercup.gd    # side-view quadruped puppet (4 legs hip-swing)
  assets/
    rusty/             # body + foot_l + foot_r (front)
    buttercup_side/    # source.png + body + leg1..leg4 (left-facing side profile)
```

## Adding a character (checklist)
1. Decide facing (front portrait vs generated side profile).
2. Generate side asset if needed → `assets/<name>_side/source.png`.
3. Write a cut script → parts + keep-largest-CC cleanup.
4. Note joint pivots (printed by the cut script, image coords).
5. Build `<Name>.tscn` (Sprite2D per part, pivots via position/offset, correct draw order) and
   `<name>.gd` (procedural walk/idle).
6. `--headless --import`, smoke-test, then run and eyeball.

## Constraints (carry over from 2025)
- Never expose API keys (`../kattles_rust/.env`).
- Never generate Princess Kate's voice.
