"""Cut a front-facing upright biped portrait into body + 2 legs + 2 arms.

Usage: ../.venv-sprite/bin/python tools/cut_front_biped.py <name>

Each limb is a polygon region (image coords) with a `cut` row: the limb part keeps the
region's pixels from `top` down; the body drops the region's pixels from `cut` down, so
the body still covers the joint (legs are drawn behind the body, arms in front with a
feathered top). Writes assets/<name>_front/{body,leg_l,leg_r,arm_l,arm_r}.png, a magenta
_cut.png, a _walk.png filmstrip using the same math as front_biped.gd, and <Name>.tscn.
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

ROOT = Path(__file__).resolve().parent.parent
PORTRAITS = ROOT.parent / "kattles_web" / "app" / "assets" / "images" / "Kattles"

CONFIGS = {
    "lieutenant-leather": {
        "title": "LieutenantLeather",
        "source": "Cattles/lieutenant-leather.png",
        "parts": {
            # legs: trousers + shoes below the belt; tops tuck behind the body
            "leg_l": {"poly": [(225, 495), (310, 495), (310, 600), (225, 600)],
                      "top": 498, "cut": 516, "pivot": (272, 508)},
            "leg_r": {"poly": [(310, 495), (400, 495), (400, 600), (310, 600)],
                      "top": 498, "cut": 516, "pivot": (348, 508)},
            # arms: sleeve + forearm + hand; drawn in front, feathered at the top
            "arm_l": {"poly": [(150, 330), (238, 330), (234, 420), (214, 470), (214, 530), (150, 530)],
                      "top": 345, "cut": 372, "pivot": (212, 362)},
            "arm_r": {"poly": [(392, 330), (460, 330), (460, 530), (408, 530), (408, 470), (398, 420)],
                      "top": 345, "cut": 372, "pivot": (396, 362)},
        },
        "scene": {"move_speed": 55, "left_bound": 120, "right_bound": 840},
    },
}

# must match front_biped.gd defaults
WALK = {"lift": 14.0, "stride": 6.0, "arm_swing": 0.12, "bob": 4.0, "tilt": 0.025}
ORDER = ["leg_l", "leg_r", "body", "arm_l", "arm_r"]


def largest_cc(mask):
    lab, n = ndimage.label(mask)
    if n <= 1:
        return mask
    sizes = ndimage.sum(mask, lab, range(1, n + 1))
    return lab == (int(np.argmax(sizes)) + 1)


def poly_mask(shape, poly):
    img = Image.new("L", (shape[1], shape[0]), 0)
    ImageDraw.Draw(img).polygon(poly, fill=1)
    return np.array(img).astype(bool)


def to_rgba(src, mask, fade=None):
    out = src.copy()
    a = np.where(mask, src[..., 3], 0).astype(np.float32)
    if fade is not None:
        top, cut = fade
        t = np.clip((np.arange(src.shape[0]) - top) / max(cut - top, 1), 0, 1)[:, None]
        a *= t * t * (3 - 2 * t)
    out[..., 3] = a.astype(np.uint8)
    return Image.fromarray(out)


def rotate_about(img, angle_rad, pivot):
    return img.rotate(-np.degrees(angle_rad), resample=Image.BICUBIC, center=pivot)


def pose(p):
    """Same math as front_biped.gd: returns per-part (dx, dy, rot) and body (dy, rot)."""
    s = np.sin(2 * np.pi * p)
    lift_l = WALK["lift"] * max(0.0, s)
    lift_r = WALK["lift"] * max(0.0, -s)
    return {
        "leg_l": (WALK["stride"] * s, -lift_l, 0.0),
        "leg_r": (-WALK["stride"] * s, -lift_r, 0.0),
        # arms only swing inward (toward the torso, which covers them) - an outward
        # swing would open a gap where the forearm was cut out of the body
        "arm_l": (0.0, 0.0, -WALK["arm_swing"] * max(0.0, -s)),
        "arm_r": (0.0, 0.0, WALK["arm_swing"] * max(0.0, s)),
        "body": (0.0, WALK["bob"] * 0.5 * (1 - np.cos(4 * np.pi * p)), WALK["tilt"] * s),
    }


def main(name):
    cfg = CONFIGS[name]
    d = ROOT / "assets" / f"{name}_front"
    d.mkdir(parents=True, exist_ok=True)
    src_img = Image.open(PORTRAITS / cfg["source"]).convert("RGBA")
    src_img.save(d / "source.png")
    src = np.array(src_img)
    h, w = src.shape[:2]
    alpha = src[..., 3] > cfg.get("alpha", 60)
    rows = np.arange(h)[:, None]

    body = alpha.copy()
    masks = {}
    body_fade = np.ones((h, w), np.float32)
    for pname, pc in cfg["parts"].items():
        region = poly_mask(src.shape, pc["poly"]) & alpha
        masks[pname] = largest_cc(region & (rows >= pc["top"]))
        body &= ~(region & (rows >= pc["cut"]))
        if pname.startswith("leg"):
            # body's trouser bottom fades into the legs drawn behind it (no hard hem line
            # when a leg lifts)
            t = np.clip((np.arange(h) - pc["top"]) / max(pc["cut"] - pc["top"], 1), 0, 1)[:, None]
            ramp = 1 - t * t * (3 - 2 * t)
            body_fade = np.where(region, np.minimum(body_fade, ramp), body_fade)
    masks["body"] = largest_cc(body)

    imgs = {}
    for pname, m in masks.items():
        pc = cfg["parts"].get(pname, {})
        fade = (pc["top"], pc["cut"]) if pname.startswith("arm") else None
        imgs[pname] = to_rgba(src, m, fade)
        if pname == "body":
            arr = np.array(imgs[pname])
            arr[..., 3] = (arr[..., 3] * body_fade).astype(np.uint8)
            imgs[pname] = Image.fromarray(arr)
        imgs[pname].save(d / f"{pname}.png")

    check = Image.new("RGBA", (w, h), (255, 0, 255, 255))
    for pname in ORDER:
        check.alpha_composite(imgs[pname])
    check.save(d / "_cut.png")

    frames = []
    for p in np.linspace(0, 1, 8, endpoint=False):
        f = Image.new("RGBA", (w, h), (40, 44, 60, 255))
        ps = pose(p)
        for pname in ORDER:
            dx, dy, rot = ps[pname]
            pivot = cfg["parts"][pname]["pivot"] if pname != "body" else (w / 2, h * 0.85)
            layer = Image.new("RGBA", (w, h))
            layer.alpha_composite(rotate_about(imgs[pname], rot, pivot), (int(round(dx)), int(round(dy))))
            f.alpha_composite(layer)
        frames.append(f.crop((100, 0, 500, 600)).resize((200, 300)))
    strip = Image.new("RGBA", (200 * 8, 300))
    for i, f in enumerate(frames):
        strip.paste(f, (i * 200, 0))
    strip.save(d / "_walk.png")

    write_scene(name, cfg, (w / 2, h / 2), (w / 2, h * 0.85))


def write_scene(name, cfg, center, body_pivot):
    cx, cy = center
    res, nodes = [], []
    for pname in ORDER:
        res.append(f'[ext_resource type="Texture2D" path="res://assets/{name}_front/{pname}.png" id="{len(res) + 1}"]')
        if pname == "body":
            px, py = body_pivot
            node = "Body"
        else:
            px, py = cfg["parts"][pname]["pivot"]
            node = {"leg_l": "LegL", "leg_r": "LegR", "arm_l": "ArmL", "arm_r": "ArmR"}[pname]
        ox, oy = px - cx, py - cy
        nodes.append(f'[node name="{node}" type="Sprite2D" parent="."]\n'
                     f'position = Vector2({ox:g}, {oy:g})\noffset = Vector2({-ox:g}, {-oy:g})\n'
                     f'texture = ExtResource("{len(res)}")\n')
    props = "\n".join(f"{k} = {float(v)}" for k, v in cfg["scene"].items())
    out = [f"[gd_scene load_steps={len(res) + 2} format=3]", "",
           '[ext_resource type="Script" path="res://front_biped.gd" id="0"]', *res, "",
           f'[node name="{cfg["title"]}" type="Node2D"]\nscript = ExtResource("0")\n{props}\n', *nodes]
    (ROOT / f'{cfg["title"]}.tscn').write_text("\n".join(out))
    print(f'wrote {cfg["title"]}.tscn')


if __name__ == "__main__":
    main(sys.argv[1])
