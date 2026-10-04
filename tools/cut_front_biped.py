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
    "nocturna": {
        "title": "Nocturna",
        # generated 3/4 view (portrait faces dead-on, which reads as sliding when
        # walking sideways); whole body turned toward the LEFT, tail behind on the right
        "source_local": True,
        "alpha": 110,  # faint generated ground shadow
        "parts": {
            # neutral stance: legs straight and side by side, separate below ~y782
            "leg_l": {"poly": [(330, 760), (496, 760), (496, 1010), (330, 1010)],
                      "top": 768, "cut": 792, "pivot": (432, 780)},
            "leg_r": {"poly": [(496, 760), (660, 760), (660, 1010), (496, 1010)],
                      "top": 768, "cut": 792, "pivot": (568, 780)},
            "arm_l": {"poly": [(255, 600), (357, 600), (357, 810), (255, 810)],
                      "top": 612, "cut": 645, "pivot": (335, 625)},
            # right hand covers the tail root: tail stays in the body, arm holds still
            "arm_r": {"poly": [(634, 600), (740, 600), (740, 740), (728, 800), (634, 800)],
                      "top": 612, "cut": 645, "pivot": (665, 625)},
        },
        "scene": {"move_speed": 45, "left_bound": 120, "right_bound": 840, "steps_per_sec": 1.5,
                  "arm_r_amount": 0, "faces_left": True},
    },
    "boilbert": {
        "title": "Boilbert",
        "source": "Kettles/boilbert.png",
        # robot legs (ball joint + foot) hang from the bottom plate; no swinging arms
        # (raised hose arm + side pipes would look wrong swinging)
        "parts": {
            "leg_l": {"poly": [(100, 446), (258, 446), (258, 600), (100, 600)],
                      "top": 446, "cut": 470, "pivot": (250, 466)},
            "leg_r": {"poly": [(372, 446), (560, 446), (560, 600), (372, 600)],
                      "top": 446, "cut": 470, "pivot": (392, 466)},
        },
        # heavy bouncer: slower, weightier steps, more body rock
        "scene": {"move_speed": 45, "left_bound": 120, "right_bound": 840, "steps_per_sec": 1.4,
                  "lift": 12, "bob": 6, "tilt": 0.04, "faces_left": True},
    },
    "brewster": {
        "title": "Brewster",
        "source": "Kettles/brewster.png",
        # stubby feet under the base; spout + handle stay fixed (spout leads: faces left)
        "parts": {
            "leg_l": {"poly": [(125, 470), (244, 470), (244, 545), (125, 545)],
                      "top": 470, "cut": 490, "pivot": (205, 480)},
            "leg_r": {"poly": [(352, 470), (470, 470), (470, 545), (352, 545)],
                      "top": 470, "cut": 490, "pivot": (395, 480)},
        },
        # chill and laid-back: slow lazy waddle, low lift, extra side-to-side sway
        "scene": {"move_speed": 35, "left_bound": 120, "right_bound": 840, "steps_per_sec": 1.2,
                  "lift": 8, "stride": 4, "bob": 3, "tilt": 0.06, "faces_left": True},
    },
    "bubbly": {
        "title": "Bubbly",
        "source": "Kettles/bubbly.png",
        # tiny feet under the glass base; spout leads (faces left); heart + sparkles
        # are separate pieces kept by keep_big
        "parts": {
            "leg_l": {"poly": [(160, 500), (242, 500), (242, 560), (160, 560)],
                      "top": 500, "cut": 527, "pivot": (205, 515)},
            "leg_r": {"poly": [(336, 500), (418, 500), (418, 560), (336, 560)],
                      "top": 500, "cut": 527, "pivot": (375, 515)},
        },
        # cheerful + energetic: quick hoppy steps
        "scene": {"move_speed": 70, "left_bound": 120, "right_bound": 840, "steps_per_sec": 2.4,
                  "lift": 12, "stride": 4, "bob": 7, "tilt": 0.03, "faces_left": True},
    },
    "grimey": {
        "title": "Grimey",
        # near-faithful regen of the portrait (input_fidelity=high), only slightly turned
        # left, ground shadow removed
        "source_local": True,
        "alpha": 110,
        "parts": {
            "leg_l": {"poly": [(195, 812), (440, 812), (440, 960), (195, 960)],
                      "top": 812, "cut": 834, "pivot": (362, 824)},
            "leg_r": {"poly": [(565, 812), (805, 812), (805, 960), (565, 960)],
                      "top": 812, "cut": 834, "pivot": (634, 824)},
        },
        # sneaky henchman: quick, low, shifty scuttle
        "scene": {"move_speed": 60, "left_bound": 120, "right_bound": 840, "steps_per_sec": 2.2,
                  "lift": 10, "stride": 5, "bob": 4, "tilt": 0.05, "faces_left": True},
    },
    "hissy": {
        "title": "Hissy",
        "source": "Kettles/hissy.png",
        # portrait already 3/4 (spout leads: faces left); ground-shadow ellipse clipped
        "floor": 546,
        "parts": {
            "leg_l": {"poly": [(186, 512), (262, 512), (262, 538), (253, 547), (198, 547), (186, 538)],
                      "top": 512, "cut": 526, "pivot": (228, 519)},
            "leg_r": {"poly": [(306, 512), (382, 512), (382, 538), (374, 547), (317, 547), (306, 538)],
                      "top": 512, "cut": 526, "pivot": (342, 519)},
        },
        # fussy complainer: prim, clipped little steps, stiff body
        "scene": {"move_speed": 45, "left_bound": 120, "right_bound": 840, "steps_per_sec": 2.0,
                  "lift": 7, "stride": 3, "bob": 2, "tilt": 0.015, "faces_left": True},
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


def keep_big(mask, min_px=400):
    """Keep every connected piece of at least min_px (the body can legitimately be in
    several pieces, e.g. a tail only attached through an arm that was cut out)."""
    lab, n = ndimage.label(mask)
    if n <= 1:
        return mask
    sizes = ndimage.sum(mask, lab, range(1, n + 1))
    return np.isin(lab, [i + 1 for i, sz in enumerate(sizes) if sz >= min_px])


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


def pose(p, scene=None):
    """Same math as front_biped.gd: returns per-part (dx, dy, rot) and body (dy, rot)."""
    scene = scene or {}
    al, ar = scene.get("arm_l_amount", 1.0), scene.get("arm_r_amount", 1.0)
    walk = {**WALK, **{k: v for k, v in scene.items() if k in WALK}}
    s = np.sin(2 * np.pi * p)
    lift_l = walk["lift"] * max(0.0, s)
    lift_r = walk["lift"] * max(0.0, -s)
    return {
        "leg_l": (walk["stride"] * s, -lift_l, 0.0),
        "leg_r": (-walk["stride"] * s, -lift_r, 0.0),
        # arms only swing inward (toward the torso, which covers them) - an outward
        # swing would open a gap where the forearm was cut out of the body
        "arm_l": (0.0, 0.0, -walk["arm_swing"] * al * max(0.0, -s)),
        "arm_r": (0.0, 0.0, walk["arm_swing"] * ar * max(0.0, s)),
        "body": (0.0, walk["bob"] * 0.5 * (1 - np.cos(4 * np.pi * p)), walk["tilt"] * s),
    }


def order_for(cfg):
    return [p for p in ORDER if p == "body" or p in cfg["parts"]]


def main(name):
    cfg = CONFIGS[name]
    order = order_for(cfg)
    d = ROOT / "assets" / f"{name}_front"
    d.mkdir(parents=True, exist_ok=True)
    if cfg.get("source_local"):
        # generated view already saved as assets/<name>_front/source.png
        src_img = Image.open(d / "source.png").convert("RGBA")
    else:
        src_img = Image.open(PORTRAITS / cfg["source"]).convert("RGBA")
        src_img.save(d / "source.png")
    src = np.array(src_img)
    h, w = src.shape[:2]
    alpha = src[..., 3] > cfg.get("alpha", 60)
    rows = np.arange(h)[:, None]
    if "floor" in cfg:
        # drop generated ground shadow: below the floor row keep only leg regions
        legs_area = np.zeros((h, w), bool)
        for pname, pc in cfg["parts"].items():
            if pname.startswith("leg"):
                legs_area |= poly_mask(src.shape, pc["poly"])
        alpha &= ~((rows >= cfg["floor"]) & ~legs_area)

    px = src.astype(int)
    bright = ((px[..., 0] + px[..., 1]) / 2 > 125) & (px[..., 0] - px[..., 2] > 35)
    body = alpha.copy()
    masks = {}
    body_fade = np.ones((h, w), np.float32)
    for pname, pc in cfg["parts"].items():
        region = poly_mask(src.shape, pc["poly"]) & alpha
        if "exclude_bright_above" in pc:
            # light cloth (poncho fringe) in front of the limb stays with the body
            region &= ~(bright & (rows < pc["exclude_bright_above"]))
        masks[pname] = largest_cc(region & (rows >= pc["top"]))
        body &= ~(region & (rows >= pc["cut"]))
        if pname.startswith("leg"):
            # body's trouser bottom fades into the legs drawn behind it (no hard hem line
            # when a leg lifts)
            t = np.clip((np.arange(h) - pc["top"]) / max(pc["cut"] - pc["top"], 1), 0, 1)[:, None]
            ramp = 1 - t * t * (3 - 2 * t)
            body_fade = np.where(region, np.minimum(body_fade, ramp), body_fade)
    masks["body"] = keep_big(body)

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
    for pname in order:
        check.alpha_composite(imgs[pname])
    check.save(d / "_cut.png")

    frames = []
    for p in np.linspace(0, 1, 8, endpoint=False):
        f = Image.new("RGBA", (w, h), (40, 44, 60, 255))
        ps = pose(p, cfg["scene"])
        for pname in order:
            dx, dy, rot = ps[pname]
            pivot = cfg["parts"][pname]["pivot"] if pname != "body" else (w / 2, h * 0.85)
            layer = Image.new("RGBA", (w, h))
            layer.alpha_composite(rotate_about(imgs[pname], rot, pivot), (int(round(dx)), int(round(dy))))
            f.alpha_composite(layer)
        frames.append(f.crop((w // 6, 0, w * 5 // 6, h)).resize((200, 300)))
    strip = Image.new("RGBA", (200 * 8, 300))
    for i, f in enumerate(frames):
        strip.paste(f, (i * 200, 0))
    strip.save(d / "_walk.png")

    write_scene(name, cfg, (w / 2, h / 2), (w / 2, h * 0.85))


def write_scene(name, cfg, center, body_pivot):
    cx, cy = center
    order = order_for(cfg)
    res, nodes = [], []
    for pname in order:
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
    props = "\n".join(f"{k} = {str(v).lower()}" if isinstance(v, bool) else f"{k} = {float(v)}"
                      for k, v in cfg["scene"].items())
    out = [f"[gd_scene load_steps={len(res) + 2} format=3]", "",
           '[ext_resource type="Script" path="res://front_biped.gd" id="0"]', *res, "",
           f'[node name="{cfg["title"]}" type="Node2D"]\nscript = ExtResource("0")\n{props}\n', *nodes]
    (ROOT / f'{cfg["title"]}.tscn').write_text("\n".join(out))
    print(f'wrote {cfg["title"]}.tscn')


if __name__ == "__main__":
    main(sys.argv[1])
